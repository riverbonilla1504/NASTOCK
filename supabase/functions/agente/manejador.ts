// Manejador HTTP de `agente` (docs/07 §3, HU-044 a HU-048, corte de demo D-70).
//
// Solo acepta el secreto interno, que envía el trabajo `ciclo_agente` de pg_cron. Cada llamada
// corre un ciclo: verifica los datos, calcula métricas y Q, elige las candidatas, consulta a JEV
// (una llamada por candidata), calcula el puntaje compuesto y guarda cada evaluación con su
// explicación. No importa el módulo del broker: la IA no compra ni vende (invariante).
//
// Respuestas:
//   200  { ciclo, estado, evaluadas, excluidas, elegidas }   el ciclo terminó (completado u omitido)
//   200  { omitida: true }                                     ya hay otro ciclo en curso
//   401  SESION_INVALIDA · 403 NO_AUTORIZADO · 405 método
//   500  fallo interno (el ciclo queda `fallido` con su error)

import {
  autenticar,
  ErrorDeAcceso,
  type Identidad,
  respuestaDeAcceso,
} from "../_shared/auth.ts";
import type { Bd } from "../_shared/bd.ts";
import {
  armarExplicacion,
  elegirMejor,
  type Evaluacion,
  evaluar,
  explicacionDeExclusion,
  type Pesos,
  type Umbrales,
} from "../_shared/decision.ts";
import {
  type BarraDia,
  calcularMetricas,
  elegirCandidatas,
  type Metricas,
  puntajesCuantitativos,
  verificarCalidad,
} from "../_shared/indicadores.ts";
import {
  armarEstado,
  type ConfiguracionDeEtiquetas,
} from "../_shared/ia/etiquetas.ts";
import {
  ErrorDeJev,
  type PreguntaJev,
  type ProveedorDeJev,
  type RespuestaJev,
} from "../_shared/ia/tipos.ts";

export interface DependenciasDeAgente {
  jev: ProveedorDeJev;
  abrirBd: () => Bd;
  /** SECRETO_INTERNO. Por defecto se lee del entorno en cada llamada. */
  secreto?: string;
  /** Llamadas a JEV a la vez. */
  concurrencia?: number;
}

const SIN_PERSONAS: Identidad = {
  usuarioDelToken: () => Promise.resolve(null),
  rolDe: () => Promise.resolve(null),
};

function responder(
  estado: number,
  cuerpo: unknown,
  cabeceras: HeadersInit = {},
): Response {
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: { "Content-Type": "application/json", ...cabeceras },
  });
}

/** Días de barras que se piden: 52 semanas + margen para las medias (docs/07 §4.1). */
const DIAS_DE_BARRAS = 400;

type Fila = Record<string, unknown>;

function aFecha(valor: unknown): string {
  if (valor instanceof Date) return valor.toISOString().slice(0, 10);
  return String(valor).slice(0, 10);
}

function redondear<T>(valor: T, decimales = 4): T {
  if (typeof valor === "number") {
    return (Math.round(valor * 10 ** decimales) / 10 ** decimales) as T;
  }
  if (valor && typeof valor === "object") {
    return Object.fromEntries(
      Object.entries(valor).map(([k, v]) => [k, redondear(v, decimales)]),
    ) as T;
  }
  return valor;
}

/** Ejecuta `tareas` con a lo más `limite` a la vez, en orden de resultado. */
async function enParalelo<T, R>(
  elementos: readonly T[],
  limite: number,
  trabajo: (e: T) => Promise<R>,
): Promise<R[]> {
  const resultados: R[] = new Array(elementos.length);
  let siguiente = 0;
  const lector = async () => {
    while (siguiente < elementos.length) {
      const i = siguiente++;
      resultados[i] = await trabajo(elementos[i]);
    }
  };
  await Promise.all(
    Array.from({ length: Math.min(limite, elementos.length) }, lector),
  );
  return resultados;
}

/** Con qué disparador corre el ciclo: pg_cron o `lanzar_ciclo()` (D-72). */
export type Disparador = "programado" | "manual";

/** Lee el disparador del cuerpo que envía `private.despertar_funcion`. */
export async function disparadorDe(peticion: Request): Promise<Disparador> {
  try {
    const cuerpo = await peticion.json();
    return cuerpo?.disparador === "manual" ? "manual" : "programado";
  } catch {
    return "programado";
  }
}

interface Candidata {
  bolsillo: "arriesgadas" | "usuarios";
  simbolo: string;
  sector: string | null;
}

export interface ResumenDeCiclo {
  ciclo: string;
  estado: "completado" | "omitido" | "fallido";
  evaluadas: number;
  excluidas: number;
  elegidas: string[];
  motivo?: string;
}

/** Corre un ciclo completo contra `bd` y `jev`. Exportada para las pruebas. */
export async function correrCiclo(
  bd: Bd,
  jev: ProveedorDeJev,
  concurrencia = 4,
  disparador: Disparador = "programado",
): Promise<ResumenDeCiclo | null> {
  const [{ registrar_ciclo: ciclo }] = await bd.llamar<
    { registrar_ciclo: string | null }
  >(
    "registrar_ciclo",
    [disparador],
  );
  if (!ciclo) return null;
  const inicio = Date.now();

  let version = 0;
  try {
    const [config] = await bd.llamar<Fila>("configuracion_activa");
    if (!config) throw new Error("No hay una configuración de decisión activa");
    version = Number(config.version);
    const etiquetas = config.etiquetas as ConfiguracionDeEtiquetas;
    const pesos = config.pesos as Record<"usuarios" | "arriesgadas", Pesos>;
    const preguntas = (config.preguntas as {
      entrada: Record<string, PreguntaJev & { requiere_contexto?: boolean }>;
    })
      .entrada;

    const parametros = new Map(
      (await bd.llamar<{ clave: string; valor: unknown }>(
        "parametros_del_agente",
      ))
        .map((p) => [p.clave, p.valor]),
    );
    const numero = (clave: string, defecto: number) => {
      const v = Number(parametros.get(clave));
      return Number.isFinite(v) ? v : defecto;
    };
    const texto = (clave: string, defecto: string) => {
      const v = parametros.get(clave);
      return typeof v === "string" && v ? v : defecto;
    };
    const umbrales: Umbrales = {
      confianzaMinima: numero("jev.confianza_minima", 0.65),
      umbralContradiccion: numero("jev.umbral_contradiccion", 0.5),
      puntajeMinimo: numero("jev.puntaje_minimo", 0.6),
    };
    const candidatosMax = numero("ia.candidatos_max", 10);
    const timeoutMs = numero("ia.timeout_jev_seg", 10) * 1000;
    const modeloJev = texto("ia.modelo_jev", "jev-1.13.0");
    const maxAntiguedad = numero("mercado.max_antiguedad_cotizacion_seg", 60);

    const [{ ahora, mercado_en_ventana: mercadoAbierto, ia_activa }] = await bd
      .llamar<
        { ahora: Date; mercado_en_ventana: boolean; ia_activa: boolean }
      >("estado_del_agente");
    // HU-046 CA-3 (D-72): con el interruptor de la IA apagado el ciclo no evalúa.
    if (!ia_activa) {
      return await cerrarOmitido(bd, ciclo, version, inicio, "ia_apagada");
    }
    const universo = await bd.llamar<
      {
        bolsillo: "reserva" | "arriesgadas" | "usuarios";
        simbolo: string;
        sector: string | null;
      }
    >("universo_del_agente");
    const filasDeBarras = await bd.llamar<Fila>("barras_del_agente", [
      DIAS_DE_BARRAS,
    ]);
    const filasDeCotizaciones = await bd.llamar<Fila>(
      "cotizaciones_del_agente",
    );

    const barras = new Map<string, BarraDia[]>();
    for (const f of filasDeBarras) {
      const simbolo = String(f.simbolo);
      if (!barras.has(simbolo)) barras.set(simbolo, []);
      barras.get(simbolo)!.push({
        fecha: aFecha(f.fecha),
        apertura: Number(f.apertura),
        maximo: Number(f.maximo),
        minimo: Number(f.minimo),
        cierre: Number(f.cierre),
        volumen: Number(f.volumen),
      });
    }
    const cotizaciones = new Map<
      string,
      { precio: number; antiguedadSeg: number }
    >();
    for (const f of filasDeCotizaciones) {
      cotizaciones.set(String(f.simbolo), {
        precio: Number(f.precio),
        antiguedadSeg:
          (ahora.getTime() - new Date(String(f.recibido_en)).getTime()) / 1000,
      });
    }

    // CB-87: sin QQQ el ciclo se omite.
    const barrasQqq = barras.get("QQQ");
    if (!barrasQqq || barrasQqq.length === 0) {
      return await cerrarOmitido(bd, ciclo, version, inicio, "qqq_sin_datos");
    }
    const ultimaSesion = barrasQqq[barrasQqq.length - 1].fecha;

    // 1. Calidad de datos y métricas.
    const simbolos = [...new Set(universo.map((u) => u.simbolo)), "QQQ"];
    const calidad = new Map<string, string>();
    const metricas = new Map<string, Metricas>();
    for (const simbolo of simbolos) {
      const serie = barras.get(simbolo) ?? [];
      const motivo = serie.length === 0
        ? "barras_insuficientes"
        : verificarCalidad(serie, {
          ultimaSesion,
          precioEnVivo: cotizaciones.get(simbolo) ?? null,
          maxAntiguedadSeg: maxAntiguedad,
          exigirPrecioEnVivo: mercadoAbierto,
        });
      calidad.set(simbolo, motivo);
      if (motivo === "ok") {
        const vivo = mercadoAbierto
          ? cotizaciones.get(simbolo)?.precio
          : undefined;
        metricas.set(simbolo, calcularMetricas(serie, vivo));
      }
    }
    if (calidad.get("QQQ") !== "ok") {
      return await cerrarOmitido(bd, ciclo, version, inicio, "qqq_sin_datos");
    }

    // 2. Puntaje cuantitativo y candidatas.
    const q = puntajesCuantitativos(metricas);
    const deBolsillo = (b: string) =>
      universo.filter((u) => u.bolsillo === b).map((u) => u.simbolo);
    const elegidas = elegirCandidatas(
      deBolsillo("arriesgadas"),
      deBolsillo("usuarios"),
      q,
      candidatosMax,
    );
    const sectorDe = new Map(universo.map((u) => [u.simbolo, u.sector]));
    const candidatas: Candidata[] = [
      ...elegidas.arriesgadas.map((s) => ({
        bolsillo: "arriesgadas" as const,
        simbolo: s,
        sector: sectorDe.get(s) ?? null,
      })),
      ...elegidas.usuarios.map((s) => ({
        bolsillo: "usuarios" as const,
        simbolo: s,
        sector: sectorDe.get(s) ?? null,
      })),
    ];

    // 3. JEV: una llamada por candidata, con todas las preguntas.
    const niveles: Record<string, number> = {};
    const aEnviar: Record<string, PreguntaJev> = {};
    for (const [clave, p] of Object.entries(preguntas)) {
      if (Array.isArray(p.criteria)) niveles[clave] = p.criteria.length;
      if (p.requiere_contexto) continue; // D-59: sin contexto no se preguntan.
      const { requiere_contexto: _omitida, ...limpia } = p;
      aEnviar[clave] = limpia;
    }
    const mercadoRef = {
      metricas: metricas.get("QQQ")!,
      percentilVolatilidad: q.get("QQQ")!.v,
    };
    const resultadosJev = await enParalelo(
      candidatas,
      concurrencia,
      async (c) => {
        const lista = candidatas.filter((x) => x.bolsillo === c.bolsillo)
          .sort((a, b) => q.get(b.simbolo)!.q - q.get(a.simbolo)!.q);
        const estado = armarEstado({
          bolsillo: c.bolsillo,
          simbolo: c.simbolo,
          sector: c.sector,
          metricas: metricas.get(c.simbolo)!,
          percentilVolatilidad: q.get(c.simbolo)!.v,
          posicion: lista.findIndex((x) => x.simbolo === c.simbolo) + 1,
          totalCandidatas: lista.length,
          mercado: mercadoRef,
          mercadoAbierto,
        }, etiquetas);
        let respuesta: RespuestaJev | null = null;
        let fallo: string | null = null;
        try {
          respuesta = await jev.consultar(
            {
              state: JSON.stringify(estado),
              model: modeloJev,
              questions: aEnviar,
            },
            { timeoutMs },
          );
        } catch (error) {
          fallo = error instanceof ErrorDeJev ? error.codigo : "desconocido";
          console.warn(`agente: JEV falló en ${c.simbolo}: ${fallo}`);
        }
        return { estado, respuesta, fallo };
      },
    );

    // 4. Puntaje compuesto y reglas por candidata; la mejor de cada bolsillo es la recomendación.
    const evaluaciones = candidatas.map((c, i) => ({
      c,
      ...resultadosJev[i],
      evaluacion: evaluar({
        q: q.get(c.simbolo)!.q,
        v: q.get(c.simbolo)!.v,
        jev: resultadosJev[i].respuesta,
        niveles,
        pesos: pesos[c.bolsillo],
        umbrales,
      }) as Evaluacion,
    }));
    const mejores = new Map<string, string | null>();
    for (const bolsillo of ["arriesgadas", "usuarios"] as const) {
      mejores.set(
        bolsillo,
        elegirMejor(
          evaluaciones
            .filter((e) =>
              e.c.bolsillo === bolsillo && e.evaluacion.motivo === null
            )
            .map((e) => ({
              simbolo: e.c.simbolo,
              puntaje: e.evaluacion.puntaje,
              confianza: e.evaluacion.confianza ?? 0,
              v: q.get(e.c.simbolo)!.v,
            })),
        ),
      );
    }

    // 5. Filas: candidatas evaluadas y excluidas por calidad.
    let tokens = 0;
    let modelo: string | null = null;
    const filas: Fila[] = [];
    const recomendadas: string[] = [];
    for (const e of evaluaciones) {
      const resultado = e.evaluacion.motivo !== null
        ? `no_elegible:${e.evaluacion.motivo}`
        : mejores.get(e.c.bolsillo) === e.c.simbolo
        ? "elegida"
        : "elegible_no_elegida";
      if (resultado === "elegida") recomendadas.push(e.c.simbolo);
      tokens += (e.respuesta?.usage?.input_tokens ?? 0) +
        (e.respuesta?.usage?.output_tokens ?? 0);
      modelo ??= e.respuesta?.model ?? null;
      const explicacion = armarExplicacion({
        simbolo: e.c.simbolo,
        evaluacion: e.evaluacion,
        resultado,
        horizonte: e.c.bolsillo === "arriesgadas"
          ? "unos días"
          : "unas semanas",
        mercadoAbierto,
        umbrales,
        fallosJev: e.fallo,
        jev: e.respuesta,
        niveles,
      });
      filas.push({
        bolsillo: e.c.bolsillo,
        simbolo: e.c.simbolo,
        tipo: "entrada",
        calidad_datos: "ok",
        metricas: redondear(metricas.get(e.c.simbolo)),
        estado_enviado: e.estado,
        estado_contexto: "sin_contexto",
        respuestas_jev: e.respuesta?.answers ?? null,
        modelo_jev: e.respuesta?.model ?? null,
        puntaje_cuantitativo: redondear(q.get(e.c.simbolo)!.q),
        puntaje_compuesto: redondear(e.evaluacion.puntaje),
        aportes: redondear(e.evaluacion.aportes),
        contradiccion: redondear(e.evaluacion.contradiccion, 3),
        confianza: e.evaluacion.confianza === null
          ? null
          : redondear(e.evaluacion.confianza, 3),
        resultado,
        explicacion,
      });
    }
    let excluidas = 0;
    for (const u of universo) {
      const motivo = calidad.get(u.simbolo);
      if (u.bolsillo === "reserva" || !motivo || motivo === "ok") continue;
      excluidas++;
      filas.push({
        bolsillo: u.bolsillo,
        simbolo: u.simbolo,
        tipo: "entrada",
        calidad_datos: motivo,
        resultado: `excluida:${motivo}`,
        explicacion: explicacionDeExclusion(u.simbolo, motivo),
      });
    }

    await bd.llamar("registrar_evaluaciones", [ciclo, version, filas]);
    await bd.llamar("cerrar_ciclo", [
      ciclo,
      "completado",
      version,
      modelo,
      candidatas.length,
      excluidas,
      tokens,
      Date.now() - inicio,
      null,
      null,
    ]);
    return {
      ciclo,
      estado: "completado",
      evaluadas: candidatas.length,
      excluidas,
      elegidas: recomendadas,
    };
  } catch (error) {
    const mensaje = error instanceof Error ? error.message : String(error);
    try {
      await bd.llamar("cerrar_ciclo", [
        ciclo,
        "fallido",
        version || null,
        null,
        null,
        null,
        null,
        Date.now() - inicio,
        null,
        mensaje,
      ]);
    } catch {
      console.error("agente: no se pudo cerrar el ciclo fallido");
    }
    throw error;
  }
}

async function cerrarOmitido(
  bd: Bd,
  ciclo: string,
  version: number,
  inicio: number,
  motivo: string,
): Promise<ResumenDeCiclo> {
  await bd.llamar("cerrar_ciclo", [
    ciclo,
    "omitido",
    version,
    null,
    0,
    0,
    0,
    Date.now() - inicio,
    motivo,
    null,
  ]);
  return {
    ciclo,
    estado: "omitido",
    evaluadas: 0,
    excluidas: 0,
    elegidas: [],
    motivo,
  };
}

export function crearManejador(
  dependencias: DependenciasDeAgente,
): (peticion: Request) => Promise<Response> {
  return async (peticion) => {
    if (peticion.method !== "POST") {
      return responder(405, { error: "método no permitido" }, {
        Allow: "POST",
      });
    }
    try {
      await autenticar(
        peticion,
        { aceptaInterno: true, roles: [] },
        SIN_PERSONAS,
        dependencias.secreto,
      );
    } catch (error) {
      if (error instanceof ErrorDeAcceso) return respuestaDeAcceso(error);
      console.error("agente: fallo al autenticar");
      return responder(500, { error: "interno" });
    }

    let bd: Bd | undefined;
    try {
      const disparador = await disparadorDe(peticion);
      bd = dependencias.abrirBd();
      const resumen = await correrCiclo(
        bd,
        dependencias.jev,
        dependencias.concurrencia,
        disparador,
      );
      if (!resumen) return responder(200, { omitida: true });
      return responder(200, resumen);
    } catch (error) {
      console.error(
        `agente: fallo interno: ${
          error instanceof Error ? error.message : error
        }`,
      );
      return responder(500, { error: "interno" });
    } finally {
      try {
        await bd?.cerrar();
      } catch {
        console.error("agente: no se pudo cerrar la conexión a la base");
      }
    }
  };
}

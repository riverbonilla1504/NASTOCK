// Manejador HTTP de ingesta-mercado (docs/05 §6, docs/09 §2): solo acepta el secreto interno, que
// envía el trabajo `ingesta_mercado` de pg_cron cada 15 segundos.
//
// Con el mercado en ventana consulta los precios de todo el universo y los ETF en una sola llamada,
// descarta los inválidos (CB-53) y entrega el lote a private.publicar_cotizaciones, que guarda y
// publica en el canal `mercado`. Fuera de ventana no llama al proveedor (FR-068).
//
// Respuestas:
//   200  { omitida: true }                      el mercado no está en ventana
//   200  { guardadas, descartadas, ... }        lote publicado
//   401  SESION_INVALIDA   sin secreto ni sesión, o con un JWT
//   403  NO_AUTORIZADO     secreto incorrecto
//   405  otro método que POST
//   502  INTEGRACION_CAIDA el proveedor falló; no se toca lo guardado (la app sigue con el último precio)
//   500  cualquier otro fallo, sin detalles internos

import {
  autenticar,
  ErrorDeAcceso,
  type Identidad,
  respuestaDeAcceso,
} from "../_shared/auth.ts";
import type { Bd } from "../_shared/bd.ts";
import { z } from "../_shared/esquemas.ts";
import { registrarSalud } from "../_shared/salud.ts";
import {
  type Cotizacion,
  ErrorDeProveedor,
  type ProveedorDeMercado,
} from "../_shared/mercado/interfaz.ts";

/** Margen antes de la apertura en que ya se consulta (docs/05 §7). */
export const MARGEN_DE_VENTANA = "10 minutes";

export interface DependenciasDeManejador {
  mercado: ProveedorDeMercado;
  /** Abre una conexión a la base; el manejador la cierra siempre al terminar. */
  abrirBd: () => Bd;
  /** Valor de `cotizaciones.fuente`: 'alpaca-iex' con Alpaca, 'simulado' con el simulado. */
  fuente: string;
  /** SECRETO_INTERNO. Por defecto se lee del entorno en cada llamada. */
  secreto?: string;
}

const precioValido = z.number().finite().positive();
const opcional = z.number().finite().nullable().optional();

/** Una cotización que llega del proveedor: lo que no sirva se descarta, no detiene el lote. */
const esquemaDeCotizacion = z.object({
  simbolo: z.string().min(1),
  precio: precioValido,
  bid: opcional,
  ask: opcional,
  cierreAnterior: opcional,
  volumenDia: opcional,
  momento: z.string().refine((t) => !Number.isNaN(Date.parse(t))),
  barraMinuto: z.unknown().optional(),
});

export interface Descarte {
  simbolo: string;
  motivo: string;
}

/** Separa las cotizaciones válidas de las inválidas (CB-53). */
export function validarCotizaciones(
  crudas: readonly unknown[],
): { validas: Cotizacion[]; descartes: Descarte[] } {
  const validas: Cotizacion[] = [];
  const descartes: Descarte[] = [];
  for (const cruda of crudas) {
    const resultado = esquemaDeCotizacion.safeParse(cruda);
    if (resultado.success) {
      validas.push(cruda as Cotizacion);
    } else {
      const simbolo = (cruda as { simbolo?: unknown } | null)?.simbolo;
      descartes.push({
        simbolo: typeof simbolo === "string" ? simbolo : "?",
        motivo: "PRECIO_INVALIDO",
      });
    }
  }
  return { validas, descartes };
}

/** Forma que recibe private.publicar_cotizaciones (docs/06 §8.2). */
function aDatos(cotizaciones: readonly Cotizacion[], fuente: string) {
  return cotizaciones.map((c) => ({
    simbolo: c.simbolo,
    precio: c.precio,
    bid: c.bid ?? null,
    ask: c.ask ?? null,
    cierre_anterior: c.cierreAnterior ?? null,
    volumen_dia: c.volumenDia ?? null,
    fuente,
    momento: c.momento,
    barra_minuto: c.barraMinuto ?? null,
  }));
}

/** Esta función no acepta personas: ningún JWT identifica a nadie. */
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

export function crearManejador(
  dependencias: DependenciasDeManejador,
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
      console.error("ingesta-mercado: fallo al autenticar");
      return responder(500, { error: "interno" });
    }

    let bd: Bd | undefined;
    try {
      bd = dependencias.abrirBd();

      // FR-068: fuera de ventana no se consulta. El trabajo de pg_cron ya lo filtra; esto cubre
      // una llamada a mano.
      const [{ mercado_en_ventana: enVentana }] = await bd.llamar<
        { mercado_en_ventana: boolean }
      >("mercado_en_ventana", [MARGEN_DE_VENTANA]);
      if (!enVentana) return responder(200, { omitida: true });

      const [{ ahora }] = await bd.llamar<{ ahora: Date }>("ahora");
      if (!(ahora instanceof Date) || Number.isNaN(ahora.getTime())) {
        throw new Error("private.ahora() no devolvió una hora válida");
      }
      const simbolos =
        (await bd.llamar<{ simbolo: string }>("simbolos_del_universo"))
          .map((f) => f.simbolo);

      // Una sola llamada al proveedor para todos los símbolos (FR-066).
      let crudas: Cotizacion[];
      try {
        crudas = await dependencias.mercado.snapshots(simbolos, ahora);
      } catch (error) {
        if (!(error instanceof ErrorDeProveedor)) throw error;
        console.error(`ingesta-mercado: el proveedor falló: ${error.message}`);
        await registrarSalud(bd, "alpaca_datos", false, error);
        return responder(502, {
          codigo: "INTEGRACION_CAIDA",
          detalle: error.message,
        });
      }

      await registrarSalud(bd, "alpaca_datos", true);
      const { validas, descartes } = validarCotizaciones(crudas);
      // Un símbolo sin cotización utilizable (el proveedor lo omitió por precio nulo o ≤ 0) también se registra.
      const recibidos = new Set(crudas.map((c) => c.simbolo));
      for (const simbolo of simbolos) {
        if (!recibidos.has(simbolo)) {
          descartes.push({ simbolo, motivo: "SIN_PRECIO_VALIDO" });
        }
      }

      const [resultado] = await bd.llamar<{
        guardadas: number;
        descartadas: number;
        barras_minuto: number;
        descartes: Descarte[];
      }>("publicar_cotizaciones", [aDatos(validas, dependencias.fuente)]);
      descartes.push(...(resultado.descartes ?? []));

      if (descartes.length > 0) {
        // Solo símbolo y motivo: nada que identifique a personas ni llaves.
        console.warn(
          `ingesta-mercado: ${descartes.length} descartados: ${
            descartes.map((d) => `${d.simbolo}=${d.motivo}`).join(", ")
          }`,
        );
      }
      return responder(200, {
        guardadas: resultado.guardadas,
        descartadas: descartes.length,
        barras_minuto: resultado.barras_minuto,
        descartes,
      });
    } catch (error) {
      console.error(
        `ingesta-mercado: fallo interno: ${
          error instanceof Error ? error.message : error
        }`,
      );
      return responder(500, { error: "interno" });
    } finally {
      try {
        await bd?.cerrar();
      } catch {
        console.error(
          "ingesta-mercado: no se pudo cerrar la conexión a la base",
        );
      }
    }
  };
}

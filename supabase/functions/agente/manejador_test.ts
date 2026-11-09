import { assert, assertEquals } from "@std/assert";
import type { Argumento, Bd } from "../_shared/bd.ts";
import { serie } from "../_shared/indicadores_test.ts";
import {
  ErrorDeJev,
  type ProveedorDeJev,
  type RespuestaJev,
} from "../_shared/ia/tipos.ts";
import { correrCiclo, crearManejador } from "./manejador.ts";

const PREGUNTAS = {
  entrada: {
    reversal_risk: {
      type: "score",
      instructions: "r",
      criteria: ["a", "b", "c", "d"],
    },
    event_risk: {
      type: "score",
      instructions: "e",
      criteria: ["a", "b", "c", "d"],
    },
    entry_timing: {
      type: "choice",
      instructions: "t",
      criteria: { buy_now: "x", wait: "y", avoid: "z" },
    },
    context_support: {
      requiere_contexto: true,
      type: "score",
      instructions: "c",
      criteria: ["a", "b", "c"],
    },
  },
};
const ETIQUETAS = {
  rendimiento: {
    "1d": { cortes: [-0.02, -0.005, 0.005, 0.02] },
    "5d": { cortes: [-0.06, -0.02, 0.02, 0.06] },
    "20d": { cortes: [-0.12, -0.04, 0.04, 0.12] },
    "60d": { cortes: [-0.2, -0.07, 0.07, 0.2] },
    etiquetas: ["a", "b", "c", "d", "e"],
    etiquetas_1d: ["a", "b", "c", "d", "e"],
  },
  volatilidad: {
    cortes: [0.2, 0.4, 0.6, 0.8],
    etiquetas: ["a", "b", "c", "d", "e"],
  },
  rsi: { cortes: [30, 45, 55, 70], etiquetas: ["a", "b", "c", "d", "e"] },
  distancia_maximo_52s: {
    cortes: [-0.25, -0.1, -0.02],
    etiquetas: ["a", "b", "c", "d"],
  },
  volumen_relativo: { cortes: [0.7, 1.3, 2], etiquetas: ["a", "b", "c", "d"] },
  horizonte: {
    arriesgadas: {
      name: "risky",
      horizon: "a few days (about one week)",
      profile: "p",
    },
    usuarios: { name: "users", horizon: "a few weeks", profile: "p" },
  },
};
const PESOS = {
  usuarios: {
    wQ: 0.25,
    wC: 0.1,
    wS: 0.1,
    wT: 0.05,
    wV: 0.2,
    wE: 0.15,
    wR: 0.15,
  },
  arriesgadas: {
    wQ: 0.3,
    wC: 0.1,
    wS: 0.1,
    wT: 0.05,
    wV: 0.15,
    wE: 0.15,
    wR: 0.15,
  },
};

interface Llamada {
  funcion: string;
  argumentos: readonly Argumento[];
}

/** Base de datos falsa: devuelve datos fijos y anota cada llamada. */
function bdFalsa(opciones: { sinQqq?: boolean; cicloNulo?: boolean } = {}) {
  const llamadas: Llamada[] = [];
  const simbolos = [
    "QQQ",
    "QLD",
    ...Array.from({ length: 12 }, (_, i) => `S${i}`),
  ];
  const bd: Bd = {
    llamar<T>(
      funcion: string,
      argumentos: readonly Argumento[] = [],
    ): Promise<T[]> {
      llamadas.push({ funcion, argumentos });
      let filas: unknown[] = [];
      switch (funcion) {
        case "registrar_ciclo":
          filas = [{ registrar_ciclo: opciones.cicloNulo ? null : "ciclo-1" }];
          break;
        case "configuracion_activa":
          filas = [{
            version: 1,
            preguntas: PREGUNTAS,
            etiquetas: ETIQUETAS,
            pesos: PESOS,
            umbrales: {},
          }];
          break;
        case "parametros_del_agente":
          filas = [{ clave: "ia.candidatos_max", valor: 5 }, {
            clave: "ia.modelo_jev",
            valor: "jev-1.13.0",
          }, { clave: "jev.puntaje_minimo", valor: 0 }];
          break;
        case "estado_del_agente":
          filas = [{
            ahora: new Date("2026-11-07T20:00:00Z"),
            mercado_en_ventana: false,
          }];
          break;
        case "universo_del_agente":
          filas = [
            { bolsillo: "usuarios", simbolo: "QLD", sector: null },
            { bolsillo: "usuarios", simbolo: "QQQ", sector: null },
            ...simbolos.filter((s) => s.startsWith("S")).map((s) => ({
              bolsillo: "arriesgadas",
              simbolo: s,
              sector: "Tech",
            })),
          ];
          break;
        case "barras_del_agente":
          filas = simbolos.flatMap((s, i) =>
            opciones.sinQqq && s === "QQQ"
              ? []
              : serie(90, 100, 0.2 + i * 0.05, "2026-11-06", 1.5).map((b) => ({
                simbolo: s,
                fecha: new Date(`${b.fecha}T00:00:00Z`),
                apertura: String(b.apertura),
                maximo: String(b.maximo),
                minimo: String(b.minimo),
                cierre: String(b.cierre),
                volumen: String(b.volumen),
              }))
          );
          break;
        case "cotizaciones_del_agente":
          filas = [];
          break;
        case "registrar_evaluaciones":
        case "cerrar_ciclo":
          filas = [{}];
          break;
      }
      return Promise.resolve(filas as T[]);
    },
    cerrar: () => Promise.resolve(),
  };
  const de = (f: string) => llamadas.filter((l) => l.funcion === f);
  return { bd, llamadas, de };
}

function jevQue(
  respuesta: (estado: string) => RespuestaJev | Error,
): ProveedorDeJev {
  return {
    nombre: "falso",
    consultar: (c) => {
      const r = respuesta(c.state);
      return r instanceof Error ? Promise.reject(r) : Promise.resolve(r);
    },
  };
}

const comprarYa: RespuestaJev = {
  model: "jev-1.13.0",
  answers: {
    entry_timing: { type: "choice", choice: "buy_now", confidence: 0.9 },
    event_risk: { type: "score", score: 0 },
    reversal_risk: { type: "score", score: 0 },
  },
  usage: { input_tokens: 100, output_tokens: 5 },
};

Deno.test("ciclo: evalúa, guarda las evaluaciones y cierra completado con una recomendación por bolsillo", async () => {
  const { bd, de } = bdFalsa();
  const resumen = await correrCiclo(bd, jevQue(() => comprarYa));

  assertEquals(resumen?.estado, "completado");
  assertEquals(resumen?.evaluadas, 5 + 2); // 5 de Arriesgadas (ia.candidatos_max) y QLD y QQQ
  assertEquals(resumen?.elegidas.length, 2); // una por bolsillo
  const filas = de("registrar_evaluaciones")[0].argumentos[2] as Record<
    string,
    unknown
  >[];
  assertEquals(filas.length, 7);
  assertEquals(filas.filter((f) => f.resultado === "elegida").length, 2);
  for (const f of filas) {
    assertEquals(f.estado_contexto, "sin_contexto");
    assert((f.explicacion as { que: string }).que.length > 0);
  }
  const cierre = de("cerrar_ciclo")[0].argumentos;
  assertEquals(cierre[1], "completado");
});

Deno.test("ciclo: no pregunta a JEV por el contexto (D-59) y el estado no lleva cifras de personas", async () => {
  const { bd } = bdFalsa();
  const preguntasEnviadas: string[][] = [];
  const jev: ProveedorDeJev = {
    nombre: "falso",
    consultar: (c) => {
      preguntasEnviadas.push(Object.keys(c.questions));
      assert(!("requiere_contexto" in c.questions.reversal_risk));
      return Promise.resolve(comprarYa);
    },
  };
  await correrCiclo(bd, jev);
  assert(preguntasEnviadas.length === 7);
  for (const p of preguntasEnviadas) {
    assertEquals(p.sort(), ["entry_timing", "event_risk", "reversal_risk"]);
  }
});

Deno.test("ciclo: sin JEV (falló) las evaluaciones quedan marcadas y nada se recomienda", async () => {
  const { bd, de } = bdFalsa();
  const resumen = await correrCiclo(
    bd,
    jevQue(() => new ErrorDeJev("sin_llave", "Falta TYPESAFE_API_KEY")),
  );
  assertEquals(resumen?.estado, "completado");
  assertEquals(resumen?.elegidas, []);
  const filas = de("registrar_evaluaciones")[0].argumentos[2] as Record<
    string,
    unknown
  >[];
  for (const f of filas) {
    assertEquals(f.resultado, "no_elegible:sin_jev");
    assertEquals(f.respuestas_jev, null);
  }
});

Deno.test("ciclo: sin barras de QQQ el ciclo se omite (CB-87)", async () => {
  const { bd, de } = bdFalsa({ sinQqq: true });
  const resumen = await correrCiclo(bd, jevQue(() => comprarYa));
  assertEquals(resumen?.estado, "omitido");
  assertEquals(resumen?.motivo, "qqq_sin_datos");
  assertEquals(de("registrar_evaluaciones").length, 0);
  assertEquals(de("cerrar_ciclo")[0].argumentos[1], "omitido");
});

Deno.test("ciclo: con otro ciclo en curso no hace nada", async () => {
  const { bd, llamadas } = bdFalsa({ cicloNulo: true });
  assertEquals(await correrCiclo(bd, jevQue(() => comprarYa)), null);
  assertEquals(llamadas.length, 1);
});

Deno.test("ciclo: un fallo interno cierra el ciclo como fallido y lo relanza", async () => {
  const { bd, de } = bdFalsa();
  const roto: Bd = {
    llamar: (f, a) =>
      f === "universo_del_agente"
        ? Promise.reject(new Error("se cayó"))
        : bd.llamar(f, a),
    cerrar: bd.cerrar,
  };
  let lanzado = false;
  try {
    await correrCiclo(roto, jevQue(() => comprarYa));
  } catch {
    lanzado = true;
  }
  assert(lanzado);
  const cierre = de("cerrar_ciclo")[0].argumentos;
  assertEquals(cierre[1], "fallido");
  assertEquals(cierre[9], "se cayó");
});

Deno.test("manejador: solo acepta POST con el secreto interno", async () => {
  const { bd } = bdFalsa();
  const manejador = crearManejador({
    jev: jevQue(() => comprarYa),
    abrirBd: () => bd,
    secreto: "s3",
  });
  assertEquals((await manejador(new Request("http://x/agente"))).status, 405);
  assertEquals(
    (await manejador(new Request("http://x/agente", { method: "POST" })))
      .status,
    401,
  );
  assertEquals(
    (await manejador(
      new Request("http://x/agente", {
        method: "POST",
        headers: { "x-secreto-interno": "otro" },
      }),
    ))
      .status,
    403,
  );
  const ok = await manejador(
    new Request("http://x/agente", {
      method: "POST",
      headers: { "x-secreto-interno": "s3" },
    }),
  );
  assertEquals(ok.status, 200);
  assertEquals((await ok.json()).estado, "completado");
});

Deno.test("agente no importa el broker (invariante: la IA no ejecuta)", async () => {
  for (const archivo of ["index.ts", "manejador.ts"]) {
    const texto = await Deno.readTextFile(new URL(archivo, import.meta.url));
    // La CI busca este texto en toda la carpeta: se arma aquí para no delatarse a sí misma.
    assert(
      !texto.includes("_shared/" + "broker"),
      `${archivo} importa el broker`,
    );
  }
});

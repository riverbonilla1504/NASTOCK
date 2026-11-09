import { assert, assertAlmostEquals, assertEquals, assertStringIncludes } from "@std/assert";
import {
  armarExplicacion,
  elegirMejor,
  evaluar,
  type Pesos,
  type Umbrales,
} from "./decision.ts";
import type { RespuestaJev } from "./ia/tipos.ts";

const pesosArriesgadas: Pesos = { wQ: 0.3, wC: 0.1, wS: 0.1, wT: 0.05, wV: 0.15, wE: 0.15, wR: 0.15 };
const pesosUsuarios: Pesos = { wQ: 0.25, wC: 0.1, wS: 0.1, wT: 0.05, wV: 0.2, wE: 0.15, wR: 0.15 };
const umbrales: Umbrales = { confianzaMinima: 0.65, umbralContradiccion: 0.5, puntajeMinimo: 0.6 };
const niveles = { event_risk: 4, reversal_risk: 4 };

function jev(
  over: { eleccion?: string; confianza?: number; evento?: number; reversion?: number; conflicto?: number } = {},
): RespuestaJev {
  return {
    model: "jev-1.13.0",
    answers: {
      entry_timing: { type: "choice", choice: over.eleccion ?? "buy_now", confidence: over.confianza ?? 0.8 },
      event_risk: { type: "score", score: over.evento ?? 0 },
      reversal_risk: { type: "score", score: over.reversion ?? 0 },
      ...(over.conflicto === undefined ? {} : { data_context_conflict: { type: "noul", noul: over.conflicto } }),
    },
  };
}

Deno.test("los pesos de cada bolsillo suman 1", () => {
  for (const p of [pesosArriesgadas, pesosUsuarios]) {
    assertAlmostEquals(Object.values(p).reduce((a, b) => a + b, 0), 1, 1e-12);
  }
});

Deno.test("puntaje: sin contexto C, S y T valen 0,5 y el resto sigue la fórmula", () => {
  const e = evaluar({ q: 1, v: 0, jev: jev(), niveles, pesos: pesosArriesgadas, umbrales });
  // 0,30·1 + (0,10+0,10+0,05)·0,5 + 0,15·1 + 0,15·1 + 0,15·1
  assertAlmostEquals(e.puntaje, 0.3 + 0.125 + 0.45, 1e-12);
  for (const d of ["C", "S", "T"] as const) {
    assertEquals(e.aportes[d].valor, 0.5);
    assertEquals(e.aportes[d].neutral, true);
  }
  assertEquals(e.motivo, null);
});

Deno.test("puntaje: máximo y mínimo con contexto neutral", () => {
  const mejor = evaluar({ q: 1, v: 0, jev: jev(), niveles, pesos: pesosUsuarios, umbrales });
  const peor = evaluar({
    q: 0, v: 1, jev: jev({ evento: 3, reversion: 3 }), niveles, pesos: pesosUsuarios, umbrales,
  });
  assertAlmostEquals(mejor.puntaje, 0.25 + 0.125 + 0.2 + 0.15 + 0.15, 1e-12);
  assertAlmostEquals(peor.puntaje, 0.125, 1e-12); // solo el 0,25 de contexto neutral × 0,5
});

Deno.test("reglas: cada motivo de no elegibilidad", () => {
  const base = { q: 1, v: 0, niveles, pesos: pesosArriesgadas, umbrales };
  assertEquals(evaluar({ ...base, jev: jev({ eleccion: "wait" }) }).motivo, "espera");
  assertEquals(evaluar({ ...base, jev: jev({ eleccion: "avoid" }) }).motivo, "evitar");
  assertEquals(evaluar({ ...base, jev: jev({ confianza: 0.5 }) }).motivo, "confianza");
  assertEquals(evaluar({ ...base, jev: jev({ conflicto: 0.6 }) }).motivo, "contradiccion");
  assertEquals(evaluar({ ...base, q: 0, v: 1, jev: jev() }).motivo, "puntaje");
  assertEquals(evaluar({ ...base, jev: null }).motivo, "sin_jev");
});

Deno.test("sin JEV: riesgos neutros, marcada y sin recomendación", () => {
  const e = evaluar({ q: 0.8, v: 0.2, jev: null, niveles, pesos: pesosArriesgadas, umbrales });
  assertEquals(e.sinJev, true);
  assertEquals(e.confianza, null);
  assertEquals(e.aportes.E.neutral, true);
});

Deno.test("mejor opción: mayor puntaje, luego mayor confianza, luego menor volatilidad (CB-86)", () => {
  assertEquals(elegirMejor([]), null);
  assertEquals(
    elegirMejor([
      { simbolo: "A", puntaje: 0.7, confianza: 0.7, v: 0.5 },
      { simbolo: "B", puntaje: 0.8, confianza: 0.66, v: 0.9 },
    ]),
    "B",
  );
  assertEquals(
    elegirMejor([
      { simbolo: "A", puntaje: 0.8, confianza: 0.7, v: 0.5 },
      { simbolo: "B", puntaje: 0.8, confianza: 0.9, v: 0.9 },
    ]),
    "B",
  );
  assertEquals(
    elegirMejor([
      { simbolo: "A", puntaje: 0.8, confianza: 0.9, v: 0.7 },
      { simbolo: "B", puntaje: 0.8, confianza: 0.9, v: 0.2 },
    ]),
    "B",
  );
});

Deno.test("explicación: elegida, con por qué, qué la frena y advertencias", () => {
  const evaluacion = evaluar({
    q: 0.9, v: 0.9, jev: jev({ evento: 2, reversion: 0 }), niveles, pesos: pesosArriesgadas, umbrales,
  });
  const x = armarExplicacion({
    simbolo: "NVDA", evaluacion, resultado: "elegida", horizonte: "unos días", mercadoAbierto: false, umbrales,
  });
  assertStringIncludes(x.que, "considerar comprar NVDA");
  assert(x.por_que.length >= 1 && x.por_que.length <= 3);
  assert(x.frena.some((f) => f.includes("volatilidad")));
  assert(x.advertencias.some((a) => a.startsWith("Sin contexto")));
  assert(x.advertencias.some((a) => a.startsWith("Mercado cerrado")));
  assertStringIncludes(x.resumen, "NVDA");
});

Deno.test("explicación: no elegible dice el motivo y sin JEV lo avisa", () => {
  const evaluacion = evaluar({ q: 0.5, v: 0.5, jev: null, niveles, pesos: pesosArriesgadas, umbrales });
  const x = armarExplicacion({
    simbolo: "AMD", evaluacion, resultado: "no_elegible:sin_jev", horizonte: "unos días",
    mercadoAbierto: true, umbrales, fallosJev: "sin_llave",
  });
  assertStringIncludes(x.que, "No se recomienda comprar AMD");
  assert(x.advertencias.some((a) => a.includes("falta la llave")));
});

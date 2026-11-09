import { assert, assertEquals, assertRejects } from "@std/assert";
import { armarEstado, type ConfiguracionDeEtiquetas, etiquetaPorCortes } from "./etiquetas.ts";
import { crearJev, ErrorDeJev } from "./jev.ts";
import { JevSimulado } from "./simulado.ts";
import { JevTypeSafe } from "./typesafe.ts";
import { calcularMetricas } from "../indicadores.ts";
import { serie } from "../indicadores_test.ts";

const preguntas = {
  entry_timing: {
    type: "choice" as const,
    instructions: "Is it a good moment?",
    criteria: { buy_now: "yes", wait: "wait", avoid: "no" },
  },
  event_risk: {
    type: "score" as const,
    instructions: "Event risk?",
    criteria: ["None", "Minor", "Relevant", "Binary"],
  },
};
const consulta = { state: "{}", model: "jev-1.13.0", questions: preguntas };

const respuestaOk = {
  model: "jev-1.13.0",
  answers: { entry_timing: { type: "choice", choice: "wait", confidence: 0.7 } },
  usage: { input_tokens: 10, output_tokens: 2 },
};

function respuesta(estado: number, cuerpo: unknown = respuestaOk): Response {
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.test("typesafe: una llamada con estado, modelo y preguntas; devuelve el model", async () => {
  let pedido: { url: string; init: RequestInit } | undefined;
  const jev = new JevTypeSafe({
    llave: "llave-de-prueba",
    fetcher: (url, init) => {
      pedido = { url: String(url), init: init! };
      return Promise.resolve(respuesta(200));
    },
  });
  const r = await jev.consultar(consulta, { timeoutMs: 5000 });
  assertEquals(r.model, "jev-1.13.0");
  assertEquals(pedido!.url, "https://api.typesafe.ai/v1/systemone");
  const cuerpo = JSON.parse(String(pedido!.init.body));
  assertEquals(Object.keys(cuerpo).sort(), ["model", "questions", "state"]);
  assertEquals(cuerpo.model, "jev-1.13.0");
  assertEquals(new Headers(pedido!.init.headers).get("Authorization"), "Bearer llave-de-prueba");
});

Deno.test("typesafe: reintenta con espera exponencial ante 429 y 529", async () => {
  const estados = [429, 529, 200];
  const esperas: number[] = [];
  const jev = new JevTypeSafe({
    llave: "k",
    fetcher: () => Promise.resolve(respuesta(estados.shift()!)),
    esperar: (ms) => {
      esperas.push(ms);
      return Promise.resolve();
    },
  });
  const r = await jev.consultar(consulta, { timeoutMs: 60000 });
  assertEquals(r.model, "jev-1.13.0");
  assertEquals(esperas.length, 2);
  assert(esperas[1] > esperas[0]);
});

Deno.test("typesafe: si sigue fallando tras reintentar, lanza ErrorDeJev", async () => {
  const jev = new JevTypeSafe({
    llave: "k",
    fetcher: () => Promise.resolve(respuesta(429)),
    esperar: () => Promise.resolve(),
  });
  await assertRejects(() => jev.consultar(consulta, { timeoutMs: 60000 }), ErrorDeJev, "429");
});

Deno.test("typesafe: sin llave, acceso negado y respuesta mal formada", async () => {
  const sinLlave = new JevTypeSafe({ llave: "" });
  const e1 = await assertRejects(() => sinLlave.consultar(consulta, { timeoutMs: 1000 }), ErrorDeJev);
  assertEquals((e1 as ErrorDeJev).codigo, "sin_llave");

  const negado = new JevTypeSafe({
    llave: "secreto-no-copiar",
    fetcher: () => Promise.resolve(respuesta(403, {})),
  });
  const e2 = await assertRejects(() => negado.consultar(consulta, { timeoutMs: 1000 }), ErrorDeJev);
  assertEquals((e2 as ErrorDeJev).codigo, "sin_acceso");
  assert(!(e2 as ErrorDeJev).message.includes("secreto-no-copiar"));

  const mal = new JevTypeSafe({
    llave: "k",
    fetcher: () => Promise.resolve(respuesta(200, { hola: 1 })),
  });
  const e3 = await assertRejects(() => mal.consultar(consulta, { timeoutMs: 1000 }), ErrorDeJev);
  assertEquals((e3 as ErrorDeJev).codigo, "formato");
});

Deno.test("typesafe: corta la espera al agotarse el tiempo", async () => {
  const jev = new JevTypeSafe({
    llave: "k",
    fetcher: (_u, init) =>
      new Promise((_r, rechazar) => {
        init!.signal!.addEventListener("abort", () => rechazar(new DOMException("t", "TimeoutError")));
      }),
  });
  const e = await assertRejects(() => jev.consultar(consulta, { timeoutMs: 30 }), ErrorDeJev);
  assertEquals((e as ErrorDeJev).codigo, "tiempo_agotado");
});

Deno.test("simulado: determinista y con escenarios", async () => {
  const a = await new JevSimulado().consultar(consulta);
  const b = await new JevSimulado().consultar(consulta);
  assertEquals(a, b);
  assertEquals(a.model, "jev-1.13.0");
  const baja = await new JevSimulado("confianza_baja").consultar(consulta);
  assert((baja.answers.entry_timing.confidence ?? 1) < 0.65);
  await assertRejects(() => new JevSimulado("sin_respuesta").consultar(consulta), ErrorDeJev);
  const conflicto = await new JevSimulado("contradiccion").consultar({
    ...consulta,
    questions: { ...preguntas, data_context_conflict: { type: "noul", instructions: "?" } },
  });
  assert((conflicto.answers.data_context_conflict.noul ?? 0) >= 0.5);
});

Deno.test("crearJev: simulado por defecto, typesafe si se pide, y mvp rechaza el simulado (CB-91)", () => {
  assertEquals(crearJev(() => undefined).nombre, "simulado");
  const typesafe = (n: string) => ({ PROVEEDOR_JEV: "typesafe" } as Record<string, string>)[n];
  assertEquals(crearJev(typesafe).nombre, "typesafe");
  const mvp = (n: string) => ({ ENTORNO: "mvp", PROVEEDOR_JEV: "typesafe" } as Record<string, string>)[n];
  let error: unknown;
  try {
    crearJev(mvp);
  } catch (e) {
    error = e;
  }
  assert(error, "con ENTORNO=mvp debe fallar si otro proveedor es simulado");
});

const etiquetas: ConfiguracionDeEtiquetas = {
  rendimiento: {
    "1d": { cortes: [-0.02, -0.005, 0.005, 0.02] },
    "5d": { cortes: [-0.06, -0.02, 0.02, 0.06] },
    "20d": { cortes: [-0.12, -0.04, 0.04, 0.12] },
    "60d": { cortes: [-0.2, -0.07, 0.07, 0.2] },
    etiquetas: ["strong loss", "moderate loss", "flat", "moderate gain", "strong gain"],
    etiquetas_1d: ["sharp drop", "small drop", "flat", "small gain", "sharp gain"],
  },
  volatilidad: { cortes: [0.2, 0.4, 0.6, 0.8], etiquetas: ["very low", "low", "moderate", "high", "very high"] },
  rsi: { cortes: [30, 45, 55, 70], etiquetas: ["oversold", "weak", "neutral", "strong", "overbought"] },
  distancia_maximo_52s: {
    cortes: [-0.25, -0.1, -0.02],
    etiquetas: ["far below", "well below", "slightly below", "at or near the 52-week high"],
  },
  volumen_relativo: { cortes: [0.7, 1.3, 2], etiquetas: ["below normal", "normal", "above normal", "very high"] },
  horizonte: {
    arriesgadas: { name: "risky", horizon: "a few days", profile: "p" },
    usuarios: { name: "users", horizon: "weeks", profile: "p" },
  },
};

Deno.test("etiquetas: cortes", () => {
  const c = [-0.12, -0.04, 0.04, 0.12];
  assertEquals(etiquetaPorCortes(0.2, c, etiquetas.rendimiento.etiquetas), "strong gain");
  assertEquals(etiquetaPorCortes(0, c, etiquetas.rendimiento.etiquetas), "flat");
  assertEquals(etiquetaPorCortes(-1, c, etiquetas.rendimiento.etiquetas), "strong loss");
});

Deno.test("estado para JEV: solo etiquetas, sin cifras de las métricas, fechas ni datos de personas", () => {
  const m = calcularMetricas(serie(80, 123.45, 0.789));
  const estado = JSON.stringify(
    armarEstado({
      bolsillo: "arriesgadas", simbolo: "NVDA", sector: "Information Technology", metricas: m,
      percentilVolatilidad: 0.85, posicion: 2, totalCandidatas: 10,
      mercado: { metricas: m, percentilVolatilidad: 0.3 }, mercadoAbierto: false,
    }, etiquetas),
  );
  assert(!/\d+\.\d+/.test(estado), `hay cifras decimales: ${estado}`);
  assert(!/\d{4}-\d{2}-\d{2}/.test(estado), "hay una fecha");
  assert(!/@/.test(estado), "hay un correo");
  assert(!/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/.test(estado), "hay un uuid");
  for (const valor of [m.precio, m.rendimiento_20d, m.sma_50].map(String)) {
    assert(!estado.includes(valor), `se coló ${valor}`);
  }
  assert(estado.includes("2nd best of 10 candidates"));
  assert(estado.includes("market closed"));
});

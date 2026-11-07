// Pruebas del broker real con respuestas "grabadas" (fixtures/).
//
// Las respuestas de fixtures/ están escritas a mano con la forma documentada de la API de trading
// de Alpaca (v2/calendar, v2/clock y v2/assets); no se capturaron en vivo porque la sesión que las
// escribió no tiene, ni debe tener, llaves de Alpaca. La prueba real semanal contra Alpaca paper
// (docs/15 §6) es la que las contrasta con la API de verdad. Las fechas del calendario siguen los
// dos cambios de horario de verano de 2026 y la semana de Acción de Gracias.

import { assert, assertEquals, assertRejects } from "@std/assert";
import { ErrorDeProveedor } from "../mercado/interfaz.ts";
import { BrokerAlpaca } from "./alpaca.ts";

const KEY_ID = "CLAVE-ID-QUE-NO-DEBE-FILTRARSE";
const SECRET = "CLAVE-SECRETA-QUE-NO-DEBE-FILTRARSE";
const AHORA = new Date("2026-11-06T15:00:00Z");

async function fixture(nombre: string): Promise<unknown> {
  const texto = await Deno.readTextFile(
    new URL(`./fixtures/${nombre}`, import.meta.url),
  );
  return JSON.parse(texto);
}

interface Solicitud {
  url: URL;
  headers: Headers;
}

/** `fetch` falso: responde por ruta y anota cada solicitud. */
function fetchFalso(responder: (url: URL) => Response | Error) {
  const solicitudes: Solicitud[] = [];
  const fn = ((entrada: RequestInfo | URL, init?: RequestInit) => {
    const url = new URL(entrada.toString());
    solicitudes.push({ url, headers: new Headers(init?.headers) });
    const respuesta = responder(url);
    return respuesta instanceof Error
      ? Promise.reject(respuesta)
      : Promise.resolve(respuesta);
  }) as typeof fetch;
  return { fn, solicitudes };
}

function json(cuerpo: unknown, estado = 200): Response {
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: { "content-type": "application/json" },
  });
}

function crear(responder: (url: URL) => Response | Error) {
  const falso = fetchFalso(responder);
  const broker = new BrokerAlpaca({
    urlTrading: "https://paper-api.alpaca.markets/",
    keyId: KEY_ID,
    secretKey: SECRET,
    fetch: falso.fn,
  });
  return { broker, solicitudes: falso.solicitudes };
}

// Calendario -------------------------------------------------------------------------------

Deno.test("calendario: pasa a UTC la hora de Nueva York y resuelve el horario de verano (CA-4, CB-51)", async () => {
  const calendario = await fixture("calendario.json");
  const { broker, solicitudes } = crear(() => json(calendario));
  const dias = await broker.calendario(
    { desde: "2026-03-06", hasta: "2026-11-30" },
    AHORA,
  );
  const por = Object.fromEntries(dias.map((d) => [d.fecha, d]));

  // Antes del cambio de marzo (UTC−5) y después (UTC−4): la apertura se corre una hora en UTC.
  assertEquals(por["2026-03-06"].apertura, "2026-03-06T14:30:00.000Z");
  assertEquals(por["2026-03-06"].cierre, "2026-03-06T21:00:00.000Z");
  assertEquals(por["2026-03-09"].apertura, "2026-03-09T13:30:00.000Z");
  assertEquals(por["2026-03-09"].cierre, "2026-03-09T20:00:00.000Z");
  // Antes del cambio de noviembre (UTC−4) y después (UTC−5).
  assertEquals(por["2026-10-30"].apertura, "2026-10-30T13:30:00.000Z");
  assertEquals(por["2026-11-02"].apertura, "2026-11-02T14:30:00.000Z");

  assertEquals(solicitudes.length, 1);
  assertEquals(solicitudes[0].url.pathname, "/v2/calendar");
  assertEquals(solicitudes[0].url.searchParams.get("start"), "2026-03-06");
  assertEquals(solicitudes[0].url.searchParams.get("end"), "2026-11-30");
});

Deno.test("calendario: el feriado no aparece y la media jornada cierra a las 13:00 de Nueva York (CA-2, CA-3)", async () => {
  const calendario = await fixture("calendario.json");
  const { broker } = crear(() => json(calendario));
  const dias = await broker.calendario(
    { desde: "2026-11-24", hasta: "2026-11-30" },
    AHORA,
  );

  assertEquals(dias.map((d) => d.fecha), [
    "2026-11-24",
    "2026-11-25",
    "2026-11-27",
    "2026-11-30",
  ]);
  assert(!dias.some((d) => d.fecha === "2026-11-26"), "Acción de Gracias");
  const media = dias.find((d) => d.fecha === "2026-11-27")!;
  assertEquals(media.sesion, "media_jornada");
  assertEquals(media.cierre, "2026-11-27T18:00:00.000Z");
  assertEquals(dias.find((d) => d.fecha === "2026-11-25")!.sesion, "regular");
});

Deno.test("calendario: descarta lo que no sirve (horas invertidas, formato raro, fuera de rango)", async () => {
  const incoherentes = await fixture("calendario_con_incoherentes.json");
  const { broker } = crear(() => json(incoherentes));
  const dias = await broker.calendario(
    { desde: "2026-11-03", hasta: "2026-11-30" },
    AHORA,
  );
  assertEquals(dias.map((d) => d.fecha), ["2026-11-03", "2026-11-09"]);
});

Deno.test("calendario: un rango invertido no llama a Alpaca", async () => {
  const { broker, solicitudes } = crear(() => json([]));
  assertEquals(
    await broker.calendario(
      { desde: "2026-11-30", hasta: "2026-11-01" },
      AHORA,
    ),
    [],
  );
  assertEquals(solicitudes.length, 0);
});

// Reloj ------------------------------------------------------------------------------------

Deno.test("reloj: pasa los desfases a UTC", async () => {
  const reloj = await fixture("reloj.json");
  const { broker, solicitudes } = crear(() => json(reloj));
  const respuesta = await broker.reloj(AHORA);

  assertEquals(respuesta.abierto, false);
  assertEquals(respuesta.ahora, "2026-11-06T14:15:00.123Z");
  assertEquals(respuesta.proximaApertura, "2026-11-06T14:30:00.000Z");
  assertEquals(respuesta.proximoCierre, "2026-11-06T21:00:00.000Z");
  assertEquals(solicitudes[0].url.pathname, "/v2/clock");
});

Deno.test("reloj: una fecha inválida o un formato inesperado es un error del proveedor", async () => {
  const { broker } = crear(() =>
    json({
      timestamp: "no es una fecha",
      is_open: true,
      next_open: "2026-11-06T09:30:00-05:00",
      next_close: "2026-11-06T16:00:00-05:00",
    })
  );
  await assertRejects(
    () => broker.reloj(AHORA),
    ErrorDeProveedor,
    "fechas inválidas",
  );

  const { broker: otro } = crear(() => json({ is_open: true }));
  await assertRejects(
    () => otro.reloj(AHORA),
    ErrorDeProveedor,
    "formato inesperado",
  );
});

// Activos ----------------------------------------------------------------------------------

Deno.test("activos: negociable es activo y tradable; fraccionable sale de Alpaca; 404 no es negociable (CA-5, CA-7)", async () => {
  const respuestas: Record<string, unknown> = {
    AAPL: await fixture("activo_aapl.json"),
    SNDK: await fixture("activo_inactivo.json"),
    ASML: await fixture("activo_no_fraccionable.json"),
  };
  const { broker, solicitudes } = crear((url) => {
    const simbolo = url.pathname.split("/").pop()!;
    return simbolo in respuestas
      ? json(respuestas[simbolo])
      : json({ code: 40410000, message: "asset not found" }, 404);
  });
  const activos = await broker.activos([
    "AAPL",
    "SNDK",
    "ASML",
    "FANTASMA",
    "AAPL",
  ]);

  assertEquals(activos, [
    { simbolo: "AAPL", negociable: true, fraccionable: true },
    { simbolo: "SNDK", negociable: false, fraccionable: false },
    { simbolo: "ASML", negociable: true, fraccionable: false },
    { simbolo: "FANTASMA", negociable: false, fraccionable: false },
  ]);
  assertEquals(solicitudes.length, 4, "sin repetidos");
});

Deno.test("activos: consulta de a 10 en paralelo", async () => {
  const aapl = await fixture("activo_aapl.json");
  let enCurso = 0;
  let maximo = 0;
  const falso = fetchFalso(() => json(aapl));
  const original = falso.fn;
  const fn = (async (...args: Parameters<typeof fetch>) => {
    enCurso++;
    maximo = Math.max(maximo, enCurso);
    await new Promise((r) => setTimeout(r, 1));
    const respuesta = await original(...args);
    enCurso--;
    return respuesta;
  }) as typeof fetch;
  const broker = new BrokerAlpaca({
    urlTrading: "https://paper-api.alpaca.markets",
    keyId: KEY_ID,
    secretKey: SECRET,
    fetch: fn,
  });
  const simbolos = Array.from({ length: 25 }, (_, i) => `S${i}`);
  const activos = await broker.activos(simbolos);
  assertEquals(activos.length, 25);
  assertEquals(maximo, 10);
});

// Seguridad y errores ----------------------------------------------------------------------

Deno.test("las llaves viajan solo en cabeceras, nunca en la URL", async () => {
  const reloj = await fixture("reloj.json");
  const { broker, solicitudes } = crear(() => json(reloj));
  await broker.reloj(AHORA);
  const { url, headers } = solicitudes[0];
  assertEquals(headers.get("APCA-API-KEY-ID"), KEY_ID);
  assertEquals(headers.get("APCA-API-SECRET-KEY"), SECRET);
  assert(!url.toString().includes(KEY_ID) && !url.toString().includes(SECRET));
});

Deno.test("un error de Alpaca no copia las llaves en el mensaje", async () => {
  for (
    const respuesta of [
      json({ message: `forbidden ${KEY_ID} ${SECRET}` }, 403),
      new Error(`fallo con ${KEY_ID}`),
    ]
  ) {
    const { broker } = crear(() =>
      respuesta instanceof Response ? respuesta.clone() : respuesta
    );
    const error = await assertRejects(
      () => broker.reloj(AHORA),
      ErrorDeProveedor,
    );
    assert(!error.message.includes(KEY_ID) && !error.message.includes(SECRET));
  }
});

Deno.test("un 5xx, un cuerpo que no es JSON y un tiempo agotado son errores del proveedor", async () => {
  const { broker } = crear(() => json({}, 503));
  const error = await assertRejects(
    () => broker.reloj(AHORA),
    ErrorDeProveedor,
  );
  assertEquals(error.estado, 503);

  const { broker: sinJson } = crear(() =>
    new Response("<html>", { status: 200 })
  );
  await assertRejects(
    () => sinJson.reloj(AHORA),
    ErrorDeProveedor,
    "no es JSON",
  );

  const { broker: lento } = crear(() =>
    new DOMException("agotado", "TimeoutError") as unknown as Error
  );
  await assertRejects(() => lento.reloj(AHORA), ErrorDeProveedor, "a tiempo");
});

Deno.test("un 404 en el calendario sí es un error (solo el activo lo acepta)", async () => {
  const { broker } = crear(() => json({}, 404));
  await assertRejects(
    () =>
      broker.calendario({ desde: "2026-11-01", hasta: "2026-11-30" }, AHORA),
    ErrorDeProveedor,
    "404",
  );
});

Deno.test("exige las llaves y la URL", () => {
  for (
    const configuracion of [
      { urlTrading: "", keyId: "a", secretKey: "b" },
      { urlTrading: "https://x", keyId: "", secretKey: "b" },
      { urlTrading: "https://x", keyId: "a", secretKey: "" },
    ]
  ) {
    let lanzo = false;
    try {
      new BrokerAlpaca(configuracion);
    } catch (error) {
      lanzo = error instanceof ErrorDeProveedor;
    }
    assert(lanzo);
  }
});

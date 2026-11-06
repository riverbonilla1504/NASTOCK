// Pruebas del adaptador de Alpaca con respuestas "grabadas" (fixtures/).
//
// Las respuestas de fixtures/ están escritas a mano con la forma documentada de la API de
// datos de Alpaca (v2/stocks/bars y v2/stocks/snapshots); no se capturaron en vivo porque la
// sesión que las escribió no tiene, ni debe tener, llaves de Alpaca. La prueba real semanal
// contra Alpaca paper (docs/15 §6) es la que las contrasta con la API de verdad.

import { assert, assertEquals, assertRejects, assertThrows } from "@std/assert";
import { ErrorDeProveedor } from "./interfaz.ts";
import { MercadoAlpaca } from "./alpaca.ts";

const KEY_ID = "CLAVE-ID-QUE-NO-DEBE-FILTRARSE";
const SECRET = "CLAVE-SECRETA-QUE-NO-DEBE-FILTRARSE";

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

/** `fetch` falso: responde en orden y anota cada solicitud. */
function fetchFalso(respuestas: (Response | Error)[]) {
  const solicitudes: Solicitud[] = [];
  const fn = ((entrada: RequestInfo | URL, init?: RequestInit) => {
    solicitudes.push({
      url: new URL(entrada.toString()),
      headers: new Headers(init?.headers),
    });
    const siguiente = respuestas.shift();
    if (!siguiente) {
      return Promise.reject(new Error("no había más respuestas preparadas"));
    }
    return siguiente instanceof Error
      ? Promise.reject(siguiente)
      : Promise.resolve(siguiente);
  }) as typeof fetch;
  return { fn, solicitudes };
}

function json(cuerpo: unknown, estado = 200): Response {
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: { "content-type": "application/json" },
  });
}

function crear(respuestas: (Response | Error)[]) {
  const falso = fetchFalso(respuestas);
  const mercado = new MercadoAlpaca({
    urlDatos: "https://data.alpaca.markets/",
    keyId: KEY_ID,
    secretKey: SECRET,
    fetch: falso.fn,
  });
  return { mercado, solicitudes: falso.solicitudes };
}

const consulta = {
  simbolos: ["MSFT", "AAPL"],
  desde: "2024-11-05",
  hasta: "2025-06-02",
};

// Barras -----------------------------------------------------------------------------------

Deno.test("barras: junta las páginas y las ordena por símbolo y fecha", async () => {
  const { mercado, solicitudes } = crear([
    json(await fixture("barras_pagina_1.json")),
    json(await fixture("barras_pagina_2.json")),
  ]);

  const { barras, descartadas } = await mercado.barras(consulta);

  assertEquals(descartadas, 0);
  assertEquals(
    barras.map((b) => `${b.simbolo} ${b.fecha}`),
    [
      "AAPL 2024-11-05",
      "AAPL 2024-11-06",
      "MSFT 2024-11-05",
      "MSFT 2024-11-06",
      "MSFT 2025-06-02", // t = 04:00Z: medianoche de Nueva York con horario de verano
    ],
  );
  assertEquals(barras[0], {
    simbolo: "AAPL",
    fecha: "2024-11-05",
    apertura: 221.8,
    maximo: 223.95,
    minimo: 220.95,
    cierre: 222.91,
    volumen: 28111,
  });

  assertEquals(solicitudes.length, 2);
  assertEquals(solicitudes[0].url.searchParams.get("page_token"), null);
  assertEquals(
    solicitudes[1].url.searchParams.get("page_token"),
    "TOKEN-PAGINA-2",
  );
});

Deno.test("barras: pide dos símbolos en una llamada, con split, IEX y el día completo", async () => {
  const { mercado, solicitudes } = crear([
    json(await fixture("barras_vacia.json")),
  ]);
  await mercado.barras(consulta);

  const { url } = solicitudes[0];
  assertEquals(
    url.origin + url.pathname,
    "https://data.alpaca.markets/v2/stocks/bars",
  );
  const p = url.searchParams;
  assertEquals(p.get("symbols"), "AAPL,MSFT");
  assertEquals(p.get("timeframe"), "1Day");
  assertEquals(p.get("start"), "2024-11-05T00:00:00Z");
  assertEquals(p.get("end"), "2025-06-02T23:59:59Z");
  assertEquals(p.get("adjustment"), "split");
  assertEquals(p.get("feed"), "iex");
  assertEquals(p.get("sort"), "asc");
  assertEquals(p.get("limit"), "10000");
});

Deno.test("las llaves van en las cabeceras y nunca en la URL", async () => {
  const { mercado, solicitudes } = crear([
    json(await fixture("barras_vacia.json")),
  ]);
  await mercado.barras(consulta);
  const { url, headers } = solicitudes[0];
  assertEquals(headers.get("APCA-API-KEY-ID"), KEY_ID);
  assertEquals(headers.get("APCA-API-SECRET-KEY"), SECRET);
  assert(!url.toString().includes(KEY_ID) && !url.toString().includes(SECRET));
});

Deno.test("barras: sin datos o con la lista vacía devuelve vacío", async () => {
  for (const nombre of ["barras_vacia.json", "barras_sin_datos.json"]) {
    const { mercado } = crear([json(await fixture(nombre))]);
    assertEquals(await mercado.barras(consulta), {
      barras: [],
      descartadas: 0,
    });
  }
});

Deno.test("barras: sin símbolos o con el rango invertido no llama a Alpaca", async () => {
  const { mercado, solicitudes } = crear([]);
  assertEquals(await mercado.barras({ ...consulta, simbolos: [] }), {
    barras: [],
    descartadas: 0,
  });
  assertEquals(
    await mercado.barras({
      ...consulta,
      desde: "2026-01-02",
      hasta: "2026-01-01",
    }),
    {
      barras: [],
      descartadas: 0,
    },
  );
  assertEquals(solicitudes.length, 0);
});

Deno.test("barras: descarta y cuenta las incoherentes sin romper el lote", async () => {
  const { mercado } = crear([
    json(await fixture("barras_con_incoherentes.json")),
  ]);
  const { barras, descartadas } = await mercado.barras({
    simbolos: ["AAPL"],
    desde: "2024-11-05",
    hasta: "2024-11-11",
  });
  assertEquals(barras.map((b) => b.fecha), ["2024-11-05"]);
  // cierre mayor que el máximo · ceros · cierre que no es número · volumen con decimales
  assertEquals(descartadas, 4);
});

Deno.test("barras: ignora símbolos que no se pidieron y barras repetidas", async () => {
  const una = {
    c: 10,
    h: 11,
    l: 9,
    o: 10,
    t: "2024-11-05T05:00:00Z",
    v: 5,
  };
  const { mercado } = crear([
    json({ bars: { AAPL: [una, una], OTRO: [una] }, next_page_token: null }),
  ]);
  const { barras } = await mercado.barras({
    simbolos: ["AAPL"],
    desde: "2024-11-05",
    hasta: "2024-11-05",
  });
  assertEquals(barras.map((b) => b.simbolo), ["AAPL"]);
});

// Errores ----------------------------------------------------------------------------------

Deno.test("un estado de error lanza ErrorDeProveedor con el estado y sin llaves", async () => {
  for (const estado of [401, 403, 429, 500, 503]) {
    const { mercado } = crear([
      json({ code: 40110000, message: `fallo ${KEY_ID} ${SECRET}` }, estado),
    ]);
    const error = await assertRejects(
      () => mercado.barras(consulta),
      ErrorDeProveedor,
    );
    assertEquals((error as ErrorDeProveedor).estado, estado);
    assert(
      !error.message.includes(KEY_ID) && !error.message.includes(SECRET),
      error.message,
    );
    assert(error.message.includes(String(estado)));
  }
});

Deno.test("una página que falla a la mitad lanza el error (la carga retoma después)", async () => {
  const { mercado } = crear([
    json(await fixture("barras_pagina_1.json")),
    json({ message: "rate limit" }, 429),
  ]);
  const error = await assertRejects(
    () => mercado.barras(consulta),
    ErrorDeProveedor,
  );
  assertEquals((error as ErrorDeProveedor).estado, 429);
});

Deno.test("sin conexión, con tiempo agotado o con algo que no es JSON", async () => {
  {
    const { mercado } = crear([new TypeError(`fallo de red hacia ${KEY_ID}`)]);
    const error = await assertRejects(
      () => mercado.barras(consulta),
      ErrorDeProveedor,
      "No se pudo conectar con Alpaca",
    );
    assert(!error.message.includes(KEY_ID));
  }
  {
    const { mercado } = crear([new DOMException("tiempo", "TimeoutError")]);
    await assertRejects(
      () => mercado.barras(consulta),
      ErrorDeProveedor,
      "no respondió a tiempo",
    );
  }
  {
    const { mercado } = crear([
      new Response("<html>no es json</html>", { status: 200 }),
    ]);
    await assertRejects(
      () => mercado.barras(consulta),
      ErrorDeProveedor,
      "no es JSON",
    );
  }
});

Deno.test("una respuesta con otra forma lanza ErrorDeProveedor", async () => {
  for (
    const cuerpo of [
      { bars: "texto" },
      { bars: { AAPL: "x" } },
      [],
      "hola",
      null,
    ]
  ) {
    const { mercado } = crear([json(cuerpo)]);
    await assertRejects(
      () => mercado.barras(consulta),
      ErrorDeProveedor,
      "formato inesperado",
    );
  }
});

Deno.test("faltan las llaves: no se puede crear el adaptador", () => {
  for (
    const datos of [{ keyId: "", secretKey: "x" }, {
      keyId: "x",
      secretKey: "",
    }]
  ) {
    assertThrows(
      () =>
        new MercadoAlpaca({
          urlDatos: "https://data.alpaca.markets",
          ...datos,
        }),
      ErrorDeProveedor,
      "ALPACA_KEY_ID",
    );
  }
});

// Cotizaciones -----------------------------------------------------------------------------

Deno.test("snapshots: toma precio, bid, ask, cierre anterior y volumen", async () => {
  const { mercado, solicitudes } = crear([
    json(await fixture("snapshots.json")),
  ]);
  const cotizaciones = await mercado.snapshots(
    ["MSFT", "AAPL", "ZZZZ", "NADA"],
    new Date(),
  );

  assertEquals(cotizaciones, [
    {
      simbolo: "AAPL",
      precio: 225.5,
      bid: 225.48,
      ask: 225.52,
      cierreAnterior: 222.91,
      volumenDia: 300000,
      momento: "2024-11-06T15:00:01.123Z",
    },
    {
      simbolo: "MSFT",
      precio: 420.18,
      bid: null,
      ask: null,
      cierreAnterior: null,
      volumenDia: null,
      momento: "2024-11-06T15:00:00.000Z",
    },
    // ZZZZ llega sin última operación y NADA no llega: no hay precio, no hay cotización.
  ]);

  const { url } = solicitudes[0];
  assertEquals(
    url.origin + url.pathname,
    "https://data.alpaca.markets/v2/stocks/snapshots",
  );
  assertEquals(url.searchParams.get("symbols"), "AAPL,MSFT,NADA,ZZZZ");
  assertEquals(url.searchParams.get("feed"), "iex");
});

Deno.test("snapshots: sin símbolos no llama a Alpaca y un error se informa", async () => {
  const { mercado, solicitudes } = crear([json({ message: "no" }, 403)]);
  assertEquals(await mercado.snapshots([], new Date()), []);
  assertEquals(solicitudes.length, 0);
  await assertRejects(
    () => mercado.snapshots(["AAPL"], new Date()),
    ErrorDeProveedor,
    "403",
  );
});

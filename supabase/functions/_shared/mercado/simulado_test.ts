import { assert, assertAlmostEquals, assertEquals } from "@std/assert";
import { esBarraCoherente } from "./interfaz.ts";
import {
  baseDe,
  esDiaHabil,
  fechaDeIndice,
  indiceDeDia,
  MercadoSimulado,
  semillaDe,
} from "./simulado.ts";
import { horaDeNuevaYork } from "./tiempo.ts";

const mercado = new MercadoSimulado();

// Valores conocidos ------------------------------------------------------------------------
// Los mismos valores los comprueba supabase/tests/database/02_universo_y_barras_test.sql contra
// las barras que siembra seed.sql: así el algoritmo en TypeScript y el de SQL no se separan.
// Si cambias el algoritmo, cambia seed.sql y estas dos listas (contracts/mercado.md).
export const VALORES_CONOCIDOS = [
  {
    simbolo: "QQQ",
    fecha: "2026-06-01",
    apertura: 389.822,
    maximo: 390.4826,
    minimo: 387.4463,
    cierre: 388.5635,
    volumen: 1156260,
  },
  {
    simbolo: "AAPL",
    fecha: "2026-06-01",
    apertura: 128.0763,
    maximo: 129.3337,
    minimo: 126.8377,
    cierre: 127.0639,
    volumen: 919189,
  },
  {
    simbolo: "TQQQ",
    fecha: "2025-11-03",
    apertura: 62.345,
    maximo: 62.6551,
    minimo: 60.4177,
    cierre: 60.8589,
    volumen: 1467833,
  },
];

Deno.test("las barras de valores conocidos no cambian", async () => {
  for (const esperada of VALORES_CONOCIDOS) {
    const { barras } = await mercado.barras({
      simbolos: [esperada.simbolo],
      desde: esperada.fecha,
      hasta: esperada.fecha,
    });
    assertEquals(barras, [esperada]);
  }
});

Deno.test("la semilla y la base salen de las letras del símbolo", () => {
  // ((81 · 31 + 81) · 31 + 81) con 81 = código de "Q"
  assertEquals(semillaDe("QQQ"), 80433);
  assertEquals(baseDe("QQQ"), 400);
  assertEquals(baseDe("QLD"), 80);
  assertEquals(baseDe("TQQQ"), 60);
  assertEquals(baseDe("AAPL"), 30 + (semillaDe("AAPL") % 370));
  for (const simbolo of ["AAPL", "MSFT", "NVDA", "SPCX", "ZS"]) {
    assert(baseDe(simbolo) >= 30 && baseDe(simbolo) < 400, simbolo);
  }
});

// Determinismo -----------------------------------------------------------------------------

Deno.test("la misma consulta da siempre el mismo resultado", async () => {
  const consulta = {
    simbolos: ["MSFT", "AAPL"],
    desde: "2025-01-01",
    hasta: "2025-03-31",
  };
  const a = await new MercadoSimulado().barras(consulta);
  const b = await new MercadoSimulado().barras(consulta);
  assertEquals(a, b);
  assertEquals(a.descartadas, 0);
});

Deno.test("una barra no depende del rango que se pidió", async () => {
  const larga = await mercado.barras({
    simbolos: ["NVDA"],
    desde: "2024-11-05",
    hasta: "2026-11-04",
  });
  const corta = await mercado.barras({
    simbolos: ["NVDA"],
    desde: "2026-05-25",
    hasta: "2026-06-05",
  });
  const recorte = larga.barras.filter((b) =>
    b.fecha >= "2026-05-25" && b.fecha <= "2026-06-05"
  );
  assert(corta.barras.length > 0);
  assertEquals(corta.barras, recorte);
});

Deno.test("la lista de símbolos se ordena y no repite", async () => {
  const { barras } = await mercado.barras({
    simbolos: ["QQQ", "AAPL", "QQQ"],
    desde: "2026-06-01",
    hasta: "2026-06-02",
  });
  assertEquals(barras.map((b) => `${b.simbolo} ${b.fecha}`), [
    "AAPL 2026-06-01",
    "AAPL 2026-06-02",
    "QQQ 2026-06-01",
    "QQQ 2026-06-02",
  ]);
});

// Días hábiles y rangos --------------------------------------------------------------------

Deno.test("solo hay barras de lunes a viernes", async () => {
  // 2026-06-01 es lunes; el rango cubre dos fines de semana.
  const { barras } = await mercado.barras({
    simbolos: ["QQQ"],
    desde: "2026-05-29",
    hasta: "2026-06-09",
  });
  assertEquals(
    barras.map((b) => b.fecha),
    [
      "2026-05-29",
      "2026-06-01",
      "2026-06-02",
      "2026-06-03",
      "2026-06-04",
      "2026-06-05",
      "2026-06-08",
      "2026-06-09",
    ],
  );
  for (const barra of barras) {
    assert(esDiaHabil(indiceDeDia(barra.fecha)), barra.fecha);
  }
});

Deno.test("un rango sin días hábiles, invertido o anterior al ancla no da barras", async () => {
  for (
    const [desde, hasta] of [
      ["2026-06-06", "2026-06-07"], // sábado y domingo
      ["2026-06-10", "2026-06-01"], // invertido
      ["2019-01-01", "2019-12-31"], // antes del ancla
    ]
  ) {
    const { barras } = await mercado.barras({
      simbolos: ["QQQ"],
      desde,
      hasta,
    });
    assertEquals(barras, [], `${desde} a ${hasta}`);
  }
});

Deno.test("los índices de día y las fechas son inversos", () => {
  assertEquals(indiceDeDia("2000-01-01"), 0);
  assertEquals(fechaDeIndice(0), "2000-01-01");
  for (const fecha of ["2020-01-01", "2024-02-29", "2026-11-05"]) {
    assertEquals(fechaDeIndice(indiceDeDia(fecha)), fecha);
  }
});

// Coherencia -------------------------------------------------------------------------------

Deno.test("cada barra cumple las restricciones de barras_diarias", async () => {
  const simbolos = [
    "QQQ",
    "QLD",
    "TQQQ",
    "AAPL",
    "MSFT",
    "NVDA",
    "SPCX",
    "ZS",
    "GOOGL",
  ];
  const { barras } = await mercado.barras({
    simbolos,
    desde: "2024-11-05",
    hasta: "2026-11-04",
  });
  assert(barras.length > simbolos.length * 500);
  for (const barra of barras) {
    assert(esBarraCoherente(barra), JSON.stringify(barra));
  }
});

Deno.test("QLD y TQQQ siguen a QQQ con retorno diario de ×2 y ×3", async () => {
  const { barras } = await mercado.barras({
    simbolos: ["QQQ", "QLD", "TQQQ"],
    desde: "2026-01-01",
    hasta: "2026-03-31",
  });
  const cierres = (simbolo: string) =>
    barras.filter((b) => b.simbolo === simbolo).map((b) => b.cierre);
  const retornos = (serie: number[]) =>
    serie.slice(1).map((c, i) => Math.log(c / serie[i]));
  const qqq = retornos(cierres("QQQ"));
  const qld = retornos(cierres("QLD"));
  const tqqq = retornos(cierres("TQQQ"));
  assert(qqq.length > 50);
  qqq.forEach((r, i) => {
    assertAlmostEquals(qld[i], 2 * r, 1e-4);
    assertAlmostEquals(tqqq[i], 3 * r, 1e-4);
  });
});

// Cotizaciones -----------------------------------------------------------------------------

Deno.test("en sesión, la cotización queda dentro de la barra del día y se repite para la misma hora", async () => {
  // Miércoles 2026-11-04 15:00 UTC = 10:00 en Nueva York (horario de invierno).
  const ahora = new Date("2026-11-04T15:00:00Z");
  assertEquals(horaDeNuevaYork(ahora), { fecha: "2026-11-04", minutos: 600 });

  const [cotizacion] = await mercado.snapshots(["NVDA"], ahora);
  const [otra] = await mercado.snapshots(["NVDA"], ahora);
  assertEquals(cotizacion, otra);

  const { barras: [dia, ...resto] } = await mercado.barras({
    simbolos: ["NVDA"],
    desde: "2026-11-04",
    hasta: "2026-11-04",
  });
  assertEquals(resto, []);
  assert(cotizacion.precio >= dia.minimo && cotizacion.precio <= dia.maximo);
  assertEquals(cotizacion.momento, "2026-11-04T15:00:00.000Z");
  assertAlmostEquals(cotizacion.ask! - cotizacion.bid!, 0.02, 1e-9);
  assert(
    cotizacion.bid! < cotizacion.precio && cotizacion.precio < cotizacion.ask!,
  );
  assert(cotizacion.volumenDia! > 0 && cotizacion.volumenDia! < dia.volumen);

  const { barras: [anterior] } = await mercado.barras({
    simbolos: ["NVDA"],
    desde: "2026-11-03",
    hasta: "2026-11-03",
  });
  assertEquals(cotizacion.cierreAnterior, anterior.cierre);
});

Deno.test("otra hora da otro precio", async () => {
  const [a] = await mercado.snapshots(
    ["NVDA"],
    new Date("2026-11-04T15:00:00Z"),
  );
  const [b] = await mercado.snapshots(
    ["NVDA"],
    new Date("2026-11-04T15:01:00Z"),
  );
  assert(a.precio !== b.precio);
});

Deno.test("fuera de sesión, la cotización es el cierre de la última sesión completa", async () => {
  const casos = [
    // Sábado: la última sesión es la del viernes 2026-11-06, que cerró a las 21:00 UTC.
    {
      ahora: "2026-11-07T15:00:00Z",
      sesion: "2026-11-06",
      momento: "2026-11-06T21:00:00.000Z",
    },
    // Miércoles después del cierre (17:00 en Nueva York).
    {
      ahora: "2026-11-04T22:00:00Z",
      sesion: "2026-11-04",
      momento: "2026-11-04T21:00:00.000Z",
    },
    // Jueves antes de abrir (07:00 en Nueva York): la sesión completa es la de ayer.
    {
      ahora: "2026-11-05T12:00:00Z",
      sesion: "2026-11-04",
      momento: "2026-11-04T21:00:00.000Z",
    },
    // Con horario de verano el cierre es a las 20:00 UTC.
    {
      ahora: "2026-06-02T01:00:00Z",
      sesion: "2026-06-01",
      momento: "2026-06-01T20:00:00.000Z",
    },
  ];
  for (const caso of casos) {
    const [cotizacion] = await mercado.snapshots(["QQQ"], new Date(caso.ahora));
    const { barras: [dia] } = await mercado.barras({
      simbolos: ["QQQ"],
      desde: caso.sesion,
      hasta: caso.sesion,
    });
    assertEquals(cotizacion.momento, caso.momento, caso.ahora);
    assertAlmostEquals(cotizacion.precio, dia.cierre, 1e-3, caso.ahora);
    assertEquals(cotizacion.volumenDia, dia.volumen, caso.ahora);
  }
});

Deno.test("varios símbolos: salen ordenados y sin repetir", async () => {
  const cotizaciones = await mercado.snapshots(
    ["QQQ", "AAPL", "QQQ"],
    new Date("2026-11-04T15:00:00Z"),
  );
  assertEquals(cotizaciones.map((c) => c.simbolo), ["AAPL", "QQQ"]);
});

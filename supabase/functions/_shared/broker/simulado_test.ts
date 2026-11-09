import { assert, assertEquals } from "@std/assert";
import { BrokerSimulado, MODOS_DE_RELOJ } from "./simulado.ts";

// 2026-11-05 es jueves; 15:00 UTC son las 10:00 en Nueva York (UTC−5).
const AHORA = new Date("2026-11-05T15:00:00Z");

Deno.test("modo calendario: lunes a viernes, 9:30–16:00 de Nueva York en UTC", async () => {
  const broker = new BrokerSimulado();
  const dias = await broker.calendario(
    { desde: "2026-11-05", hasta: "2026-11-10" },
    AHORA,
  );
  // jueves 5, viernes 6, lunes 9 y martes 10; sábado y domingo no.
  assertEquals(dias.map((d) => d.fecha), [
    "2026-11-05",
    "2026-11-06",
    "2026-11-09",
    "2026-11-10",
  ]);
  assertEquals(dias[0], {
    fecha: "2026-11-05",
    apertura: "2026-11-05T14:30:00.000Z",
    cierre: "2026-11-05T21:00:00.000Z",
    sesion: "regular",
  });
});

Deno.test("modo calendario: resuelve el horario de verano sin intervención (CB-51)", async () => {
  const broker = new BrokerSimulado();
  const [antes, despues] = await broker.calendario(
    { desde: "2026-03-06", hasta: "2026-03-09" },
    AHORA,
  ).then((d) => [d[0], d[d.length - 1]]);
  assertEquals(antes.apertura, "2026-03-06T14:30:00.000Z");
  assertEquals(despues.apertura, "2026-03-09T13:30:00.000Z");
});

Deno.test("modo calendario: feriados y medias jornadas inyectados (CB-49, CB-50)", async () => {
  const broker = new BrokerSimulado({
    excepciones: { "2026-11-26": "feriado", "2026-11-27": "media_jornada" },
  });
  const dias = await broker.calendario(
    { desde: "2026-11-25", hasta: "2026-11-30" },
    AHORA,
  );
  assertEquals(dias.map((d) => d.fecha), [
    "2026-11-25",
    "2026-11-27",
    "2026-11-30",
  ]);
  const media = dias[1];
  assertEquals(media.sesion, "media_jornada");
  assertEquals(media.cierre, "2026-11-27T18:00:00.000Z");
});

Deno.test("modo siempre_abierto: la sesión de hoy rodea a ahora", async () => {
  const broker = new BrokerSimulado({ modo: "siempre_abierto" });
  const reloj = await broker.reloj(AHORA);
  assertEquals(reloj.abierto, true);
  const [hoy] = await broker.calendario(
    { desde: "2026-11-05", hasta: "2026-11-05" },
    AHORA,
  );
  assert(Date.parse(hoy.apertura) < AHORA.getTime());
  assert(Date.parse(hoy.cierre) > AHORA.getTime());
  assertEquals(hoy.sesion, "regular");
});

Deno.test("modo siempre_abierto sirve también un sábado", async () => {
  const sabado = new Date("2026-11-07T15:00:00Z");
  const broker = new BrokerSimulado({ modo: "siempre_abierto" });
  assertEquals((await broker.reloj(sabado)).abierto, true);
});

Deno.test("modo cerrado: hoy no hay sesión y el reloj marca cerrado", async () => {
  const broker = new BrokerSimulado({ modo: "cerrado" });
  const dias = await broker.calendario(
    { desde: "2026-11-05", hasta: "2026-11-06" },
    AHORA,
  );
  assertEquals(dias.map((d) => d.fecha), ["2026-11-06"]);
  const reloj = await broker.reloj(AHORA);
  assertEquals(reloj.abierto, false);
  assertEquals(reloj.proximaApertura, "2026-11-06T14:30:00.000Z");
});

Deno.test("modo cierre_en_10_min: cierra 10 minutos después de ahora", async () => {
  const broker = new BrokerSimulado({ modo: "cierre_en_10_min" });
  const reloj = await broker.reloj(AHORA);
  assertEquals(reloj.abierto, true);
  assertEquals(reloj.proximoCierre, "2026-11-05T15:10:00.000Z");
});

Deno.test("reloj en modo calendario: cerrado antes de abrir, abierto en sesión, cerrado al cerrar", async () => {
  const broker = new BrokerSimulado();
  const antes = await broker.reloj(new Date("2026-11-05T14:29:00Z"));
  assertEquals(antes.abierto, false);
  assertEquals(antes.proximaApertura, "2026-11-05T14:30:00.000Z");
  assertEquals(
    (await broker.reloj(new Date("2026-11-05T14:30:00Z"))).abierto,
    true,
  );
  const alCierre = await broker.reloj(new Date("2026-11-05T21:00:00Z"));
  assertEquals(alCierre.abierto, false);
  assertEquals(alCierre.proximaApertura, "2026-11-06T14:30:00.000Z");
});

Deno.test("activos: todo negociable y fraccionable salvo lo que se configura", async () => {
  const broker = new BrokerSimulado({
    noNegociables: ["SNDK"],
    noFraccionables: ["ASML"],
    desconocidos: ["FANTASMA"],
  });
  assertEquals(
    await broker.activos(["AAPL", "SNDK", "ASML", "FANTASMA", "AAPL"]),
    [
      { simbolo: "AAPL", negociable: true, fraccionable: true },
      { simbolo: "SNDK", negociable: false, fraccionable: true },
      { simbolo: "ASML", negociable: true, fraccionable: false },
      { simbolo: "FANTASMA", negociable: false, fraccionable: false },
    ],
  );
});

Deno.test("hay cuatro modos de reloj y el primero es el de por defecto", () => {
  assertEquals([...MODOS_DE_RELOJ], [
    "calendario",
    "siempre_abierto",
    "cerrado",
    "cierre_en_10_min",
  ]);
  assertEquals(new BrokerSimulado().modo, "calendario");
});

Deno.test("cuenta: el efectivo por defecto es el de una cuenta paper nueva y se puede configurar", async () => {
  assertEquals(await new BrokerSimulado().cuenta(), { efectivo: 100_000 });
  assertEquals(await new BrokerSimulado({ efectivo: 10_000 }).cuenta(), {
    efectivo: 10_000,
  });
});

import { assertEquals } from "@std/assert";
import type { Argumento, Bd } from "../_shared/bd.ts";
import { BrokerSimulado } from "../_shared/broker/simulado.ts";
import {
  CALENDARIO_DIAS_ADELANTE,
  contrastarReloj,
  sincronizarActivos,
  sincronizarCalendario,
} from "./sincronizacion.ts";

interface Llamada {
  funcion: string;
  argumentos: readonly Argumento[];
}

/** Base falsa que anota cada llamada y responde con filas fijas por función. */
function bdFalsa(respuestas: Record<string, Record<string, unknown>[]>) {
  const llamadas: Llamada[] = [];
  const bd: Bd = {
    llamar<T = Record<string, unknown>>(
      funcion: string,
      argumentos: readonly Argumento[] = [],
    ) {
      llamadas.push({ funcion, argumentos });
      return Promise.resolve((respuestas[funcion] ?? []) as T[]);
    },
    cerrar: () => Promise.resolve(),
  };
  return { bd, llamadas };
}

Deno.test("calendario: el rango empieza hoy en Nueva York y llega a 60 días", async () => {
  // 03:00 UTC del 6 de noviembre son las 22:00 del 5 en Nueva York: hoy es el 5.
  const ahora = new Date("2026-11-06T03:00:00Z");
  const { bd, llamadas } = bdFalsa({
    sincronizar_calendario: [{ guardados: 43, eliminados: 0 }],
  });
  const resultado = await sincronizarCalendario({
    bd,
    broker: new BrokerSimulado(),
    ahora,
  });

  assertEquals(resultado.desde, "2026-11-05");
  assertEquals(resultado.hasta, "2027-01-04");
  assertEquals(CALENDARIO_DIAS_ADELANTE, 60);
  assertEquals(resultado.dias_guardados, 43);
  assertEquals(resultado.dias_eliminados, 0);

  const [llamada] = llamadas;
  assertEquals(llamada.funcion, "sincronizar_calendario");
  assertEquals(llamada.argumentos[0], "2026-11-05");
  assertEquals(llamada.argumentos[1], "2027-01-04");
  const dias = llamada.argumentos[2] as { fecha: string }[];
  assertEquals(resultado.dias_recibidos, dias.length);
  assertEquals(dias[0].fecha, "2026-11-05");
});

Deno.test("calendario: las horas viajan en UTC y la media jornada con su sesión", async () => {
  const ahora = new Date("2026-11-20T15:00:00Z");
  const { bd, llamadas } = bdFalsa({
    sincronizar_calendario: [{ guardados: 1, eliminados: 0 }],
  });
  await sincronizarCalendario({
    bd,
    broker: new BrokerSimulado({
      excepciones: { "2026-11-26": "feriado", "2026-11-27": "media_jornada" },
    }),
    ahora,
  });
  const dias = llamadas[0].argumentos[2] as {
    fecha: string;
    apertura: string;
    cierre: string;
    sesion: string;
  }[];
  assertEquals(dias.some((d) => d.fecha === "2026-11-26"), false);
  assertEquals(dias.find((d) => d.fecha === "2026-11-27"), {
    fecha: "2026-11-27",
    apertura: "2026-11-27T14:30:00.000Z",
    cierre: "2026-11-27T18:00:00.000Z",
    sesion: "media_jornada",
  });
});

Deno.test("reloj: coincide cuando broker y calendario dicen lo mismo", async () => {
  const ahora = new Date("2026-11-05T15:00:00Z"); // 10:00 en Nueva York, jueves
  const { bd } = bdFalsa({ mercado_abierto: [{ mercado_abierto: true }] });
  assertEquals(
    await contrastarReloj({ bd, broker: new BrokerSimulado(), ahora }),
    { abierto_broker: true, abierto_bd: true, coincide: true },
  );
});

Deno.test("reloj: informa la discrepancia sin lanzar", async () => {
  const ahora = new Date("2026-11-05T15:00:00Z");
  const { bd } = bdFalsa({ mercado_abierto: [{ mercado_abierto: false }] });
  assertEquals(
    await contrastarReloj({ bd, broker: new BrokerSimulado(), ahora }),
    { abierto_broker: true, abierto_bd: false, coincide: false },
  );
});

Deno.test("activos: consulta el universo y reporta lo desactivado, sin repetidos", async () => {
  const { bd, llamadas } = bdFalsa({
    simbolos_del_universo: [{ simbolo: "AAPL" }, { simbolo: "QQQ" }, {
      simbolo: "SNDK",
    }],
    sincronizar_activos: [
      { bolsillo: "arriesgadas", simbolo: "AAPL", desactivado: false },
      { bolsillo: "usuarios", simbolo: "QQQ", desactivado: false },
      { bolsillo: "arriesgadas", simbolo: "SNDK", desactivado: true },
      { bolsillo: "usuarios", simbolo: "SNDK", desactivado: true },
    ],
  });
  const resultado = await sincronizarActivos({
    bd,
    broker: new BrokerSimulado({ noNegociables: ["SNDK"] }),
  });

  assertEquals(resultado, {
    consultados: 3,
    actualizados: 4,
    desactivados: ["SNDK"],
  });
  assertEquals(llamadas[1].funcion, "sincronizar_activos");
  assertEquals(llamadas[1].argumentos[0], [
    { simbolo: "AAPL", negociable: true, fraccionable: true },
    { simbolo: "QQQ", negociable: true, fraccionable: true },
    { simbolo: "SNDK", negociable: false, fraccionable: true },
  ]);
});

Deno.test("activos: sin símbolos en el universo no llama al broker ni guarda", async () => {
  const { bd, llamadas } = bdFalsa({ simbolos_del_universo: [] });
  const resultado = await sincronizarActivos({
    bd,
    broker: {
      calendario: () => Promise.reject(new Error("no debería llamarse")),
      reloj: () => Promise.reject(new Error("no debería llamarse")),
      activos: () => Promise.reject(new Error("no debería llamarse")),
      cuenta: () => Promise.reject(new Error("no debería llamarse")),
      enviarOrden: () => Promise.reject(new Error("no debería llamarse")),
      consultarOrden: () => Promise.reject(new Error("no debería llamarse")),
      cancelarOrden: () => Promise.reject(new Error("no debería llamarse")),
      posiciones: () => Promise.reject(new Error("no debería llamarse")),
    },
  });
  assertEquals(resultado, {
    consultados: 0,
    actualizados: 0,
    desactivados: [],
  });
  assertEquals(llamadas.map((l) => l.funcion), ["simbolos_del_universo"]);
});

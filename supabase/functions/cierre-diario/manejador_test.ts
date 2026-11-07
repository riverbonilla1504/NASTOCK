import { assertEquals } from "@std/assert";
import { type Argumento, type Bd, ErrorDeBd } from "../_shared/bd.ts";
import {
  ErrorDeProveedor,
  type ProveedorDeMercado,
} from "../_shared/mercado/interfaz.ts";
import { MercadoSimulado } from "../_shared/mercado/simulado.ts";
import { crearManejador } from "./manejador.ts";

const SECRETO = "secreto-de-prueba";
// Jueves 2026-11-05, después del cierre (21:00 UTC): "hoy" en Nueva York es el 5.
const AHORA = new Date("2026-11-05T21:30:00Z");
const SIMBOLOS = ["AAPL", "QLD", "QQQ"];

function bdFalsa(opciones: { falla?: Error; universo?: string[] } = {}) {
  const estado = {
    cerrada: false,
    guardadas: [] as { simbolo: string; fecha: string }[],
  };
  const bd: Bd = {
    llamar<T = Record<string, unknown>>(
      funcion: string,
      argumentos: readonly Argumento[] = [],
    ) {
      if (opciones.falla) return Promise.reject(opciones.falla);
      switch (funcion) {
        case "ahora":
          return Promise.resolve([{ ahora: AHORA }] as T[]);
        case "simbolos_del_universo":
          return Promise.resolve(
            (opciones.universo ?? SIMBOLOS).map((simbolo) => ({
              simbolo,
            })) as T[],
          );
        case "guardar_barras_diarias": {
          const barras = argumentos[0] as { simbolo: string; fecha: string }[];
          estado.guardadas.push(...barras);
          return Promise.resolve(
            [{ guardar_barras_diarias: barras.length }] as T[],
          );
        }
        default:
          return Promise.reject(
            new ErrorDeBd(`función inesperada: ${funcion}`),
          );
      }
    },
    cerrar() {
      estado.cerrada = true;
      return Promise.resolve();
    },
  };
  return { bd, estado };
}

function manejadorCon(
  opciones: { mercado?: ProveedorDeMercado; bd?: Bd } = {},
) {
  const aperturas = { cuantas: 0 };
  const manejador = crearManejador({
    mercado: opciones.mercado ?? new MercadoSimulado(),
    abrirBd: () => {
      aperturas.cuantas++;
      return opciones.bd ?? bdFalsa().bd;
    },
    secreto: SECRETO,
  });
  return { manejador, aperturas };
}

function post(cabeceras: Record<string, string> = {}): Request {
  return new Request("http://localhost/functions/v1/cierre-diario", {
    method: "POST",
    headers: cabeceras,
    body: "{}",
  });
}

const CON_SECRETO = { "x-secreto-interno": SECRETO };

Deno.test("CA-1: guarda la barra de hoy de cada símbolo del universo", async () => {
  const { bd, estado } = bdFalsa();
  const { manejador } = manejadorCon({ bd });

  const respuesta = await manejador(post(CON_SECRETO));
  const cuerpo = await respuesta.json();

  assertEquals(respuesta.status, 200);
  assertEquals(cuerpo.fecha, "2026-11-05");
  assertEquals(cuerpo.simbolos_consultados, 3);
  assertEquals(cuerpo.barras_nuevas, 3);
  assertEquals(cuerpo.sin_datos, []);
  assertEquals(cuerpo.pendientes, []);
  assertEquals(estado.guardadas.map((b) => b.simbolo).sort(), SIMBOLOS);
  assertEquals(
    new Set(estado.guardadas.map((b) => b.fecha)),
    new Set(["2026-11-05"]),
  );
  assertEquals(estado.cerrada, true);
});

Deno.test("pide los símbolos en lotes y solo guarda la fecha de hoy", async () => {
  const pedidos: string[][] = [];
  const mercado: ProveedorDeMercado = {
    snapshots: () => Promise.resolve([]),
    barras: (consulta) => {
      pedidos.push([...consulta.simbolos]);
      assertEquals(consulta.desde, "2026-11-05");
      assertEquals(consulta.hasta, "2026-11-05");
      // Trae también la barra de ayer: no debe guardarse.
      return new MercadoSimulado().barras({ ...consulta, desde: "2026-11-04" });
    },
  };
  const universo = Array.from(
    { length: 45 },
    (_, i) => `S${String(i).padStart(2, "0")}`,
  );
  const { bd, estado } = bdFalsa({ universo });
  const { manejador } = manejadorCon({ bd, mercado });

  const respuesta = await manejador(post(CON_SECRETO));
  const cuerpo = await respuesta.json();

  assertEquals(pedidos.map((p) => p.length), [20, 20, 5]);
  assertEquals(cuerpo.barras_nuevas, 45);
  assertEquals(estado.guardadas.every((b) => b.fecha === "2026-11-05"), true);
});

Deno.test("un símbolo sin barra de hoy queda en sin_datos", async () => {
  const mercado: ProveedorDeMercado = {
    snapshots: () => Promise.resolve([]),
    barras: async (consulta) => {
      const r = await new MercadoSimulado().barras(consulta);
      return { ...r, barras: r.barras.filter((b) => b.simbolo !== "AAPL") };
    },
  };
  const { manejador } = manejadorCon({ mercado });
  const respuesta = await manejador(post(CON_SECRETO));
  const cuerpo = await respuesta.json();
  assertEquals(respuesta.status, 200);
  assertEquals(cuerpo.sin_datos, ["AAPL"]);
  assertEquals(cuerpo.barras_nuevas, 2);
});

Deno.test("si el proveedor falla responde 502 con lo pendiente", async () => {
  const mercado: ProveedorDeMercado = {
    snapshots: () => Promise.resolve([]),
    barras: () =>
      Promise.reject(new ErrorDeProveedor("Alpaca respondió 500", 500)),
  };
  const { bd, estado } = bdFalsa();
  const { manejador } = manejadorCon({ bd, mercado });
  const respuesta = await manejador(post(CON_SECRETO));
  const cuerpo = await respuesta.json();
  assertEquals(respuesta.status, 502);
  assertEquals(cuerpo.codigo, "INTEGRACION_CAIDA");
  assertEquals(cuerpo.pendientes, SIMBOLOS);
  assertEquals(estado.cerrada, true);
});

Deno.test("un fallo de la base responde 500 sin detalles y cierra la conexión", async () => {
  const { bd, estado } = bdFalsa({ falla: new ErrorDeBd("caída") });
  const { manejador } = manejadorCon({ bd });
  const respuesta = await manejador(post(CON_SECRETO));
  assertEquals(respuesta.status, 500);
  assertEquals(await respuesta.json(), { error: "interno" });
  assertEquals(estado.cerrada, true);
});

Deno.test("un secreto incorrecto responde 403 y no abre la base", async () => {
  const { manejador, aperturas } = manejadorCon();
  const respuesta = await manejador(post({ "x-secreto-interno": "otro" }));
  assertEquals(respuesta.status, 403);
  assertEquals(await respuesta.json(), { codigo: "NO_AUTORIZADO" });
  assertEquals(aperturas.cuantas, 0);
});

Deno.test("sin secreto ni sesión responde 401; un JWT tampoco sirve", async () => {
  const { manejador, aperturas } = manejadorCon();
  const casos: Record<string, string>[] = [
    {},
    { Authorization: "Bearer eyJ.fake.token" },
  ];
  for (const cabeceras of casos) {
    const respuesta = await manejador(post(cabeceras));
    assertEquals(respuesta.status, 401);
    assertEquals(await respuesta.json(), { codigo: "SESION_INVALIDA" });
  }
  assertEquals(aperturas.cuantas, 0);
});

Deno.test("otro método que POST responde 405", async () => {
  const { manejador, aperturas } = manejadorCon();
  const respuesta = await manejador(
    new Request("http://localhost/functions/v1/cierre-diario", {
      method: "GET",
      headers: CON_SECRETO,
    }),
  );
  assertEquals(respuesta.status, 405);
  await respuesta.body?.cancel();
  assertEquals(aperturas.cuantas, 0);
});

// Pruebas de ingesta-mercado (HU-028): autenticación (CA-5), mercado cerrado (CA-3), precio inválido
// (CA-2, CB-53), fallo del proveedor (CA-4) y el lote completo (CA-1) con una base y un proveedor falsos.

import { assert, assertEquals } from "@std/assert";
import { type Argumento, type Bd } from "../_shared/bd.ts";
import {
  type Cotizacion,
  ErrorDeProveedor,
  type ProveedorDeMercado,
} from "../_shared/mercado/interfaz.ts";
import { crearManejador, validarCotizaciones } from "./manejador.ts";

const SECRETO = "secreto-de-prueba";
const AHORA = new Date("2026-11-05T15:00:00Z");
const UNIVERSO = ["AAPL", "QLD", "QQQ"];

function cotizacion(simbolo: string, precio: number): Cotizacion {
  return {
    simbolo,
    precio,
    bid: null,
    ask: null,
    cierreAnterior: 100,
    volumenDia: 10,
    momento: "2026-11-05T14:59:50.000Z",
  };
}

function bdFalsa(opciones: { enVentana?: boolean } = {}) {
  const estado = {
    cerrada: false,
    lotes: [] as unknown[][],
    llamadas: [] as string[],
    intervalo: undefined as unknown,
  };
  const bd: Bd = {
    llamar<T = Record<string, unknown>>(
      funcion: string,
      argumentos: readonly Argumento[] = [],
    ) {
      estado.llamadas.push(funcion);
      switch (funcion) {
        case "mercado_en_ventana":
          estado.intervalo = argumentos[0];
          return Promise.resolve(
            [{ mercado_en_ventana: opciones.enVentana ?? true }] as T[],
          );
        case "ahora":
          return Promise.resolve([{ ahora: AHORA }] as T[]);
        case "simbolos_del_universo":
          return Promise.resolve(
            UNIVERSO.map((simbolo) => ({ simbolo })) as T[],
          );
        case "publicar_cotizaciones": {
          const datos = argumentos[0] as unknown[];
          estado.lotes.push(datos);
          return Promise.resolve([
            {
              guardadas: datos.length,
              descartadas: 0,
              barras_minuto: 0,
              descartes: [],
            },
          ] as T[]);
        }
        default:
          return Promise.reject(new Error(`función inesperada: ${funcion}`));
      }
    },
    cerrar() {
      estado.cerrada = true;
      return Promise.resolve();
    },
  };
  return { bd, estado };
}

function proveedor(
  resultado: Cotizacion[] | Error,
): { mercado: ProveedorDeMercado; llamadas: string[][] } {
  const llamadas: string[][] = [];
  return {
    llamadas,
    mercado: {
      snapshots(simbolos) {
        llamadas.push([...simbolos]);
        return resultado instanceof Error
          ? Promise.reject(resultado)
          : Promise.resolve(resultado);
      },
      barras: () => Promise.resolve({ barras: [], descartadas: 0 }),
    },
  };
}

function manejadorCon(mercado: ProveedorDeMercado, bd: Bd) {
  return crearManejador({
    mercado,
    abrirBd: () => bd,
    fuente: "simulado",
    secreto: SECRETO,
  });
}

function post(cabeceras: Record<string, string> = {}): Request {
  return new Request("http://localhost/functions/v1/ingesta-mercado", {
    method: "POST",
    headers: cabeceras,
  });
}
const CON_SECRETO = { "x-secreto-interno": SECRETO };

Deno.test("CA-5: sin el secreto interno rechaza y no toca la base ni al proveedor", async () => {
  const { bd, estado } = bdFalsa();
  const { mercado, llamadas } = proveedor([]);
  const manejador = manejadorCon(mercado, bd);

  assertEquals((await manejador(post())).status, 401);
  assertEquals(
    (await manejador(post({ "x-secreto-interno": "otro" }))).status,
    403,
  );
  assertEquals(
    (await manejador(post({ Authorization: "Bearer cualquier.jwt.token" })))
      .status,
    401,
  );
  assertEquals(estado.llamadas, []);
  assertEquals(llamadas, []);
});

Deno.test("solo acepta POST", async () => {
  const { bd } = bdFalsa();
  const respuesta = await manejadorCon(proveedor([]).mercado, bd)(
    new Request("http://localhost/", { method: "GET", headers: CON_SECRETO }),
  );
  assertEquals(respuesta.status, 405);
});

Deno.test("CA-3: con el mercado cerrado no llama al proveedor", async () => {
  const { bd, estado } = bdFalsa({ enVentana: false });
  const { mercado, llamadas } = proveedor([cotizacion("QQQ", 400)]);

  const respuesta = await manejadorCon(mercado, bd)(post(CON_SECRETO));

  assertEquals(respuesta.status, 200);
  assertEquals(await respuesta.json(), { omitida: true });
  assertEquals(llamadas, []);
  assertEquals(estado.lotes, []);
  assertEquals(estado.intervalo, "10 minutes");
  assert(estado.cerrada);
});

Deno.test("CA-1: una sola llamada con todo el universo y un solo lote", async () => {
  const { bd, estado } = bdFalsa();
  const { mercado, llamadas } = proveedor(
    UNIVERSO.map((s) => cotizacion(s, 100)),
  );

  const respuesta = await manejadorCon(mercado, bd)(post(CON_SECRETO));
  const cuerpo = await respuesta.json();

  assertEquals(respuesta.status, 200);
  assertEquals(llamadas, [UNIVERSO]);
  assertEquals(estado.lotes.length, 1);
  assertEquals(estado.lotes[0].length, 3);
  assertEquals(
    (estado.lotes[0][0] as Record<string, unknown>).fuente,
    "simulado",
  );
  assertEquals(cuerpo.guardadas, 3);
  assertEquals(cuerpo.descartadas, 0);
  assert(estado.cerrada);
});

Deno.test("CA-2: precio nulo, no numérico o menor o igual a cero se descarta y los demás se guardan", async () => {
  const { bd, estado } = bdFalsa();
  const malas = [
    { ...cotizacion("AAPL", 1), precio: 0 },
    { ...cotizacion("QLD", 1), precio: null },
    { ...cotizacion("QQQ", 1), precio: "abc" },
    { ...cotizacion("MSFT", 1), precio: -3 },
    cotizacion("NVDA", 50),
  ] as unknown as Cotizacion[];
  const { mercado } = proveedor(malas);

  const respuesta = await manejadorCon(mercado, bd)(post(CON_SECRETO));
  const cuerpo = await respuesta.json();

  assertEquals(respuesta.status, 200);
  assertEquals(estado.lotes[0].map((d) => (d as { simbolo: string }).simbolo), [
    "NVDA",
  ]);
  const simbolos = cuerpo.descartes.map((d: { simbolo: string }) => d.simbolo);
  for (const s of ["AAPL", "QLD", "QQQ", "MSFT"]) {
    assert(simbolos.includes(s), s);
  }
});

Deno.test("un símbolo que el proveedor omite (sin precio válido) se registra como descartado", async () => {
  const { bd } = bdFalsa();
  const { mercado } = proveedor([cotizacion("QQQ", 400)]);

  const cuerpo = await (await manejadorCon(mercado, bd)(post(CON_SECRETO)))
    .json();

  assertEquals(
    cuerpo.descartes.map((
      d: { simbolo: string; motivo: string },
    ) => [d.simbolo, d.motivo]),
    [["AAPL", "SIN_PRECIO_VALIDO"], ["QLD", "SIN_PRECIO_VALIDO"]],
  );
});

Deno.test("CA-4: si el proveedor falla responde 502 y no escribe nada", async () => {
  const { bd, estado } = bdFalsa();
  const { mercado } = proveedor(
    new ErrorDeProveedor("Alpaca respondió 503", 503),
  );

  const respuesta = await manejadorCon(mercado, bd)(post(CON_SECRETO));
  const cuerpo = await respuesta.json();

  assertEquals(respuesta.status, 502);
  assertEquals(cuerpo.codigo, "INTEGRACION_CAIDA");
  assertEquals(estado.lotes, []);
  assert(estado.cerrada);
});

Deno.test("un fallo de la base responde 500 sin detalles y cierra la conexión", async () => {
  const bd: Bd = {
    llamar: () => Promise.reject(new Error("postgres://usuario:clave@host")),
    cerrar: () => Promise.resolve(),
  };
  const respuesta = await manejadorCon(proveedor([]).mercado, bd)(
    post(CON_SECRETO),
  );
  assertEquals(respuesta.status, 500);
  assertEquals(await respuesta.json(), { error: "interno" });
});

Deno.test("validarCotizaciones: separa válidas e inválidas", () => {
  const { validas, descartes } = validarCotizaciones([
    cotizacion("QQQ", 400),
    { ...cotizacion("QLD", 80), momento: "no es fecha" },
    null,
  ]);
  assertEquals(validas.map((c) => c.simbolo), ["QQQ"]);
  assertEquals(descartes.map((d) => d.simbolo), ["QLD", "?"]);
});

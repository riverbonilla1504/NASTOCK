import { assert, assertEquals } from "@std/assert";
import { type Argumento, type Bd, ErrorDeBd } from "../_shared/bd.ts";
import {
  ErrorDeProveedor,
  type ProveedorDeMercado,
} from "../_shared/mercado/interfaz.ts";
import { MercadoSimulado } from "../_shared/mercado/simulado.ts";
import { crearManejador } from "./manejador.ts";

const SECRETO = "secreto-de-prueba";
const AHORA = new Date("2026-11-05T15:00:00Z");

/** Base falsa: universo fijo, guarda lo que recibe. */
function bdFalsa(opciones: { falla?: Error; universo?: string[] } = {}) {
  const estado = { cerrada: false, guardadas: 0 };
  const bd: Bd = {
    llamar<T = Record<string, unknown>>(
      funcion: string,
      argumentos: readonly Argumento[] = [],
    ) {
      if (opciones.falla) return Promise.reject(opciones.falla);
      switch (funcion) {
        case "ahora":
          return Promise.resolve([{ ahora: AHORA }] as T[]);
        case "simbolos_sin_historia":
          return Promise.resolve(
            (opciones.universo ?? ["QQQ", "QLD"]).map((simbolo) => ({
              simbolo,
            })) as T[],
          );
        case "guardar_barras_diarias": {
          const barras = argumentos[0] as unknown[];
          estado.guardadas += barras.length;
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
  opciones: {
    mercado?: ProveedorDeMercado;
    bd?: Bd;
    secreto?: string;
    abrirBd?: () => Bd;
  } = {},
) {
  const aperturas = { cuantas: 0 };
  const manejador = crearManejador({
    mercado: opciones.mercado ?? new MercadoSimulado(),
    abrirBd: opciones.abrirBd ?? (() => {
      aperturas.cuantas++;
      return opciones.bd ?? bdFalsa().bd;
    }),
    secreto: opciones.secreto ?? SECRETO,
  });
  return { manejador, aperturas };
}

function post(
  cabeceras: Record<string, string> = {},
  cuerpo?: string,
): Request {
  return new Request("http://localhost/functions/v1/calendario-mercado", {
    method: "POST",
    headers: cabeceras,
    body: cuerpo,
  });
}

const CON_SECRETO = { "x-secreto-interno": SECRETO };

Deno.test("con el secreto interno correcto carga y responde 200 con el resumen", async () => {
  const { bd, estado } = bdFalsa();
  const { manejador } = manejadorCon({ bd });

  const respuesta = await manejador(post(CON_SECRETO));
  const cuerpo = await respuesta.json();

  assertEquals(respuesta.status, 200);
  assertEquals(respuesta.headers.get("content-type"), "application/json");
  assertEquals(cuerpo.desde, "2024-11-05");
  assertEquals(cuerpo.hasta, "2026-11-04");
  assertEquals(cuerpo.simbolos_consultados, 2);
  assertEquals(cuerpo.pendientes, []);
  assert(cuerpo.barras_nuevas > 1000);
  assertEquals(cuerpo.barras_nuevas, estado.guardadas);
  assertEquals(estado.cerrada, true);
});

Deno.test("el cuerpo de la petición se ignora", async () => {
  const { manejador } = manejadorCon();
  const respuesta = await manejador(post(CON_SECRETO, "esto no es json {"));
  assertEquals(respuesta.status, 200);
  await respuesta.body?.cancel();
});

Deno.test("un secreto incorrecto responde 403 y no abre la base", async () => {
  const { manejador, aperturas } = manejadorCon();
  const respuesta = await manejador(
    post({ "x-secreto-interno": "otro-secreto" }),
  );
  assertEquals(respuesta.status, 403);
  assertEquals(await respuesta.json(), { codigo: "NO_AUTORIZADO" });
  assertEquals(aperturas.cuantas, 0);
});

Deno.test("sin secreto configurado en la función, ningún secreto sirve", async () => {
  const { manejador, aperturas } = manejadorCon({ secreto: "" });
  const respuesta = await manejador(post({ "x-secreto-interno": "" }));
  assertEquals(respuesta.status, 403);
  await respuesta.body?.cancel();
  assertEquals(aperturas.cuantas, 0);
});

Deno.test("sin secreto ni sesión responde 401", async () => {
  const { manejador, aperturas } = manejadorCon();
  const respuesta = await manejador(post());
  assertEquals(respuesta.status, 401);
  assertEquals(await respuesta.json(), { codigo: "SESION_INVALIDA" });
  assertEquals(aperturas.cuantas, 0);
});

Deno.test("un JWT no sirve: esta función no acepta personas", async () => {
  const { manejador, aperturas } = manejadorCon();
  const respuesta = await manejador(
    post({ Authorization: "Bearer eyJhbGciOi.fake.token" }),
  );
  assertEquals(respuesta.status, 401);
  assertEquals(await respuesta.json(), { codigo: "SESION_INVALIDA" });
  assertEquals(aperturas.cuantas, 0);
});

Deno.test("otro método que POST responde 405", async () => {
  const { manejador, aperturas } = manejadorCon();
  for (const method of ["GET", "PUT", "DELETE", "PATCH"]) {
    const respuesta = await manejador(
      new Request("http://localhost/functions/v1/calendario-mercado", {
        method,
        headers: CON_SECRETO,
      }),
    );
    assertEquals(respuesta.status, 405, method);
    assertEquals(respuesta.headers.get("Allow"), "POST");
    await respuesta.body?.cancel();
  }
  assertEquals(aperturas.cuantas, 0);
});

Deno.test("si el proveedor falla responde 502 con lo ya hecho y cierra la base", async () => {
  const { bd, estado } = bdFalsa({ universo: ["QQQ", "QLD"] });
  const mercado: ProveedorDeMercado = {
    snapshots: () => Promise.resolve([]),
    barras: () =>
      Promise.reject(
        new ErrorDeProveedor("Alpaca respondió 429 en /v2/stocks/bars", 429),
      ),
  };
  const { manejador } = manejadorCon({ bd, mercado });

  const respuesta = await manejador(post(CON_SECRETO));
  const cuerpo = await respuesta.json();

  assertEquals(respuesta.status, 502);
  assertEquals(cuerpo.codigo, "INTEGRACION_CAIDA");
  assertEquals(cuerpo.detalle, "Alpaca respondió 429 en /v2/stocks/bars");
  assertEquals(cuerpo.pendientes, ["QQQ", "QLD"]);
  assertEquals(cuerpo.barras_nuevas, 0);
  assertEquals(estado.cerrada, true);
});

Deno.test("un fallo de la base responde 500 sin detalles y cierra la conexión", async () => {
  const { bd, estado } = bdFalsa({
    falla: new ErrorDeBd("private.ahora falló: algo interno"),
  });
  const { manejador } = manejadorCon({ bd });
  const respuesta = await manejador(post(CON_SECRETO));
  assertEquals(respuesta.status, 500);
  assertEquals(await respuesta.json(), { error: "interno" });
  assertEquals(estado.cerrada, true);
});

Deno.test("si no se puede abrir la base (falta SUPABASE_DB_URL) responde 500", async () => {
  const { manejador } = manejadorCon({
    abrirBd: () => {
      throw new ErrorDeBd("Falta SUPABASE_DB_URL");
    },
  });
  const respuesta = await manejador(post(CON_SECRETO));
  assertEquals(respuesta.status, 500);
  assertEquals(await respuesta.json(), { error: "interno" });
});

Deno.test("un error al cerrar la base no cambia la respuesta", async () => {
  const { bd } = bdFalsa();
  const { manejador } = manejadorCon({
    bd: { ...bd, cerrar: () => Promise.reject(new Error("no cierra")) },
  });
  const respuesta = await manejador(post(CON_SECRETO));
  assertEquals(respuesta.status, 200);
  await respuesta.body?.cancel();
});

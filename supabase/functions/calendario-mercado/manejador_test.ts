import { assert, assertEquals } from "@std/assert";
import { type Argumento, type Bd, ErrorDeBd } from "../_shared/bd.ts";
import type { Broker } from "../_shared/broker/interfaz.ts";
import { BrokerSimulado } from "../_shared/broker/simulado.ts";
import {
  ErrorDeProveedor,
  type ProveedorDeMercado,
} from "../_shared/mercado/interfaz.ts";
import { MercadoSimulado } from "../_shared/mercado/simulado.ts";
import { crearManejador } from "./manejador.ts";

const SECRETO = "secreto-de-prueba";
const AHORA = new Date("2026-11-05T15:00:00Z");

/** Base falsa: universo fijo, guarda lo que recibe. */
function bdFalsa(
  opciones: {
    falla?: Error;
    universo?: string[];
    /** Símbolos que `sincronizar_activos` dice haber desactivado. */
    desactivados?: string[];
    mercadoAbierto?: boolean;
  } = {},
) {
  const estado = {
    cerrada: false,
    guardadas: 0,
    calendario: [] as unknown[],
    activos: [] as unknown[],
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
        case "simbolos_sin_historia":
          return Promise.resolve(
            (opciones.universo ?? ["QQQ", "QLD"]).map((simbolo) => ({
              simbolo,
            })) as T[],
          );
        case "sincronizar_calendario": {
          const dias = argumentos[2] as unknown[];
          estado.calendario = dias;
          return Promise.resolve(
            [{ guardados: dias.length, eliminados: 1 }] as T[],
          );
        }
        case "mercado_abierto":
          return Promise.resolve(
            [{ mercado_abierto: opciones.mercadoAbierto ?? false }] as T[],
          );
        case "simbolos_del_universo":
          return Promise.resolve(
            (opciones.universo ?? ["QQQ", "QLD"]).map((simbolo) => ({
              simbolo,
            })) as T[],
          );
        case "sincronizar_activos": {
          const activos = argumentos[0] as { simbolo: string }[];
          estado.activos = activos;
          return Promise.resolve(
            activos.map((a) => ({
              bolsillo: "usuarios",
              simbolo: a.simbolo,
              desactivado: (opciones.desactivados ?? []).includes(a.simbolo),
            })) as T[],
          );
        }
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
    broker?: Broker;
    bd?: Bd;
    secreto?: string;
    abrirBd?: () => Bd;
    reloj?: () => number;
  } = {},
) {
  const aperturas = { cuantas: 0 };
  const manejador = crearManejador({
    mercado: opciones.mercado ?? new MercadoSimulado(),
    broker: opciones.broker ?? new BrokerSimulado(),
    reloj: opciones.reloj,
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

// HU-027: calendario, reloj y atributos de los activos --------------------------------------

Deno.test("200: sincroniza el calendario, contrasta el reloj y sincroniza los activos (CA-6, CA-7)", async () => {
  const { bd, estado } = bdFalsa({ mercadoAbierto: true });
  // siempre_abierto: el broker y la base (falsa) coinciden en que el mercado está abierto.
  const { manejador } = manejadorCon({
    bd,
    broker: new BrokerSimulado({ modo: "siempre_abierto" }),
  });

  const respuesta = await manejador(post(CON_SECRETO));
  const cuerpo = await respuesta.json();

  assertEquals(respuesta.status, 200);
  // Lo de HU-026 sigue en la raíz.
  assertEquals(cuerpo.simbolos_consultados, 2);
  // Calendario: de hoy (2026-11-05) a 60 días después, solo lunes a viernes.
  assertEquals(cuerpo.calendario.desde, "2026-11-05");
  assertEquals(cuerpo.calendario.hasta, "2027-01-04");
  assertEquals(cuerpo.calendario.dias_recibidos, estado.calendario.length);
  assertEquals(cuerpo.calendario.dias_guardados, estado.calendario.length);
  assertEquals(cuerpo.calendario.dias_eliminados, 1);
  assert(estado.calendario.length > 30);
  // Reloj.
  assertEquals(cuerpo.reloj, {
    abierto_broker: true,
    abierto_bd: true,
    coincide: true,
  });
  // Activos: los dos símbolos del universo, con sus atributos.
  assertEquals(cuerpo.activos, {
    consultados: 2,
    actualizados: 2,
    desactivados: [],
  });
  assertEquals(estado.activos, [
    { simbolo: "QQQ", negociable: true, fraccionable: true },
    { simbolo: "QLD", negociable: true, fraccionable: true },
  ]);
  assertEquals(estado.cerrada, true);
});

Deno.test("un símbolo que deja de ser negociable queda en `desactivados` (CA-5)", async () => {
  const { bd } = bdFalsa({ desactivados: ["QLD"] });
  const { manejador } = manejadorCon({
    bd,
    broker: new BrokerSimulado({ noNegociables: ["QLD"] }),
  });
  const cuerpo = await (await manejador(post(CON_SECRETO))).json();
  assertEquals(cuerpo.activos.desactivados, ["QLD"]);
});

Deno.test("si el reloj del broker y el calendario no coinciden lo informa y responde 200", async () => {
  const { bd } = bdFalsa({ mercadoAbierto: false });
  const { manejador } = manejadorCon({
    bd,
    broker: new BrokerSimulado({ modo: "siempre_abierto" }),
  });
  const respuesta = await manejador(post(CON_SECRETO));
  const cuerpo = await respuesta.json();
  assertEquals(respuesta.status, 200);
  assertEquals(cuerpo.reloj.coincide, false);
});

Deno.test("si el broker falla responde 502, pero la historia de barras igual se carga", async () => {
  const { bd, estado } = bdFalsa();
  const caido = (ruta: string) =>
    Promise.reject(
      new ErrorDeProveedor(`Alpaca respondió 503 en ${ruta}`, 503),
    );
  const broker: Broker = {
    calendario: () => caido("/v2/calendar"),
    reloj: () => caido("/v2/clock"),
    activos: () => caido("/v2/assets"),
  };
  const { manejador } = manejadorCon({ bd, broker });

  const respuesta = await manejador(post(CON_SECRETO));
  const cuerpo = await respuesta.json();

  assertEquals(respuesta.status, 502);
  assertEquals(cuerpo.codigo, "INTEGRACION_CAIDA");
  assertEquals(cuerpo.calendario, {
    error: "Alpaca respondió 503 en /v2/calendar",
  });
  assertEquals(cuerpo.reloj, { error: "Alpaca respondió 503 en /v2/clock" });
  assertEquals(cuerpo.activos, {
    error: "Alpaca respondió 503 en /v2/assets",
  });
  assert(cuerpo.detalle.includes("/v2/calendar"));
  // La historia se cargó aunque el broker cayó.
  assert(cuerpo.barras_nuevas > 1000);
  assertEquals(cuerpo.barras_nuevas, estado.guardadas);
  assertEquals(estado.cerrada, true);
});

Deno.test("si cae el mercado y el broker sigue, el calendario queda sincronizado", async () => {
  const { bd, estado } = bdFalsa();
  const mercado: ProveedorDeMercado = {
    snapshots: () => Promise.resolve([]),
    barras: () =>
      Promise.reject(new ErrorDeProveedor("Alpaca respondió 429", 429)),
  };
  const { manejador } = manejadorCon({ bd, mercado });
  const respuesta = await manejador(post(CON_SECRETO));
  const cuerpo = await respuesta.json();
  assertEquals(respuesta.status, 502);
  assert(cuerpo.calendario.dias_guardados > 30);
  assertEquals(cuerpo.calendario.dias_guardados, estado.calendario.length);
  assertEquals(cuerpo.activos.consultados, 2);
});

Deno.test("la historia de barras recibe lo que queda del presupuesto de tiempo", async () => {
  const { bd } = bdFalsa();
  // El reloj avanza 150 s en cada lectura: al llegar a la historia ya no queda presupuesto.
  let ahora = 0;
  const reloj = () => (ahora += 150_000);
  const { manejador } = manejadorCon({ bd, reloj });
  const cuerpo = await (await manejador(post(CON_SECRETO))).json();
  assertEquals(cuerpo.pendientes, ["QQQ", "QLD"]);
  assertEquals(cuerpo.barras_nuevas, 0);
});

Deno.test("un error que no es del proveedor en el calendario responde 500", async () => {
  const { bd } = bdFalsa();
  const roto = () => Promise.reject(new TypeError("falla interna"));
  const broker: Broker = { calendario: roto, reloj: roto, activos: roto };
  const { manejador } = manejadorCon({ bd, broker });
  const respuesta = await manejador(post(CON_SECRETO));
  assertEquals(respuesta.status, 500);
  assertEquals(await respuesta.json(), { error: "interno" });
});

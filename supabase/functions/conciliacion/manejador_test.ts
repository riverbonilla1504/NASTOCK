import { assert, assertEquals } from "@std/assert";
import { type Argumento, type Bd, ErrorDeBd } from "../_shared/bd.ts";
import type { Broker } from "../_shared/broker/interfaz.ts";
import { BrokerSimulado } from "../_shared/broker/simulado.ts";
import { ErrorDeProveedor } from "../_shared/mercado/interfaz.ts";
import { crearManejador } from "./manejador.ts";

const SECRETO = "secreto-de-prueba";
const CON_SECRETO = { "x-secreto-interno": SECRETO };

function post(cabeceras: Record<string, string> = {}): Request {
  return new Request("http://localhost/conciliacion", {
    method: "POST",
    headers: cabeceras,
  });
}

/** Base falsa: guarda las llamadas y devuelve una conciliación fija. */
function bdFalsa(opciones: { falla?: Error } = {}) {
  const estado = {
    cerrada: false,
    llamadas: [] as { funcion: string; argumentos: readonly Argumento[] }[],
  };
  const bd: Bd = {
    llamar<T = Record<string, unknown>>(
      funcion: string,
      argumentos: readonly Argumento[] = [],
    ) {
      estado.llamadas.push({ funcion, argumentos });
      if (opciones.falla) return Promise.reject(opciones.falla);
      return Promise.resolve([
        { id: "c1", resultado: "ok", accion_tomada: "aporte_confirmado" },
      ] as T[]);
    },
    cerrar() {
      estado.cerrada = true;
      return Promise.resolve();
    },
  };
  return { bd, estado };
}

/** Un broker cuya cuenta falla con el error dado; lo demás no se usa. */
function brokerConCuenta(cuenta: () => Promise<never>): Broker {
  const no = () => Promise.reject(new Error("no se usa"));
  return {
    calendario: no,
    reloj: no,
    activos: no,
    cuenta,
    enviarOrden: no,
    consultarOrden: no,
    cancelarOrden: no,
    posiciones: no,
  };
}

function manejadorCon(
  bd: Bd,
  broker: Broker = new BrokerSimulado({ efectivo: 10_000 }),
  abrio?: { valor: boolean },
) {
  return crearManejador({
    broker,
    secreto: SECRETO,
    abrirBd: () => {
      if (abrio) abrio.valor = true;
      return bd;
    },
  });
}

Deno.test("solo acepta POST", async () => {
  const { bd } = bdFalsa();
  const respuesta = await manejadorCon(bd)(
    new Request("http://localhost/conciliacion", { method: "GET" }),
  );
  assertEquals(respuesta.status, 405);
});

Deno.test("sin secreto responde 401 y con secreto incorrecto 403, sin tocar la base", async () => {
  const { bd, estado } = bdFalsa();
  const manejador = manejadorCon(bd);
  assertEquals((await manejador(post())).status, 401);
  assertEquals(
    (await manejador(post({ "x-secreto-interno": "otro" }))).status,
    403,
  );
  assertEquals(estado.llamadas.length, 0);
});

Deno.test("un JWT no basta: la función no acepta personas", async () => {
  const { bd } = bdFalsa();
  const respuesta = await manejadorCon(bd)(
    post({ Authorization: "Bearer abc" }),
  );
  assertEquals(respuesta.status, 401);
});

Deno.test("lee el efectivo del broker y se lo entrega a registrar_conciliacion", async () => {
  const { bd, estado } = bdFalsa();
  const respuesta = await manejadorCon(bd)(post(CON_SECRETO));
  assertEquals(respuesta.status, 200);
  assertEquals((await respuesta.json()).conciliacion.resultado, "ok");
  // La salud del broker se registra antes de conciliar (HU-035).
  assertEquals(estado.llamadas, [
    {
      funcion: "registrar_salud",
      argumentos: ["alpaca_trading", true, null],
    },
    { funcion: "registrar_conciliacion", argumentos: [10_000] },
  ]);
  assert(estado.cerrada, "cierra la conexión");
});

Deno.test("si el broker falla responde 502, no concilia y registra su salud (HU-035)", async () => {
  const { bd, estado } = bdFalsa();
  const abrio = { valor: false };
  const caido = brokerConCuenta(() =>
    Promise.reject(
      new ErrorDeProveedor("Alpaca respondió 503 en /v2/account", 503),
    )
  );
  const respuesta = await manejadorCon(bd, caido, abrio)(post(CON_SECRETO));
  const cuerpo = await respuesta.json();
  assertEquals(respuesta.status, 502);
  assertEquals(cuerpo.codigo, "INTEGRACION_CAIDA");
  // Solo se abre la base para anotar el fallo: no se llama a registrar_conciliacion.
  assertEquals(abrio.valor, true);
  assertEquals(estado.llamadas.map((l) => l.funcion), ["registrar_salud"]);
  assertEquals(estado.llamadas[0].argumentos.slice(0, 2), [
    "alpaca_trading",
    false,
  ]);
  assert(estado.cerrada, "cierra la conexión");
});

Deno.test("un fallo de la base responde 500 sin detalles y cierra la conexión", async () => {
  const { bd, estado } = bdFalsa({ falla: new ErrorDeBd("falló") });
  const respuesta = await manejadorCon(bd)(post(CON_SECRETO));
  assertEquals(respuesta.status, 500);
  assertEquals(await respuesta.json(), { error: "interno" });
  assert(estado.cerrada);
});

Deno.test("un error que no es del proveedor al leer la cuenta responde 500", async () => {
  const { bd } = bdFalsa();
  const roto = brokerConCuenta(() => Promise.reject(new TypeError("interno")));
  const respuesta = await manejadorCon(bd, roto)(post(CON_SECRETO));
  assertEquals(respuesta.status, 500);
  assertEquals(await respuesta.json(), { error: "interno" });
});

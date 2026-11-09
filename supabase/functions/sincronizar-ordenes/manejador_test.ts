import { assert, assertEquals } from "@std/assert";
import { type Argumento, type Bd } from "../_shared/bd.ts";
import type { Broker, OrdenAEnviar } from "../_shared/broker/mod.ts";
import { BrokerSimulado } from "../_shared/broker/simulado.ts";
import { ErrorDeProveedor } from "../_shared/mercado/interfaz.ts";
import { crearManejador } from "./manejador.ts";

const SECRETO = "secreto-de-prueba";
const CON_SECRETO = { "x-secreto-interno": SECRETO };
const ORDEN = "11111111-1111-4111-8111-111111111111";

const COMPRA: OrdenAEnviar = {
  idCliente: ORDEN,
  simbolo: "QLD",
  lado: "compra",
  cantidad: 4,
  precioLimite: 100,
  proteccion: { stopLoss: 92, objetivo: 110 },
};

function post(cabeceras: Record<string, string> = {}): Request {
  return new Request("http://localhost/sincronizar-ordenes", {
    method: "POST",
    headers: cabeceras,
  });
}

interface Llamada {
  funcion: string;
  argumentos: readonly Argumento[];
}

interface Datos {
  vivas?: Record<string, unknown>[];
  porCancelar?: Record<string, unknown>[];
  /** Funciones que fallan con este error. */
  fallan?: Record<string, Error>;
}

function bdFalsa(datos: Datos = {}) {
  const llamadas: Llamada[] = [];
  const estado = { cerrada: false };
  const bd: Bd = {
    llamar<T = Record<string, unknown>>(
      funcion: string,
      argumentos: readonly Argumento[] = [],
    ) {
      llamadas.push({ funcion, argumentos });
      const falla = datos.fallan?.[funcion];
      if (falla) return Promise.reject(falla);
      if (funcion === "ordenes_para_sincronizar") {
        return Promise.resolve((datos.vivas ?? []) as T[]);
      }
      if (funcion === "ordenes_por_cancelar_por_tiempo") {
        return Promise.resolve((datos.porCancelar ?? []) as T[]);
      }
      return Promise.resolve([] as T[]);
    },
    cerrar() {
      estado.cerrada = true;
      return Promise.resolve();
    },
  };
  return { bd, llamadas, estado };
}

async function pasada(bd: Bd, broker: Broker) {
  const manejador = crearManejador({
    broker,
    secreto: SECRETO,
    abrirBd: () => bd,
  });
  const respuesta = await manejador(post(CON_SECRETO));
  assertEquals(respuesta.status, 200);
  return await respuesta.json();
}

const funciones = (l: Llamada[]) => l.map((x) => x.funcion);
const buscar = (l: Llamada[], f: string) => l.find((x) => x.funcion === f);

/** Un broker donde la orden ya existe y se llenó con `llenar` (precio del mercado). */
async function brokerConOrden(llenar?: number) {
  const broker = new BrokerSimulado();
  const orden = await broker.enviarOrden(COMPRA);
  if (llenar !== undefined) broker.avanzar({ QLD: llenar });
  return { broker, orden };
}

function viva(
  idBroker: string | null,
  estado = "aceptada",
): Record<string, unknown> {
  return { orden_id: ORDEN, broker_order_id: idBroker, estado };
}

Deno.test("sin el secreto interno la función rechaza y no toca la base", async () => {
  const { bd, llamadas } = bdFalsa();
  const manejador = crearManejador({
    broker: new BrokerSimulado(),
    secreto: SECRETO,
    abrirBd: () => bd,
  });
  assertEquals((await manejador(post())).status, 401);
  assertEquals(
    (await manejador(post({ "x-secreto-interno": "otro" }))).status,
    403,
  );
  assertEquals(
    (await manejador(post({ authorization: "Bearer jwt" }))).status,
    401,
  );
  assertEquals(
    (await manejador(new Request("http://localhost/", { method: "GET" })))
      .status,
    405,
  );
  assertEquals(llamadas.length, 0);
});

Deno.test("CA-1: un llenado del broker se entrega a aplicar_llenado con el estado crudo", async () => {
  const { broker, orden } = await brokerConOrden(99);
  const { bd, llamadas, estado } = bdFalsa({ vivas: [viva(orden.idBroker)] });
  const cuerpo = await pasada(bd, broker);

  assertEquals(cuerpo.ordenes, [{
    orden_id: ORDEN,
    resultado: "sincronizada",
  }]);
  assertEquals(buscar(llamadas, "aplicar_llenado")?.argumentos, [
    ORDEN,
    4,
    99,
    "filled",
    0,
  ]);
  assertEquals(buscar(llamadas, "registrar_salud")?.argumentos, [
    "alpaca_trading",
    true,
    null,
  ]);
  assertEquals(estado.cerrada, true);
});

Deno.test("una orden sin llenar se entrega con cantidad 0 y precio nulo", async () => {
  const { broker, orden } = await brokerConOrden();
  const { bd, llamadas } = bdFalsa({ vivas: [viva(orden.idBroker)] });
  await pasada(bd, broker);
  assertEquals(buscar(llamadas, "aplicar_llenado")?.argumentos, [
    ORDEN,
    0,
    null,
    "new",
    0,
  ]);
});

Deno.test("CA-5/CB-34: una cancelación con llenado parcial se entrega con lo llenado", async () => {
  const broker = new BrokerSimulado({ escenario: "llenado_parcial" });
  const orden = await broker.enviarOrden(COMPRA);
  broker.avanzar({ QLD: 99 });
  await broker.cancelarOrden(orden.idBroker);
  const { bd, llamadas } = bdFalsa({ vivas: [viva(orden.idBroker)] });
  await pasada(bd, broker);
  assertEquals(buscar(llamadas, "aplicar_llenado")?.argumentos, [
    ORDEN,
    2,
    99,
    "canceled",
    0,
  ]);
});

Deno.test("CA-4/CB-35: las compras que superan el tiempo máximo se cancelan en el broker", async () => {
  const { broker, orden } = await brokerConOrden();
  const { bd, llamadas } = bdFalsa({
    porCancelar: [{ orden_id: ORDEN, broker_order_id: orden.idBroker }],
    vivas: [viva(orden.idBroker)],
  });
  const cuerpo = await pasada(bd, broker);
  assertEquals(cuerpo.canceladas, [{
    orden_id: ORDEN,
    resultado: "cancelada",
  }]);
  // Se cancela primero y luego se sincroniza: el estado final llega en la misma pasada.
  assertEquals(buscar(llamadas, "aplicar_llenado")?.argumentos.slice(3, 4), [
    "canceled",
  ]);
  assertEquals(
    (await broker.consultarOrden({ idBroker: orden.idBroker }))?.estado,
    "cancelada",
  );
});

Deno.test("CB-33: una orden desconocida se busca por client_order_id y queda aceptada", async () => {
  const { broker, orden } = await brokerConOrden();
  const { bd, llamadas } = bdFalsa({ vivas: [viva(null, "desconocida")] });
  const cuerpo = await pasada(bd, broker);
  assertEquals(cuerpo.ordenes[0].resultado, "sincronizada");
  assertEquals(funciones(llamadas).slice(2, 4), [
    "registrar_respuesta_envio",
    "aplicar_llenado",
  ]);
  assertEquals(
    buscar(llamadas, "registrar_respuesta_envio")?.argumentos.slice(0, 3),
    [
      ORDEN,
      orden.idBroker,
      "aceptada",
    ],
  );
});

Deno.test("si el broker no conoce la orden no se aplica nada", async () => {
  const { bd, llamadas } = bdFalsa({ vivas: [viva("no-existe")] });
  const cuerpo = await pasada(bd, new BrokerSimulado());
  assertEquals(cuerpo.ordenes, [{
    orden_id: ORDEN,
    resultado: "no_encontrada",
  }]);
  assert(!funciones(llamadas).includes("aplicar_llenado"));
  // Que no la conozca es una respuesta: el broker está arriba.
  assertEquals(buscar(llamadas, "registrar_salud")?.argumentos, [
    "alpaca_trading",
    true,
    null,
  ]);
});

function brokerQueFalla(): Broker {
  const cae = () => Promise.reject(new ErrorDeProveedor("caído", 503));
  const no = () => Promise.reject(new Error("no se usa"));
  return {
    calendario: no,
    reloj: no,
    activos: no,
    cuenta: no,
    enviarOrden: no,
    posiciones: no,
    consultarOrden: cae,
    cancelarOrden: cae,
  } as Broker;
}

Deno.test("si el broker cae se registra la salud, se corta la pasada y responde 200", async () => {
  const { bd, llamadas } = bdFalsa({
    vivas: [viva("b1"), { ...viva("b2"), orden_id: "otra" }],
  });
  const cuerpo = await pasada(bd, brokerQueFalla());
  assertEquals(cuerpo.ordenes, []);
  assertEquals(buscar(llamadas, "registrar_salud")?.argumentos.slice(0, 2), [
    "alpaca_trading",
    false,
  ]);
  assertEquals(
    llamadas.filter((l) => l.funcion === "registrar_salud").length,
    1,
  );
  assert(!funciones(llamadas).includes("aplicar_llenado"));
});

Deno.test("si cancelar falla porque el broker cae no se sincroniza en esa pasada", async () => {
  const { bd, llamadas } = bdFalsa({
    porCancelar: [{ orden_id: ORDEN, broker_order_id: "b1" }],
    vivas: [viva("b1")],
  });
  await pasada(bd, brokerQueFalla());
  assert(!funciones(llamadas).includes("ordenes_para_sincronizar"));
});

Deno.test("un fallo de base con una orden no frena a las demás", async () => {
  const { broker, orden } = await brokerConOrden(99);
  const { bd } = bdFalsa({
    vivas: [viva(orden.idBroker), {
      ...viva(orden.idBroker),
      orden_id: "otra",
    }],
    fallan: { aplicar_llenado: new Error("se cayó la base") },
  });
  const cuerpo = await pasada(bd, broker);
  assertEquals(cuerpo.ordenes.map((o: { resultado: string }) => o.resultado), [
    "error",
    "error",
  ]);
});

Deno.test("si la base falla al listar responde 500 sin detalles y cierra la conexión", async () => {
  const { bd, estado } = bdFalsa({
    fallan: {
      ordenes_por_cancelar_por_tiempo: new Error("postgres://u:c@h/db"),
    },
  });
  const manejador = crearManejador({
    broker: new BrokerSimulado(),
    secreto: SECRETO,
    abrirBd: () => bd,
  });
  const respuesta = await manejador(post(CON_SECRETO));
  assertEquals(respuesta.status, 500);
  assertEquals(await respuesta.json(), { error: "interno" });
  assertEquals(estado.cerrada, true);
});

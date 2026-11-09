import { assert, assertEquals } from "@std/assert";
import { type Argumento, type Bd } from "../_shared/bd.ts";
import type { Broker } from "../_shared/broker/mod.ts";
import {
  BrokerSimulado,
  type EscenarioDeOrden,
} from "../_shared/broker/simulado.ts";
import { ErrorDeProveedor } from "../_shared/mercado/interfaz.ts";
import { crearManejador } from "./manejador.ts";

const SECRETO = "secreto-de-prueba";
const CON_SECRETO = { "x-secreto-interno": SECRETO };
const ORDEN = "11111111-1111-4111-8111-111111111111";

function post(cabeceras: Record<string, string> = {}): Request {
  return new Request("http://localhost/ejecutor-ordenes", {
    method: "POST",
    headers: cabeceras,
  });
}

interface Llamada {
  funcion: string;
  argumentos: readonly Argumento[];
}

type DatosDeToma = {
  resultado: "enviar" | "consultar" | "fallida" | "ya_resuelta";
  reglas?: string[];
  orden?: Record<string, unknown>;
};

const DATOS = {
  id: ORDEN,
  estado: "creada",
  simbolo: "QLD",
  lado: "compra",
  clase: "bracket",
  cantidad: 4,
  precio_limite: 100,
  bracket_stop_precio: 92,
  bracket_objetivo_precio: 110,
};

/** Base falsa: guarda las llamadas; `tomar_orden_para_envio` responde según `tomas` (por id de orden). */
function bdFalsa(
  tomas: Record<string, DatosDeToma | Error>,
  mensajes: string[] = [ORDEN],
) {
  const llamadas: Llamada[] = [];
  const estado = { cerrada: false };
  const bd: Bd = {
    llamar<T = Record<string, unknown>>(
      funcion: string,
      argumentos: readonly Argumento[] = [],
    ) {
      llamadas.push({ funcion, argumentos });
      if (funcion === "leer_ordenes_por_enviar") {
        return Promise.resolve(
          mensajes.map((orden_id, i) => ({
            mensaje_id: i + 1,
            orden_id,
            lecturas: 1,
          })) as T[],
        );
      }
      if (funcion === "tomar_orden_para_envio") {
        const toma = tomas[String(argumentos[0])];
        if (toma instanceof Error) return Promise.reject(toma);
        return Promise.resolve([{ tomar_orden_para_envio: toma }] as T[]);
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

function manejadorCon(bd: Bd, broker: Broker) {
  return crearManejador({ broker, secreto: SECRETO, abrirBd: () => bd });
}

async function pasada(
  bd: Bd,
  broker: Broker,
): Promise<{ orden_id: string; resultado: string }[]> {
  const respuesta = await manejadorCon(bd, broker)(post(CON_SECRETO));
  assertEquals(respuesta.status, 200);
  return (await respuesta.json()).ordenes;
}

function funciones(llamadas: Llamada[]): string[] {
  return llamadas.map((l) => l.funcion);
}

function llamada(llamadas: Llamada[], funcion: string): Llamada | undefined {
  return llamadas.find((l) => l.funcion === funcion);
}

const ENVIAR: DatosDeToma = { resultado: "enviar", orden: DATOS };

// Autenticación (CA-7) ---------------------------------------------------------------------

Deno.test("CA-7: sin el secreto interno la función rechaza y no toca la base", async () => {
  const { bd, llamadas } = bdFalsa({});
  const manejador = manejadorCon(bd, new BrokerSimulado());
  assertEquals((await manejador(post())).status, 401);
  assertEquals(
    (await manejador(post({ "x-secreto-interno": "otro" }))).status,
    403,
  );
  assertEquals(
    (await manejador(post({ authorization: "Bearer jwt-de-persona" }))).status,
    401,
  );
  assertEquals(
    (await manejador(new Request("http://localhost/", { method: "GET" })))
      .status,
    405,
  );
  assertEquals(llamadas.length, 0);
});

// Camino feliz (CA-1) ------------------------------------------------------------------------

Deno.test("CA-1: toma, envía con client_order_id igual al id, cierra y confirma el mensaje", async () => {
  const broker = new BrokerSimulado();
  const { bd, llamadas, estado } = bdFalsa({ [ORDEN]: ENVIAR });
  const ordenes = await pasada(bd, broker);

  assertEquals(ordenes, [{ orden_id: ORDEN, resultado: "aceptada" }]);
  assertEquals(funciones(llamadas), [
    "leer_ordenes_por_enviar",
    "tomar_orden_para_envio",
    "registrar_salud",
    "registrar_respuesta_envio",
    "confirmar_orden_por_enviar",
  ]);
  const enviada = await broker.consultarOrden({ idCliente: ORDEN });
  assertEquals(enviada?.simbolo, "QLD");
  assertEquals(enviada?.cantidad, 4);
  assertEquals(enviada?.precioLimite, 100);
  assertEquals(enviada?.patas.map((p) => [p.tipo, p.precio]), [
    ["stop_loss", 92],
    ["objetivo", 110],
  ]);
  const respuesta = llamada(llamadas, "registrar_respuesta_envio")!;
  assertEquals(respuesta.argumentos.slice(0, 4), [
    ORDEN,
    enviada?.idBroker ?? null,
    "aceptada",
    "new",
  ]);
  assertEquals(llamada(llamadas, "registrar_salud")?.argumentos, [
    "alpaca_trading",
    true,
    null,
  ]);
  assertEquals(estado.cerrada, true);
});

Deno.test("la venta se envía como orden simple, sin patas", async () => {
  const broker = new BrokerSimulado();
  const venta = {
    ...DATOS,
    lado: "venta",
    clase: "simple",
    bracket_stop_precio: null,
    bracket_objetivo_precio: null,
  };
  const { bd } = bdFalsa({ [ORDEN]: { resultado: "enviar", orden: venta } });
  await pasada(bd, broker);
  const enviada = await broker.consultarOrden({ idCliente: ORDEN });
  assertEquals([enviada?.lado, enviada?.patas], ["venta", []]);
});

// Revalidación (CA-4) ------------------------------------------------------------------------

Deno.test("CA-4: si la revalidación falla no se llama al broker y se confirma el mensaje", async () => {
  const broker = new BrokerSimulado();
  const { bd, llamadas } = bdFalsa({
    [ORDEN]: { resultado: "fallida", reglas: ["RR-07"] },
  });
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "fallida_en_revalidacion" },
  ]);
  assertEquals(await broker.consultarOrden({ idCliente: ORDEN }), null);
  assertEquals(funciones(llamadas), [
    "leer_ordenes_por_enviar",
    "tomar_orden_para_envio",
    "confirmar_orden_por_enviar",
  ]);
});

Deno.test("una orden ya resuelta solo confirma el mensaje", async () => {
  const { bd, llamadas } = bdFalsa({ [ORDEN]: { resultado: "ya_resuelta" } });
  assertEquals(await pasada(bd, new BrokerSimulado()), [
    { orden_id: ORDEN, resultado: "ya_resuelta" },
  ]);
  assertEquals(funciones(llamadas).at(-1), "confirmar_orden_por_enviar");
});

// Errores del broker (CA-3, CA-5) ------------------------------------------------------------

Deno.test("CA-5 · CB-36: rechazo por fondos → rechazada con FONDOS_INSUFICIENTES", async () => {
  const broker = new BrokerSimulado({
    escenario: "rechazo" satisfies EscenarioDeOrden,
  });
  const { bd, llamadas } = bdFalsa({ [ORDEN]: ENVIAR });
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "rechazada" },
  ]);
  const error = llamada(llamadas, "registrar_error_envio")!;
  assertEquals(error.argumentos.slice(0, 3), [
    ORDEN,
    "rechazada",
    "FONDOS_INSUFICIENTES",
  ]);
  assertEquals(funciones(llamadas).at(-1), "confirmar_orden_por_enviar");
});

Deno.test("CA-3 · CB-33: sin respuesta → desconocida, se consulta por client_order_id y sigue como aceptada", async () => {
  // El simulado registra la orden y falla como si no hubiera respondido.
  const broker = new BrokerSimulado({ escenario: "sin_respuesta" });
  const { bd, llamadas } = bdFalsa({ [ORDEN]: ENVIAR });
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "aceptada" },
  ]);
  assertEquals(funciones(llamadas), [
    "leer_ordenes_por_enviar",
    "tomar_orden_para_envio",
    "registrar_salud",
    "registrar_error_envio",
    "registrar_respuesta_envio",
    "confirmar_orden_por_enviar",
  ]);
  assertEquals(llamada(llamadas, "registrar_salud")?.argumentos[1], false);
  assertEquals(
    llamada(llamadas, "registrar_error_envio")?.argumentos.slice(1, 3),
    [
      "desconocida",
      "SIN_RESPUESTA",
    ],
  );
});

/** Un broker cuyo envío y consulta se programan; lo demás no se usa. */
function brokerGuionado(
  enviar: () => Promise<never>,
  consultar: () => Promise<null>,
): Broker {
  const no = () => Promise.reject(new Error("no se usa"));
  return {
    calendario: no,
    reloj: no,
    activos: no,
    cuenta: no,
    posiciones: no,
    cancelarOrden: no,
    enviarOrden: enviar,
    consultarOrden: consultar,
  } as Broker;
}

Deno.test("CB-33: sin respuesta y el broker no la tiene → error_envio sin duplicar", async () => {
  const { bd, llamadas } = bdFalsa({ [ORDEN]: ENVIAR });
  const broker = brokerGuionado(
    () => Promise.reject(new ErrorDeProveedor("Alpaca no respondió a tiempo")),
    () => Promise.resolve(null),
  );
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "error_envio" },
  ]);
  const errores = llamadas.filter((l) => l.funcion === "registrar_error_envio");
  assertEquals(errores.map((l) => l.argumentos[1]), [
    "desconocida",
    "error_envio",
  ]);
  assertEquals(errores[1].argumentos[2], "NO_EXISTE_EN_BROKER");
});

Deno.test("sin respuesta y la consulta también falla → queda desconocida y el mensaje reaparece", async () => {
  const { bd, llamadas } = bdFalsa({ [ORDEN]: ENVIAR });
  const broker = brokerGuionado(
    () => Promise.reject(new ErrorDeProveedor("caído", 503)),
    () => Promise.reject(new ErrorDeProveedor("caído", 503)) as Promise<null>,
  );
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "desconocida" },
  ]);
  assert(!funciones(llamadas).includes("confirmar_orden_por_enviar"));
});

Deno.test("429: no se confirma el mensaje ni se marca error; reaparece para reintentar", async () => {
  const { bd, llamadas } = bdFalsa({ [ORDEN]: ENVIAR });
  const broker = brokerGuionado(
    () => Promise.reject(new ErrorDeProveedor("límite", 429)),
    () => Promise.resolve(null),
  );
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "pendiente" },
  ]);
  assert(!funciones(llamadas).includes("registrar_error_envio"));
  assert(!funciones(llamadas).includes("confirmar_orden_por_enviar"));
});

Deno.test("422: parámetros inválidos → error_envio con PARAMETROS_INVALIDOS", async () => {
  const broker = new BrokerSimulado({ noNegociables: ["QLD"] });
  const { bd, llamadas } = bdFalsa({ [ORDEN]: ENVIAR });
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "error_envio" },
  ]);
  assertEquals(
    llamada(llamadas, "registrar_error_envio")?.argumentos.slice(1, 3),
    ["error_envio", "PARAMETROS_INVALIDOS"],
  );
});

Deno.test("una orden fuera del alcance del MVP (fraccional) → error_envio y el broker no la recibe", async () => {
  const broker = new BrokerSimulado();
  const fraccional = { ...DATOS, cantidad: 1.5 };
  const { bd, llamadas } = bdFalsa({
    [ORDEN]: { resultado: "enviar", orden: fraccional },
  });
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "error_envio" },
  ]);
  assertEquals(
    llamada(llamadas, "registrar_error_envio")?.argumentos[2],
    "ORDEN_NO_SOPORTADA",
  );
  assertEquals(await broker.consultarOrden({ idCliente: ORDEN }), null);
});

// Reintentos: la orden ya se envió antes (CB-33) ------------------------------------------------

Deno.test("consultar: si el broker ya la tiene, la acepta sin enviarla otra vez", async () => {
  const broker = new BrokerSimulado();
  const previa = await broker.enviarOrden({
    idCliente: ORDEN,
    simbolo: "QLD",
    lado: "compra",
    cantidad: 4,
    precioLimite: 100,
    proteccion: { stopLoss: 92, objetivo: 110 },
  });
  const { bd, llamadas } = bdFalsa({
    [ORDEN]: {
      resultado: "consultar",
      orden: { ...DATOS, estado: "desconocida" },
    },
  });
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "aceptada" },
  ]);
  assertEquals(
    llamada(llamadas, "registrar_respuesta_envio")?.argumentos[1],
    previa.idBroker,
  );
});

Deno.test("consultar: desconocida que el broker no tiene → error_envio", async () => {
  const { bd, llamadas } = bdFalsa({
    [ORDEN]: {
      resultado: "consultar",
      orden: { ...DATOS, estado: "desconocida" },
    },
  });
  assertEquals(await pasada(bd, new BrokerSimulado()), [
    { orden_id: ORDEN, resultado: "error_envio" },
  ]);
  assertEquals(
    llamada(llamadas, "registrar_error_envio")?.argumentos.slice(1, 3),
    ["error_envio", "NO_EXISTE_EN_BROKER"],
  );
});

Deno.test("consultar: enviada que el broker no tiene (envío que no llegó) → se envía", async () => {
  const broker = new BrokerSimulado();
  const { bd } = bdFalsa({
    [ORDEN]: { resultado: "consultar", orden: { ...DATOS, estado: "enviada" } },
  });
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "aceptada" },
  ]);
  assertEquals(
    (await broker.consultarOrden({ idCliente: ORDEN }))?.estado,
    "aceptada",
  );
});

Deno.test("consultar: si el broker no responde, la orden queda pendiente y se registra el fallo", async () => {
  const { bd, llamadas } = bdFalsa({
    [ORDEN]: {
      resultado: "consultar",
      orden: { ...DATOS, estado: "desconocida" },
    },
  });
  const broker = brokerGuionado(
    () => Promise.reject(new Error("no debe llamarse")),
    () => Promise.reject(new ErrorDeProveedor("caído", 503)) as Promise<null>,
  );
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "pendiente" },
  ]);
  assertEquals(llamada(llamadas, "registrar_salud")?.argumentos[1], false);
});

// Aislamiento entre órdenes ---------------------------------------------------------------------

Deno.test("una orden con un fallo de base no frena a las demás (CB-67, CB-68)", async () => {
  const otra = "22222222-2222-4222-8222-222222222222";
  const broker = new BrokerSimulado();
  const { bd } = bdFalsa(
    {
      [ORDEN]: new Error("se cayó la base"),
      [otra]: { resultado: "enviar", orden: { ...DATOS, id: otra } },
    },
    [ORDEN, otra],
  );
  assertEquals(await pasada(bd, broker), [
    { orden_id: ORDEN, resultado: "pendiente" },
    { orden_id: otra, resultado: "aceptada" },
  ]);
});

Deno.test("si la base falla al leer la cola responde 500 sin detalles y cierra la conexión", async () => {
  const estado = { cerrada: false };
  const bd: Bd = {
    llamar: () => Promise.reject(new Error("postgres://usuario:clave@host/db")),
    cerrar: () => {
      estado.cerrada = true;
      return Promise.resolve();
    },
  };
  const respuesta = await manejadorCon(bd, new BrokerSimulado())(
    post(CON_SECRETO),
  );
  assertEquals(respuesta.status, 500);
  assertEquals(await respuesta.json(), { error: "interno" });
  assertEquals(estado.cerrada, true);
});

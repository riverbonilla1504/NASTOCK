// Pruebas de las órdenes del broker real (HU-072) con respuestas "grabadas" (fixtures/): escritas
// a mano con la forma documentada de la API de órdenes de Alpaca, sin llaves reales. La prueba
// real semanal contra Alpaca paper (docs/15 §6) las contrasta con la API de verdad.

import { assert, assertEquals, assertRejects } from "@std/assert";
import { ErrorDeProveedor } from "../mercado/interfaz.ts";
import { BrokerAlpaca } from "./alpaca.ts";
import {
  envioIncierto,
  type OrdenAEnviar,
  OrdenInvalida,
  OrdenRechazada,
} from "./interfaz.ts";

const KEY_ID = "CLAVE-ID-QUE-NO-DEBE-FILTRARSE";
const SECRET = "CLAVE-SECRETA-QUE-NO-DEBE-FILTRARSE";

async function fixture(nombre: string): Promise<unknown> {
  const texto = await Deno.readTextFile(
    new URL(`./fixtures/${nombre}`, import.meta.url),
  );
  return JSON.parse(texto);
}

interface Solicitud {
  metodo: string;
  url: URL;
  headers: Headers;
  cuerpo: Record<string, unknown> | null;
}

function crear(responder: (s: Solicitud) => Response | Error) {
  const solicitudes: Solicitud[] = [];
  const fn = ((entrada: RequestInfo | URL, init?: RequestInit) => {
    const s: Solicitud = {
      metodo: init?.method ?? "GET",
      url: new URL(entrada.toString()),
      headers: new Headers(init?.headers),
      cuerpo: typeof init?.body === "string" ? JSON.parse(init.body) : null,
    };
    solicitudes.push(s);
    const r = responder(s);
    return r instanceof Error ? Promise.reject(r) : Promise.resolve(r);
  }) as typeof fetch;
  const broker = new BrokerAlpaca({
    urlTrading: "https://paper-api.alpaca.markets/",
    keyId: KEY_ID,
    secretKey: SECRET,
    fetch: fn,
  });
  return { broker, solicitudes };
}

function json(cuerpo: unknown, estado = 200): Response {
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: { "content-type": "application/json" },
  });
}

const COMPRA: OrdenAEnviar = {
  idCliente: "3b7e5c0a-0000-4000-8000-orden-id-001",
  simbolo: "QLD",
  lado: "compra",
  cantidad: 1,
  precioLimite: 111.1,
  proteccion: { stopLoss: 103.4, objetivo: 123.2 },
};

const VENTA: OrdenAEnviar = {
  idCliente: "venta-1",
  simbolo: "QLD",
  lado: "venta",
  cantidad: 3,
  precioLimite: 120.5,
};

Deno.test("enviarOrden: la compra es un bracket límite gtc con stop y objetivo (CA-1, docs/10 §5)", async () => {
  const nueva = await fixture("orden_bracket_nueva.json");
  const { broker, solicitudes } = crear(() => json(nueva));
  const orden = await broker.enviarOrden(COMPRA);

  const [s] = solicitudes;
  assertEquals(s.metodo, "POST");
  assertEquals(s.url.pathname, "/v2/orders");
  assertEquals(s.cuerpo, {
    client_order_id: COMPRA.idCliente,
    symbol: "QLD",
    qty: "1",
    side: "buy",
    type: "limit",
    limit_price: "111.10",
    time_in_force: "gtc",
    order_class: "bracket",
    take_profit: { limit_price: "123.20" },
    stop_loss: { stop_price: "103.40" },
  });
  assertEquals(s.headers.get("APCA-API-KEY-ID"), KEY_ID);
  assertEquals(s.headers.get("APCA-API-SECRET-KEY"), SECRET);
  assertEquals(s.url.search, "");

  assertEquals(orden.estado, "aceptada");
  assertEquals(orden.lado, "compra");
  assertEquals(orden.cantidad, 1);
  assertEquals(orden.precioLimite, 111.1);
  assertEquals(orden.patas.map((p) => [p.tipo, p.precio, p.estado]), [
    ["objetivo", 123.2, "aceptada"],
    ["stop_loss", 103.4, "aceptada"],
  ]);
});

Deno.test("enviarOrden: la venta es simple, límite y day, sin patas", async () => {
  const llena = await fixture("orden_venta_llena.json");
  const { broker, solicitudes } = crear(() => json(llena));
  const orden = await broker.enviarOrden(VENTA);
  assertEquals(solicitudes[0].cuerpo, {
    client_order_id: "venta-1",
    symbol: "QLD",
    qty: "3",
    side: "sell",
    type: "limit",
    limit_price: "120.50",
    time_in_force: "day",
  });
  assertEquals(orden.estado, "llena");
  assertEquals(orden.cantidadLlenada, 3);
  assertEquals(orden.precioPromedio, 121);
  assertEquals(orden.patas, []);
});

Deno.test("enviarOrden: lo que se sale del alcance D-63 no llega al broker", async () => {
  const { broker, solicitudes } = crear(() => json({}));
  const malas: OrdenAEnviar[] = [
    { ...COMPRA, cantidad: 1.5 },
    { ...COMPRA, cantidad: 0 },
    { ...COMPRA, proteccion: undefined },
    { ...COMPRA, proteccion: { stopLoss: 120, objetivo: 123.2 } },
    { ...VENTA, proteccion: { stopLoss: 100, objetivo: 130 } },
    { ...VENTA, precioLimite: 120.555 },
    { ...VENTA, idCliente: " " },
  ];
  for (const mala of malas) {
    await assertRejects(() => broker.enviarOrden(mala), OrdenInvalida);
  }
  assertEquals(solicitudes.length, 0);
});

Deno.test("enviarOrden: 403 es rechazo por fondos y 422 por parámetros (docs/10 §10)", async () => {
  const errorFondos = await fixture("error_fondos.json");
  const e403 = await assertRejects(
    () => crear(() => json(errorFondos, 403)).broker.enviarOrden(COMPRA),
    OrdenRechazada,
  );
  assertEquals(e403.motivo, "fondos_insuficientes");
  assertEquals(e403.estado, 403);
  assert(e403.message.includes("insufficient buying power"));
  assertEquals(envioIncierto(e403), false);

  const errorParametros = await fixture("error_parametros.json");
  const e422 = await assertRejects(
    () => crear(() => json(errorParametros, 422)).broker.enviarOrden(COMPRA),
    OrdenRechazada,
  );
  assertEquals(e422.motivo, "parametros_invalidos");
});

Deno.test("enviarOrden: 5xx, 429 y sin respuesta son ErrorDeProveedor; solo 5xx y sin respuesta son inciertos", async () => {
  const e500 = await assertRejects(
    () => crear(() => json({}, 503)).broker.enviarOrden(COMPRA),
    ErrorDeProveedor,
  );
  assertEquals(e500.estado, 503);
  assertEquals(envioIncierto(e500), true);

  const e429 = await assertRejects(
    () => crear(() => json({}, 429)).broker.enviarOrden(COMPRA),
    ErrorDeProveedor,
  );
  assertEquals(e429.estado, 429);
  assertEquals(envioIncierto(e429), false);

  const tiempo = await assertRejects(
    () =>
      crear(() => new DOMException("agotado", "TimeoutError")).broker
        .enviarOrden(COMPRA),
    ErrorDeProveedor,
    "no respondió a tiempo",
  );
  assertEquals(envioIncierto(tiempo), true);
});

Deno.test("enviarOrden: una respuesta con formato inesperado o estado desconocido falla", async () => {
  await assertRejects(
    () => crear(() => json({ id: 1 })).broker.enviarOrden(COMPRA),
    ErrorDeProveedor,
    "formato inesperado",
  );
  const base = await fixture("orden_bracket_nueva.json") as object;
  await assertRejects(
    () =>
      crear(() => json({ ...base, status: "inventado" })).broker.enviarOrden(
        COMPRA,
      ),
    ErrorDeProveedor,
    "estado desconocido",
  );
});

Deno.test("consultarOrden: por id del broker pide las patas anidadas; por idCliente usa by_client_order_id", async () => {
  const llena = await fixture("orden_bracket_llena.json");
  const { broker, solicitudes } = crear(() => json(llena));
  const orden = await broker.consultarOrden({ idBroker: "61e69015" });
  assertEquals(solicitudes[0].url.pathname, "/v2/orders/61e69015");
  assertEquals(solicitudes[0].url.searchParams.get("nested"), "true");
  assertEquals(orden?.estado, "llena");
  assertEquals(orden?.precioPromedio, 110.85);
  const stop = orden?.patas.find((p) => p.tipo === "stop_loss");
  assertEquals(stop?.estado, "llena");
  assertEquals(stop?.precioPromedio, 103.1);
  assertEquals(
    orden?.patas.find((p) => p.tipo === "objetivo")?.estado,
    "aceptada",
  );

  await broker.consultarOrden({ idCliente: "abc 1" });
  assertEquals(solicitudes[1].url.pathname, "/v2/orders:by_client_order_id");
  assertEquals(solicitudes[1].url.searchParams.get("client_order_id"), "abc 1");
});

Deno.test("consultarOrden: parcial y cancelada se traducen; 404 devuelve null", async () => {
  const jParcial = await fixture("orden_bracket_parcial.json");
  const parcial = await crear(() => json(jParcial)).broker.consultarOrden({
    idBroker: "x",
  });
  assertEquals(parcial?.estado, "parcial");
  assertEquals(parcial?.cantidad, 2);
  assertEquals(parcial?.cantidadLlenada, 1);

  const jCancelada = await fixture("orden_cancelada.json");
  const cancelada = await crear(() => json(jCancelada)).broker.consultarOrden({
    idBroker: "x",
  });
  assertEquals(cancelada?.estado, "cancelada");
  assertEquals(cancelada?.patas.every((p) => p.estado === "cancelada"), true);

  const nada = await crear(() => json({ message: "order not found" }, 404))
    .broker.consultarOrden({ idCliente: "no-existe" });
  assertEquals(nada, null);
});

Deno.test("cancelarOrden: 204 cancela, 404 no existe, 422 ya está cerrada, 5xx falla", async () => {
  const { broker, solicitudes } = crear(() =>
    new Response(null, { status: 204 })
  );
  assertEquals(await broker.cancelarOrden("abc"), "cancelada");
  assertEquals(solicitudes[0].metodo, "DELETE");
  assertEquals(solicitudes[0].url.pathname, "/v2/orders/abc");

  assertEquals(
    await crear(() => json({ message: "x" }, 404)).broker.cancelarOrden("a"),
    "no_existe",
  );
  assertEquals(
    await crear(() => json({ message: "x" }, 422)).broker.cancelarOrden("a"),
    "ya_cerrada",
  );
  await assertRejects(
    () => crear(() => json({}, 500)).broker.cancelarOrden("a"),
    ErrorDeProveedor,
  );
});

Deno.test("posiciones: convierte cantidades y precios; el precio actual puede faltar", async () => {
  const posiciones = await fixture("posiciones.json");
  const { broker, solicitudes } = crear(() => json(posiciones));
  assertEquals(await broker.posiciones(), [
    {
      simbolo: "QLD",
      cantidad: 3,
      precioPromedioDeEntrada: 110.85,
      precioActual: 113.5,
    },
    {
      simbolo: "AAPL",
      cantidad: 1,
      precioPromedioDeEntrada: 200,
      precioActual: null,
    },
  ]);
  assertEquals(solicitudes[0].url.pathname, "/v2/positions");
  assertEquals(await crear(() => json([])).broker.posiciones(), []);
});

Deno.test("CA-5: ni las respuestas ni los errores contienen las llaves", async () => {
  const llena = await fixture("orden_bracket_llena.json");
  const orden = await crear(() => json(llena)).broker.enviarOrden(COMPRA);
  const texto = JSON.stringify(orden);
  assert(!texto.includes(KEY_ID) && !texto.includes(SECRET));

  for (const estado of [403, 422, 500]) {
    const error = await assertRejects(() =>
      crear(() => json({ message: "falló" }, estado)).broker.enviarOrden(COMPRA)
    );
    const m = (error as Error).message;
    assert(!m.includes(KEY_ID) && !m.includes(SECRET));
  }
});

// Pruebas de las órdenes del broker simulado (HU-072, CA-2 y CA-3).

import { assert, assertEquals, assertRejects } from "@std/assert";
import { ErrorDeProveedor } from "../mercado/interfaz.ts";
import {
  envioIncierto,
  type OrdenAEnviar,
  OrdenInvalida,
  OrdenRechazada,
} from "./interfaz.ts";
import { BrokerSimulado, type EscenarioDeOrden } from "./simulado.ts";

const COMPRA: OrdenAEnviar = {
  idCliente: "c-1",
  simbolo: "QLD",
  lado: "compra",
  cantidad: 2,
  precioLimite: 111.1,
  proteccion: { stopLoss: 103.4, objetivo: 123.2 },
};

function crear(escenario?: EscenarioDeOrden) {
  return new BrokerSimulado({ escenario });
}

Deno.test("la orden se acepta y se llena con el siguiente precio si cumple el límite (CA-2)", async () => {
  const broker = crear();
  const enviada = await broker.enviarOrden(COMPRA);
  assertEquals(enviada.estado, "aceptada");
  assertEquals(enviada.cantidadLlenada, 0);
  assertEquals(enviada.patas.length, 2);

  broker.avanzar({ QLD: 112 }); // sobre el límite: no se llena
  assertEquals(
    (await broker.consultarOrden({ idBroker: enviada.idBroker }))?.estado,
    "aceptada",
  );

  broker.avanzar({ QLD: 110.5 }); // bajo el límite: se llena a ese precio, nunca peor
  const llena = await broker.consultarOrden({ idCliente: "c-1" });
  assertEquals(llena?.estado, "llena");
  assertEquals(llena?.cantidadLlenada, 2);
  assertEquals(llena?.precioPromedio, 110.5);
});

Deno.test("la venta límite se llena cuando el precio llega al límite o lo supera", async () => {
  const broker = crear();
  const venta = await broker.enviarOrden({
    idCliente: "v-1",
    simbolo: "QLD",
    lado: "venta",
    cantidad: 1,
    precioLimite: 120,
  });
  broker.avanzar({ QLD: 119 });
  assertEquals(
    (await broker.consultarOrden({ idCliente: "v-1" }))?.estado,
    "aceptada",
  );
  broker.avanzar({ QLD: 121 });
  const llena = await broker.consultarOrden({ idBroker: venta.idBroker });
  assertEquals([llena?.estado, llena?.precioPromedio], ["llena", 121]);
});

Deno.test("las patas esperan al precio siguiente al llenado; el stop vende y cancela el objetivo", async () => {
  const broker = crear();
  await broker.enviarOrden(COMPRA);
  broker.avanzar({ QLD: 100 }); // llena la entrada; el precio ya está bajo el stop pero espera
  let orden = await broker.consultarOrden({ idCliente: "c-1" });
  assertEquals(orden?.estado, "llena");
  assertEquals(orden?.patas.map((p) => p.estado), ["aceptada", "aceptada"]);

  broker.avanzar({ QLD: 103 }); // cruza el stop
  orden = await broker.consultarOrden({ idCliente: "c-1" });
  const stop = orden?.patas.find((p) => p.tipo === "stop_loss");
  const objetivo = orden?.patas.find((p) => p.tipo === "objetivo");
  assertEquals([stop?.estado, stop?.cantidadLlenada, stop?.precioPromedio], [
    "llena",
    2,
    103,
  ]);
  assertEquals(objetivo?.estado, "cancelada");
  assertEquals(await broker.posiciones(), []);
});

Deno.test("el objetivo vende cuando el precio lo alcanza", async () => {
  const broker = crear();
  await broker.enviarOrden(COMPRA);
  broker.avanzar({ QLD: 111 });
  assertEquals((await broker.posiciones())[0].cantidad, 2);
  broker.avanzar({ QLD: 124 });
  const orden = await broker.consultarOrden({ idCliente: "c-1" });
  const objetivo = orden?.patas.find((p) => p.tipo === "objetivo");
  assertEquals([objetivo?.estado, objetivo?.precioPromedio], ["llena", 124]);
  assertEquals(
    orden?.patas.find((p) => p.tipo === "stop_loss")?.estado,
    "cancelada",
  );
});

Deno.test("posiciones: cantidad neta, precio de entrada y precio actual", async () => {
  const broker = crear();
  await broker.enviarOrden(COMPRA);
  broker.avanzar({ QLD: 110 });
  broker.avanzar({ QLD: 112 });
  assertEquals(await broker.posiciones(), [
    {
      simbolo: "QLD",
      cantidad: 2,
      precioPromedioDeEntrada: 110,
      precioActual: 112,
    },
  ]);
  await broker.enviarOrden({
    idCliente: "v-1",
    simbolo: "QLD",
    lado: "venta",
    cantidad: 1,
    precioLimite: 112,
  });
  broker.avanzar({ QLD: 112 });
  assertEquals((await broker.posiciones())[0].cantidad, 1);
});

Deno.test("cancelar: cancela la entrada y sus patas; una orden llena ya está cerrada; id inventado no existe", async () => {
  const broker = crear();
  const orden = await broker.enviarOrden(COMPRA);
  assertEquals(await broker.cancelarOrden(orden.idBroker), "cancelada");
  const cancelada = await broker.consultarOrden({ idBroker: orden.idBroker });
  assertEquals(cancelada?.estado, "cancelada");
  assertEquals(cancelada?.patas.every((p) => p.estado === "cancelada"), true);
  assertEquals(await broker.cancelarOrden(orden.idBroker), "ya_cerrada");

  broker.avanzar({ QLD: 100 }); // la cancelada no se llena
  assertEquals(
    (await broker.consultarOrden({ idCliente: "c-1" }))?.cantidadLlenada,
    0,
  );

  await broker.enviarOrden({ ...COMPRA, idCliente: "c-2" });
  broker.avanzar({ QLD: 100 });
  const llena = await broker.consultarOrden({ idCliente: "c-2" });
  assertEquals(await broker.cancelarOrden(llena!.idBroker), "ya_cerrada");
  // Una pata viva sí se puede cancelar sola.
  assertEquals(
    await broker.cancelarOrden(llena!.patas[0].idBroker),
    "cancelada",
  );
  assertEquals(await broker.cancelarOrden("no-existe"), "no_existe");
  assertEquals(await broker.consultarOrden({ idCliente: "no-existe" }), null);
});

Deno.test("escenario llenado_parcial: la entrada se llena a la mitad y el resto no se llena (CA-3)", async () => {
  const broker = crear("llenado_parcial");
  await broker.enviarOrden({ ...COMPRA, cantidad: 5 });
  broker.avanzar({ QLD: 110 });
  broker.avanzar({ QLD: 109 });
  const orden = await broker.consultarOrden({ idCliente: "c-1" });
  assertEquals([orden?.estado, orden?.cantidadLlenada], ["parcial", 2]);
  assertEquals(await broker.cancelarOrden(orden!.idBroker), "cancelada");
  const final = await broker.consultarOrden({ idCliente: "c-1" });
  assertEquals([final?.estado, final?.cantidadLlenada], ["cancelada", 2]);
});

Deno.test("escenario llenado_parcial: con una sola acción se llena completa", async () => {
  const broker = crear("llenado_parcial");
  await broker.enviarOrden({ ...COMPRA, cantidad: 1 });
  broker.avanzar({ QLD: 110 });
  assertEquals(
    (await broker.consultarOrden({ idCliente: "c-1" }))?.estado,
    "llena",
  );
});

Deno.test("escenario rechazo: enviarOrden falla con OrdenRechazada y no deja la orden (CA-3)", async () => {
  const broker = crear("rechazo");
  const error = await assertRejects(
    () => broker.enviarOrden(COMPRA),
    OrdenRechazada,
  );
  assertEquals(error.motivo, "fondos_insuficientes");
  assertEquals(await broker.consultarOrden({ idCliente: "c-1" }), null);
});

Deno.test("escenario sin_respuesta: falla como un envío incierto pero la orden quedó registrada (CA-3)", async () => {
  const broker = crear("sin_respuesta");
  const error = await assertRejects(
    () => broker.enviarOrden(COMPRA),
    ErrorDeProveedor,
  );
  assertEquals(envioIncierto(error), true);
  const recuperada = await broker.consultarOrden({ idCliente: "c-1" });
  assertEquals(recuperada?.estado, "aceptada");
});

Deno.test("escenario halt: la orden se acepta y nunca se llena (CA-3)", async () => {
  const broker = crear("halt");
  await broker.enviarOrden(COMPRA);
  broker.avanzar({ QLD: 100 });
  broker.avanzar({ QLD: 90 });
  const orden = await broker.consultarOrden({ idCliente: "c-1" });
  assertEquals([orden?.estado, orden?.cantidadLlenada], ["aceptada", 0]);
  // Al volver al escenario normal se llena.
  broker.escenario = "normal";
  broker.avanzar({ QLD: 100 });
  assertEquals(
    (await broker.consultarOrden({ idCliente: "c-1" }))?.estado,
    "llena",
  );
});

Deno.test("validaciones: fuera de D-63, idCliente repetido y activo no negociable", async () => {
  const broker = new BrokerSimulado({ noNegociables: ["XXX"] });
  await assertRejects(
    () => broker.enviarOrden({ ...COMPRA, cantidad: 0.5 }),
    OrdenInvalida,
  );
  await assertRejects(
    () => broker.enviarOrden({ ...COMPRA, proteccion: undefined }),
    OrdenInvalida,
  );
  await broker.enviarOrden(COMPRA);
  const repetido = await assertRejects(
    () => broker.enviarOrden(COMPRA),
    OrdenRechazada,
  );
  assertEquals(repetido.motivo, "parametros_invalidos");
  const noNegociable = await assertRejects(
    () => broker.enviarOrden({ ...COMPRA, idCliente: "c-9", simbolo: "XXX" }),
    OrdenRechazada,
  );
  assertEquals(noNegociable.estado, 422);
});

Deno.test("los resultados son copias: modificarlos no cambia al broker", async () => {
  const broker = crear();
  const enviada = await broker.enviarOrden(COMPRA);
  enviada.estado = "llena";
  enviada.patas[0].estado = "llena";
  const real = await broker.consultarOrden({ idCliente: "c-1" });
  assertEquals(real?.estado, "aceptada");
  assert(real?.patas.every((p) => p.estado === "aceptada"));
});

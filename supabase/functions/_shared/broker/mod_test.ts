import {
  assert,
  assertEquals,
  assertInstanceOf,
  assertThrows,
} from "@std/assert";
import {
  ErrorDeConfiguracion,
  INTEGRACIONES,
  VARIABLE_DE_PROVEEDOR,
} from "../proveedores.ts";
import { ErrorDeProveedor } from "../mercado/interfaz.ts";
import { BrokerAlpaca } from "./alpaca.ts";
import { crearBroker } from "./mod.ts";
import { BrokerSimulado } from "./simulado.ts";

function entorno(variables: Record<string, string>) {
  return (nombre: string) => variables[nombre];
}

/** Las seis integraciones con un proveedor real, como en el proyecto MVP. */
const TODOS_REALES = Object.fromEntries(
  INTEGRACIONES.map((i) => [VARIABLE_DE_PROVEEDOR[i], "alpaca"]),
);
const LLAVES = { ALPACA_KEY_ID: "id", ALPACA_SECRET_KEY: "secreto" };

Deno.test("sin variables, el broker es el simulado con el reloj de calendario", () => {
  const broker = crearBroker(entorno({}));
  assertInstanceOf(broker, BrokerSimulado);
  assertEquals((broker as BrokerSimulado).modo, "calendario");
});

Deno.test("RELOJ_SIMULADO elige el modo del reloj simulado", () => {
  for (
    const modo of [
      "siempre_abierto",
      "cerrado",
      "cierre_en_10_min",
      "calendario",
    ]
  ) {
    const broker = crearBroker(
      entorno({ ENTORNO: "ci", RELOJ_SIMULADO: modo }),
    );
    assertEquals((broker as BrokerSimulado).modo, modo);
  }
  const mayusculas = crearBroker(entorno({ RELOJ_SIMULADO: " Cerrado " }));
  assertEquals((mayusculas as BrokerSimulado).modo, "cerrado");
});

Deno.test("un RELOJ_SIMULADO desconocido es un error de configuración", () => {
  const error = assertThrows(
    () => crearBroker(entorno({ RELOJ_SIMULADO: "medianoche" })),
    ErrorDeConfiguracion,
  );
  assert(!error.message.includes("medianoche"), "no copia el valor");
});

Deno.test("PROVEEDOR_BROKER=alpaca crea el broker real con sus llaves", () => {
  const broker = crearBroker(
    entorno({ PROVEEDOR_BROKER: "alpaca", ...LLAVES }),
  );
  assertInstanceOf(broker, BrokerAlpaca);
});

Deno.test("el broker real exige las llaves", () => {
  assertThrows(
    () => crearBroker(entorno({ PROVEEDOR_BROKER: "alpaca" })),
    ErrorDeProveedor,
    "ALPACA_KEY_ID",
  );
});

Deno.test("ENTORNO=mvp no admite el broker simulado (CB-91)", () => {
  assertThrows(
    () =>
      crearBroker(
        entorno({
          ENTORNO: "mvp",
          ...TODOS_REALES,
          PROVEEDOR_BROKER: "simulado",
          ...LLAVES,
        }),
      ),
    ErrorDeConfiguracion,
    "PROVEEDOR_BROKER",
  );
  // Con todo real, ENTORNO=mvp funciona.
  assertInstanceOf(
    crearBroker(entorno({ ENTORNO: "mvp", ...TODOS_REALES, ...LLAVES })),
    BrokerAlpaca,
  );
});

Deno.test("EFECTIVO_SIMULADO fija el efectivo de la cuenta simulada y se valida", async () => {
  const broker = crearBroker(entorno({ EFECTIVO_SIMULADO: " 10000 " }));
  assertEquals(await broker.cuenta(), { efectivo: 10_000 });
  assertEquals(await crearBroker(entorno({})).cuenta(), { efectivo: 100_000 });
  for (const malo of ["abc", "-5"]) {
    assertThrows(
      () => crearBroker(entorno({ EFECTIVO_SIMULADO: malo })),
      ErrorDeConfiguracion,
    );
  }
});

Deno.test("crearBroker pasa el escenario de pruebas al simulado (HU-072)", () => {
  const broker = crearBroker(entorno({}), "halt") as BrokerSimulado;
  assertEquals(broker.escenario, "halt");
  assertEquals(
    (crearBroker(entorno({})) as BrokerSimulado).escenario,
    "normal",
  );
});

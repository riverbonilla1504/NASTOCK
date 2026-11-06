import { assert, assertInstanceOf, assertThrows } from "@std/assert";
import {
  ErrorDeConfiguracion,
  INTEGRACIONES,
  VARIABLE_DE_PROVEEDOR,
} from "../proveedores.ts";
import { MercadoAlpaca } from "./alpaca.ts";
import { ErrorDeProveedor } from "./interfaz.ts";
import { crearProveedorDeMercado } from "./mod.ts";
import { MercadoSimulado } from "./simulado.ts";

function entorno(variables: Record<string, string>) {
  return (nombre: string) => variables[nombre];
}

/** Las seis integraciones con un proveedor real, como en el proyecto MVP. */
const TODOS_REALES = Object.fromEntries(
  INTEGRACIONES.map((i) => [VARIABLE_DE_PROVEEDOR[i], "alpaca"]),
);
const LLAVES = { ALPACA_KEY_ID: "id", ALPACA_SECRET_KEY: "secreto" };

Deno.test("sin variables, el proveedor de mercado es el simulado", () => {
  assertInstanceOf(crearProveedorDeMercado(entorno({})), MercadoSimulado);
  assertInstanceOf(
    crearProveedorDeMercado(
      entorno({ ENTORNO: "ci", PROVEEDOR_MERCADO: "simulado" }),
    ),
    MercadoSimulado,
  );
});

Deno.test("PROVEEDOR_MERCADO=alpaca crea el adaptador real con sus llaves", () => {
  const proveedor = crearProveedorDeMercado(
    entorno({ PROVEEDOR_MERCADO: "alpaca", ...LLAVES }),
  );
  assertInstanceOf(proveedor, MercadoAlpaca);
});

Deno.test("el adaptador real exige las llaves", () => {
  assertThrows(
    () => crearProveedorDeMercado(entorno({ PROVEEDOR_MERCADO: "alpaca" })),
    ErrorDeProveedor,
    "ALPACA_KEY_ID",
  );
});

Deno.test("con ENTORNO=mvp no se admite el simulado, aunque sea solo el de mercado", () => {
  const problema = assertThrows(
    () =>
      crearProveedorDeMercado(
        entorno({
          ...TODOS_REALES,
          ENTORNO: "mvp",
          PROVEEDOR_MERCADO: "simulado",
          ...LLAVES,
        }),
      ),
    ErrorDeConfiguracion,
  );
  assert(
    (problema as ErrorDeConfiguracion).problemas.some((p) =>
      p.includes("PROVEEDOR_MERCADO")
    ),
  );
});

Deno.test("con ENTORNO=mvp y todo real, funciona", () => {
  assertInstanceOf(
    crearProveedorDeMercado(
      entorno({ ...TODOS_REALES, ENTORNO: "mvp", ...LLAVES }),
    ),
    MercadoAlpaca,
  );
});

Deno.test("un proveedor desconocido es un error de configuración", () => {
  assertThrows(
    () => crearProveedorDeMercado(entorno({ PROVEEDOR_MERCADO: "otro" })),
    ErrorDeConfiguracion,
    "PROVEEDOR_MERCADO",
  );
});

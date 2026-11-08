// Elige el proveedor de mercado según PROVEEDOR_MERCADO (docs/10 §9, _shared/proveedores.ts).
//
//   PROVEEDOR_MERCADO=simulado (o sin definir)  → MercadoSimulado
//   PROVEEDOR_MERCADO=alpaca                    → MercadoAlpaca, con ALPACA_KEY_ID,
//                                                 ALPACA_SECRET_KEY y ALPACA_DATA_URL
//
// Con ENTORNO=mvp, `elegirProveedor` se niega a usar cualquier proveedor simulado (CB-91).
// Cada función debe llamar a esta función al cargar el módulo, fuera del manejador de
// peticiones: así, una configuración inválida impide que la función arranque.

import { elegirProveedor, type LeerVariable } from "../proveedores.ts";
import { MercadoAlpaca } from "./alpaca.ts";
import type { ProveedorDeMercado } from "./interfaz.ts";
import { MercadoSimulado } from "./simulado.ts";

export type {
  Barra,
  BarraDeMinuto,
  ConsultaDeBarras,
  Cotizacion,
  ProveedorDeMercado,
  ResultadoDeBarras,
} from "./interfaz.ts";
export { ErrorDeProveedor } from "./interfaz.ts";

/** URL de la API de datos de Alpaca si ALPACA_DATA_URL no está definida (docs/10 §1). */
export const URL_DE_DATOS_POR_DEFECTO = "https://data.alpaca.markets";

export function crearProveedorDeMercado(
  leer: LeerVariable = (nombre) => Deno.env.get(nombre),
): ProveedorDeMercado {
  return elegirProveedor<ProveedorDeMercado>("mercado", {
    simulado: () => new MercadoSimulado(),
    alpaca: () =>
      new MercadoAlpaca({
        urlDatos: leer("ALPACA_DATA_URL")?.trim() || URL_DE_DATOS_POR_DEFECTO,
        keyId: leer("ALPACA_KEY_ID")?.trim() ?? "",
        secretKey: leer("ALPACA_SECRET_KEY")?.trim() ?? "",
      }),
  }, leer);
}

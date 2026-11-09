// Adaptador de JEV, el modelo de decisiones tipadas de TypeSafe AI (docs/07 §5 y §6.1, HU-045).
//
// Una sola interfaz con dos implementaciones: `typesafe.ts` (real) y `simulado.ts` (local y CI).
// Cuál se usa lo decide PROVEEDOR_JEV (`_shared/proveedores.ts`). JEV recibe etiquetas en inglés,
// nunca cifras ni fechas para comparar ni datos de personas (docs/07 §4.3 y §4.5).
//
// Cada función debe llamar a `crearJev` al cargar el módulo, fuera del manejador.

import { elegirProveedor, type LeerVariable } from "../proveedores.ts";
import { JevSimulado } from "./simulado.ts";
import type { ProveedorDeJev } from "./tipos.ts";
import { JevTypeSafe } from "./typesafe.ts";

export * from "./tipos.ts";

export function crearJev(
  leer: LeerVariable = (nombre) => Deno.env.get(nombre),
): ProveedorDeJev {
  return elegirProveedor<ProveedorDeJev>("jev", {
    simulado: () => new JevSimulado(leer("JEV_ESCENARIO")),
    // Sin llave no falla al arrancar: la evaluación sigue "sin JEV" y lo dice.
    typesafe: () =>
      new JevTypeSafe({
        llave: leer("TYPESAFE_API_KEY")?.trim() ?? "",
        url: leer("TYPESAFE_URL")?.trim() || undefined,
      }),
  }, leer);
}

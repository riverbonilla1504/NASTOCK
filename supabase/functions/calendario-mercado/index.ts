// Edge Function `calendario-mercado` (docs/05 §6).
//
// HU-026: carga inicial de dos años de barras diarias del universo. La invoca el trabajo
// diario `calendario` (HU-027) o una persona con el secreto interno. Habla con la base por
// conexión directa y solo ejecuta funciones de `private` (D-66, _shared/bd.ts).
//
// El proveedor se elige al cargar el módulo, no en cada petición: con una configuración
// inválida (por ejemplo, un proveedor simulado con ENTORNO=mvp) la función no arranca.

import { crearBd } from "../_shared/bd.ts";
import { crearProveedorDeMercado } from "../_shared/mercado/mod.ts";
import { crearManejador } from "./manejador.ts";

const mercado = crearProveedorDeMercado();

Deno.serve(crearManejador({ mercado, abrirBd: () => crearBd() }));

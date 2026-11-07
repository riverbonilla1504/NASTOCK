// Edge Function `calendario-mercado` (docs/05 §6).
//
// HU-027: sincroniza el calendario, el reloj y los atributos de los activos con el broker.
// HU-026: carga inicial de dos años de barras diarias del universo. La invoca el trabajo diario
// `calendario` de pg_cron o una persona con el secreto interno. Habla con la base por conexión
// directa y solo ejecuta funciones de `private` (D-66, _shared/bd.ts).
//
// Los proveedores se eligen al cargar el módulo, no en cada petición: con una configuración
// inválida (por ejemplo, un proveedor simulado con ENTORNO=mvp) la función no arranca.

import { crearBd } from "../_shared/bd.ts";
import { crearBroker } from "../_shared/broker/mod.ts";
import { crearProveedorDeMercado } from "../_shared/mercado/mod.ts";
import { crearManejador } from "./manejador.ts";

const mercado = crearProveedorDeMercado();
const broker = crearBroker();

Deno.serve(crearManejador({ mercado, broker, abrirBd: () => crearBd() }));

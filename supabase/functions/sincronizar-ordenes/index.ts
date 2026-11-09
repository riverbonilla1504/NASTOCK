// Edge Function `sincronizar-ordenes` (docs/05 §6).
//
// HU-074: consulta al broker el estado de las órdenes vivas, aplica los llenados con
// `private.aplicar_llenado` (libro, posición, retención y reparto de la ganancia) y cancela las compras que
// superan el tiempo máximo de llenado. La despierta el trabajo `sincronizar_ordenes` de pg_cron o una
// persona con el secreto interno. Habla con la base por conexión directa y solo ejecuta funciones de
// `private` (D-66, _shared/bd.ts).
//
// El broker se elige al cargar el módulo, no en cada petición: con una configuración inválida (por ejemplo,
// un proveedor simulado con ENTORNO=mvp) la función no arranca.

import { crearBd } from "../_shared/bd.ts";
import { crearBroker } from "../_shared/broker/mod.ts";
import { crearManejador } from "./manejador.ts";

const broker = crearBroker();

Deno.serve(crearManejador({ broker, abrirBd: () => crearBd() }));

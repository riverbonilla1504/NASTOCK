// Edge Function `ejecutor-ordenes` (docs/05 §6).
//
// HU-073: toma las órdenes de la cola `ordenes_por_enviar`, las revalida en la base, las envía al broker
// con `client_order_id` idempotente y cierra cada envío. La despierta el trabajo `barrer_ejecutor` de
// pg_cron o una persona con el secreto interno. Habla con la base por conexión directa y solo ejecuta
// funciones de `private` (D-66, _shared/bd.ts).
//
// El broker se elige al cargar el módulo, no en cada petición: con una configuración inválida (por
// ejemplo, un proveedor simulado con ENTORNO=mvp) la función no arranca.

import { crearBd } from "../_shared/bd.ts";
import { crearBroker } from "../_shared/broker/mod.ts";
import { crearManejador } from "./manejador.ts";

const broker = crearBroker();

Deno.serve(crearManejador({ broker, abrirBd: () => crearBd() }));

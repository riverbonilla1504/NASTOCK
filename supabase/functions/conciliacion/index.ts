// Edge Function `conciliacion` (docs/05 §6).
//
// HU-015: compara el efectivo de la cuenta paper del broker con el del libro, registra el resultado y
// confirma los aportes que el efectivo ya cubre (que se reparten 50/25/25 en la base). La invoca el
// trabajo `conciliacion` de pg_cron o una persona con el secreto interno. Habla con la base por
// conexión directa y solo ejecuta funciones de `private` (D-66, _shared/bd.ts).
//
// El broker se elige al cargar el módulo, no en cada petición: con una configuración inválida (por
// ejemplo, un proveedor simulado con ENTORNO=mvp) la función no arranca.

import { crearBd } from "../_shared/bd.ts";
import { crearBroker } from "../_shared/broker/mod.ts";
import { crearManejador } from "./manejador.ts";

const broker = crearBroker();

Deno.serve(crearManejador({ broker, abrirBd: () => crearBd() }));

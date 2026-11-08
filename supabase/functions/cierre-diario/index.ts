// Edge Function `cierre-diario` (docs/05 §6).
//
// HU-029: agrega la barra diaria de cada símbolo del universo tras el cierre. La despierta el
// trabajo `cierre_diario` de pg_cron cuando el mercado ya cerró hoy y falta alguna barra, o una
// persona con el secreto interno. Habla con la base por conexión directa y solo ejecuta funciones
// de `private` (D-66, _shared/bd.ts). No importa _shared/broker/.
//
// El proveedor se elige al cargar el módulo: con una configuración inválida (por ejemplo, uno
// simulado con ENTORNO=mvp) la función no arranca.

import { crearBd } from "../_shared/bd.ts";
import { crearProveedorDeMercado } from "../_shared/mercado/mod.ts";
import { crearManejador } from "./manejador.ts";

const mercado = crearProveedorDeMercado();

Deno.serve(crearManejador({ mercado, abrirBd: () => crearBd() }));

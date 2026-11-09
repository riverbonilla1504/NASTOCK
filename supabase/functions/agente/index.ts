// Edge Function `agente` (docs/07 §3, HU-044 a HU-048, corte de demo D-70).
//
// La despierta el trabajo `ciclo_agente` de pg_cron con el secreto interno. Evalúa las candidatas
// con las métricas del mercado y las respuestas de JEV, y guarda cada evaluación con su explicación.
// No importa el módulo del broker: la IA no compra ni vende.
//
// El proveedor de JEV se elige al cargar el módulo: con una configuración inválida (por ejemplo,
// JEV simulado con ENTORNO=mvp) la función no arranca. Sin TYPESAFE_API_KEY sí arranca y cada
// evaluación queda "sin JEV".

import { crearBd } from "../_shared/bd.ts";
import { crearJev } from "../_shared/ia/jev.ts";
import { crearManejador } from "./manejador.ts";

const jev = crearJev();

Deno.serve(crearManejador({ jev, abrirBd: () => crearBd() }));

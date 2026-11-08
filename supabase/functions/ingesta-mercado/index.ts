// Edge Function `ingesta-mercado` (docs/05 §6, docs/09 §2), HU-028.
//
// La despierta el trabajo `ingesta_mercado` de pg_cron cada 15 segundos con el mercado en ventana.
// Consulta los precios del universo y los ETF, y llama a private.publicar_cotizaciones. No importa
// `_shared/broker/`: solo lee precios, no ejecuta nada.
//
// El proveedor se elige al cargar el módulo: con una configuración inválida (por ejemplo, un
// proveedor simulado con ENTORNO=mvp) la función no arranca.

import { crearBd } from "../_shared/bd.ts";
import { crearProveedorDeMercado } from "../_shared/mercado/mod.ts";
import { crearManejador } from "./manejador.ts";

const mercado = crearProveedorDeMercado();
const fuente = Deno.env.get("PROVEEDOR_MERCADO") === "alpaca"
  ? "alpaca-iex"
  : "simulado";

Deno.serve(crearManejador({ mercado, fuente, abrirBd: () => crearBd() }));

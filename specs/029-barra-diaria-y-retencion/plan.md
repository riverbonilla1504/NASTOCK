# Plan de implementación (Implementation Plan): HU-029 · Barra diaria tras el cierre y retención de barras de minuto

**Branch**: `029-barra-diaria-y-retencion` | **Spec**: [spec.md](spec.md) | Historia: `backlog/E-04-datos-de-mercado/HU-029-*.md`, issue #48.

## Resumen

Módulo M-05. Por capas: **migración** (funciones `private`) → **Edge Function** `cierre-diario` → **trabajos de `pg_cron`**.

- `private.cierre_diario_pendiente()`: verdadera si el mercado ya cerró hoy (fila de `calendario_mercado` con la fecha de hoy en Nueva York y `private.ahora() >= cierre`) y a algún símbolo de `private.simbolos_del_universo()` le falta su barra de hoy en `barras_diarias`. Cubre CA-2 y CA-4.
- `cierre-diario` (primera versión): lee la hora de `private.ahora()`, pide a `_shared/mercado/` la barra de hoy de cada símbolo en lotes de 20 y la guarda con `private.guardar_barras_diarias` (idempotente). Cubre CA-1. Solo ejecuta funciones de `private` (D-66); no importa `_shared/broker/`.
- `private.limpiar_barras_minuto()`: borra las barras de más de 5 días y las de símbolos que no son ETF ni tienen posición sin cerrar. Cubre CA-3.
- Trabajos `cierre_diario` (`*/10 * * * *`, `despertar_funcion('cierre-diario') where private.cierre_diario_pendiente()`) y `limpieza` (`0 8 * * *`).

## Revisión de la constitución

| Principio | ¿Cumple? | Cómo |
|---|---|---|
| `docs/` es la fuente de verdad | Sí, con dos puntos abiertos | Ver abajo; se escribieron en `docs/06` §8.2 y `docs/17` solo como descripción de lo construido. |
| Inv. 2 y 3 (motor de políticas, libro) | N/A | No hay operaciones ni dinero. |
| Inv. 4 (RPC y RLS) | Sí | No hay tablas nuevas ni escrituras desde la app; las funciones no son ejecutables por `anon` ni `authenticated`. |
| Inv. 6 y 8 | Sí | Sin llaves; el proveedor sale de `crearProveedorDeMercado` (simulado solo en local y CI). |
| Inv. 9 | Sí | Dos migraciones nuevas, solo hacia adelante. |

### Puntos que `docs/` no fija (pendientes de confirmar por Javier)

1. **Cómo se sabe que "no se ha corrido hoy"** (`docs/05` §7). No hay tabla de ejecuciones. Se deriva sin estado nuevo: falta la barra de hoy de algún símbolo del universo. Efecto: si un símbolo activo nunca recibe barra (suspendido en bolsa), el trabajo reintenta cada 10 min hasta medianoche de Nueva York; es inofensivo (idempotente). Cuando HU-021, HU-024, HU-056 o HU-082 sumen pasos al cierre necesitarán su propia marca.
2. **"Símbolos con posiciones" antes de que exista `posiciones`** (`docs/06` §5.5). La limpieza consulta la tabla solo si existe (`to_regclass`), así que no hay que cambiar la función cuando se cree. **ETF** se interpreta como `lista_blanca.en_nasdaq100 = false` más QQQ.

## Pruebas

- pgTAP `supabase/tests/database/08_cierre_diario_y_limpieza_test.sql` (reloj fijado): antes/después del cierre, con/sin barras de hoy, fecha de Nueva York, sábado, domingo, feriado, media jornada, símbolo nuevo, permisos, retención con y sin `posiciones`, trabajos.
- `deno test` `supabase/functions/cierre-diario/manejador_test.ts`: CA-1, lotes, solo fecha de hoy, sin datos, 502, 500, 401/403/405.
- Sin escenario E2E propio (`docs/15` §4); `scripts/verificar.sh` completo.

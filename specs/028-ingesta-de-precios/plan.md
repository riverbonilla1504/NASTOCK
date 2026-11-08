# Plan de implementación: HU-028 · Ingesta de precios cada 15 segundos

**Branch**: `028-ingesta-de-precios` | **Spec**: [spec.md](spec.md) | Issue #47 | Módulo M-05

## Resumen

Un trabajo de `pg_cron` despierta cada 15 s a `ingesta-mercado` si `private.mercado_en_ventana(interval '10 minutes')`. La función pide en una sola llamada los `snapshots` del universo y los ETF, descarta los precios inválidos (CB-53) y entrega el lote a `private.publicar_cotizaciones`, que en una transacción guarda `cotizaciones`, guarda barras de minuto de los ETF y publica el evento `cotizaciones` en el canal `mercado` (`private.publicar_evento`, HU-083). `estado_mercado()` llena `datos_actualizados_en` con el `recibido_en` más reciente.

Capas: migración (tabla, RLS) → funciones `private` → `estado_mercado()` → trabajo de `pg_cron` → proveedor de mercado (barra de minuto) → Edge Function → E2E.

## Contexto técnico

SQL (Postgres 17) y TypeScript en Deno. Sin dependencias nuevas (zod ya está). Pruebas: pgTAP (`09_ingesta_de_precios_test.sql`), `deno test` (`ingesta-mercado/manejador_test.ts`, `_shared/mercado/*`), E2E de backend (`tests/e2e/01_mercado_en_vivo_test.ts`, E2E-03). Restricciones: solo funciones de `private` desde Edge Functions (D-66); `ingesta-mercado` no importa `_shared/broker/`; hora siempre de `private.ahora()`; RLS activo y sin escrituras directas.

## Constitución

Todo sale de `docs/09` §1, §2 y §4, `docs/05` §6 y §7, `docs/06` §5.2 y §8.2, `docs/12` §6. No cambia ninguna regla de `docs/`. Sin servicios nuevos (Alpaca paper gratis, feed IEX).

## Decisiones de detalle (sin cambiar reglas)

1. Carga del evento: la de `docs/09` §4 (`momento` y `datos` con `s`, `p`, `b`, `a`, `vd`); los precios son la excepción documentada a "sin montos".
2. Un dato con `momento` más viejo que el guardado no lo reemplaza ni se publica; uno del mismo momento sí refresca `recibido_en` (el mercado puede no haber operado, pero la consulta fue reciente).
3. Barras de minuto: solo de los ETF (`lista_blanca.en_nasdaq100 = false`). Las de símbolos con posiciones se agregan cuando exista `posiciones` (`docs/06` §10).
4. Descarte "registrado": `publicar_cotizaciones` devuelve `descartes` (símbolo y motivo) y la función los escribe en el registro y en su respuesta. El registro en `salud_integraciones` es de HU-035.
5. Fuera de ventana la función responde `200 {omitida: true}` aunque la llamen a mano.
6. Fallo del proveedor: `502 INTEGRACION_CAIDA`, sin tocar `cotizaciones`; la app sigue con el último precio y su antigüedad.

## Estructura

- `supabase/migrations/*_cotizaciones.sql`, `*_publicar_cotizaciones.sql`, `*_frescura_en_estado_mercado.sql`, `*_trabajo_ingesta_mercado.sql`
- `supabase/functions/ingesta-mercado/{index,manejador,manejador_test}.ts`, `supabase/config.toml` (`verify_jwt = false`)
- `supabase/functions/_shared/mercado/` (`Cotizacion.barraMinuto`)
- `supabase/tests/database/09_ingesta_de_precios_test.sql`, `supabase/tests/e2e/01_mercado_en_vivo_test.ts`

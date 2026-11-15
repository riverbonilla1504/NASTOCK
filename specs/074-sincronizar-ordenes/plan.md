# Plan: HU-074 · Sincronizar órdenes y aplicar llenados

**Rama**: `074-sincronizar-ordenes` (#191) · **Módulos**: M-04, M-10 · **Fuentes**: `docs/10` §7 · `docs/06` §5.4 · RN-23 · CB-34, CB-35, CB-38, CB-39.

- **Migraciones**: `20261110130003_cambiar_estado_orden_con_llenado.sql`, `20261110130004_posiciones_y_protecciones.sql` (tablas `posiciones` y `protecciones` con RLS y la vista de posiciones valoradas) y `20261110130005_aplicar_llenado.sql` (`private.aplicar_llenado`: libera la retención, descuenta el costo real, crea o actualiza la posición con su costo promedio y es idempotente ante el mismo llenado).
- **Función** `sincronizar-ordenes` (`index.ts`, `manejador.ts`): consulta orden por orden al broker y aplica cada llenado; cancela la compra que no se llena en `ejecucion.minutos_max_llenado` (CB-35) y respeta el vencimiento de las órdenes `day` (CB-38). Registra la salud de `alpaca_trading`.
- **Broker**: `OrdenDelBroker.estadoBroker` en `_shared/broker/` (Alpaca y simulado).

Decisiones sin regla explícita en `docs/`:
- Una orden que el broker no conoce cuenta como respuesta: la salud de `alpaca_trading` queda buena.
- `protecciones` solo se crea; la llena HU-077.
- Sin notificaciones (D-62).

Pruebas: pgTAP `20_aplicar_llenado_test.sql` (65) · `deno test sincronizar-ordenes` (11), con el broker y el ejecutor.

# Plan de implementación: HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25

**Rama**: `015-confirmar-y-repartir-el-aporte` · **Spec**: [spec.md](spec.md) · **Módulos**: M-04 y M-12 (`docs/17`)

## Resumen

Tres migraciones, una operación nueva del broker y una Edge Function. La función `conciliacion` lee el efectivo de la cuenta paper y se lo entrega a `private.registrar_conciliacion`; la base decide el resultado, confirma los aportes que el efectivo cubre y los reparte con `reparto.pct_*` (RN-08, RN-09), todo en una transacción. Sin app (la pantalla es HU-099).

## Contexto técnico

PostgreSQL 17, Deno (Edge Functions), pgTAP y `deno test`. Fuentes: `docs/02` RN-07 a RN-09; `docs/06` §5.6, §8.2; `docs/08` §4, §7.6; `docs/10` §4.1, §8; `docs/05` §6 y §7; `docs/12` CB-11, CB-12.

## Por capas

1. **Broker** (`_shared/broker/`): operación `cuenta()` (`efectivo` = `cash` de `/v2/account`) en la interfaz, en `alpaca.ts` y en `simulado.ts` (`EFECTIVO_SIMULADO`, 100.000 por defecto como Alpaca).
2. **Tabla y condición del trabajo** (`20261109140000`): `resultado_conciliacion`, `conciliaciones` con RLS de lectura para supervisores, evento `conciliacion` en `supervision`, `private.efectivo_del_libro()` y `private.conciliacion_pendiente()`.
3. **Confirmación y conciliación** (`20261109140002`): `private.confirmar_aporte(id)`, `private.aportes_sin_confirmar()` y `private.registrar_conciliacion(efectivo, detalle)`.
4. **Trabajo** (`20261109140004`): `conciliacion` de pg_cron, cada minuto, con la condición de SQL.
5. **Edge Function** `conciliacion`: secreto interno, 502 `INTEGRACION_CAIDA` si el broker falla, 200 con la conciliación registrada.

## Decisiones que no están en `docs/`

- **Efectivo del libro** = suma del efectivo de todas las subcuentas salvo `externa` (docs/10 §8 dice «bolsillos y cupos»; se incluye `resultados`, que también es dinero en la cuenta).
- **Cuándo se confirma**: con resultado `ok` (el broker cubre el libro); cada aporte, del más antiguo al más nuevo, necesita que el efectivo sobrante cubra su monto. Sin tolerancia en la cobertura: «si tiene menos, el aporte no se confirma» (docs/10 §4.1).
- **El trabajo también corre con mercado cerrado** si hay un aporte registrado esperando (docs/05 §7 lo limita al horario de mercado): el efectivo de la cuenta paper no depende del mercado y esperar a la apertura retrasaría el fondo.
- **Alerta a la hora (CA-3)**: la tabla `alertas` llega con HU-085. Hoy la conciliación deja la constancia en `conciliaciones.nota`, emite un aviso en el registro y `private.aportes_sin_confirmar()` queda lista para que HU-085 cree la alerta.
- **Descuadre crítico**: se registra y se publica, pero no apaga `trading_activo` (la pausa automática y las posiciones llegan con HU-080).
- Las partes del reparto en cero (porcentaje 0 % o aportes de centavos) no generan asiento: el libro no admite asientos de monto cero.

## Pruebas

`supabase/tests/database/14_conciliacion_y_reparto_test.sql` (56 pruebas): CA-1 a CA-5, CB-11, CB-12, porcentajes vigentes, tolerancia y descuadre, varios aportes, lectura por rol. `deno test`: manejador de `conciliacion`, `cuenta` en el broker real y el simulado. **No incluye** el E2E-04 (arnés TT-06) ni `scripts/verificar.sh` completo, por decisión de Javier.

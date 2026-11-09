# Tareas: HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25

**Entrada**: [plan.md](plan.md), [spec.md](spec.md) · Una sola historia de usuario (US1), por capas.

- [X] T001 [US1] Operación `cuenta` en `supabase/functions/_shared/broker/` (interfaz, `alpaca.ts`, `simulado.ts`, `mod.ts`) con sus pruebas
- [X] T002 [US1] Migración `20261109140000_conciliaciones.sql`: tipo, tabla, RLS, evento `conciliacion`, `efectivo_del_libro` y `conciliacion_pendiente`
- [X] T003 [US1] Migración `20261109140002_confirmar_aporte_y_conciliar.sql`: `confirmar_aporte`, `aportes_sin_confirmar` y `registrar_conciliacion` (CA-1, CA-2, CA-4, CA-5)
- [X] T004 [US1] Migración `20261109140004_trabajo_conciliacion.sql`: trabajo de pg_cron
- [X] T005 [US1] Edge Function `supabase/functions/conciliacion/` con `[functions.conciliacion]` en `config.toml` y `EFECTIVO_SIMULADO` en `.env.e2e`
- [X] T006 [US1] Pruebas pgTAP `14_conciliacion_y_reparto_test.sql` (CA-1 a CA-5, CB-11, CB-12) y `deno test` del manejador
- [X] T007 [US1] Actualizar `docs/06` §8.2 y `docs/17` (M-04)
- [ ] T008 [US1] Alerta al Administrador a la hora (CA-3): espera a HU-085; hoy queda en `conciliaciones.nota` y `private.aportes_sin_confirmar()`
- [ ] T009 [US1] E2E-04: espera al arnés TT-06 (decisión de Javier: pruebas mínimas)
- [X] T010 [US1] `supabase db reset`, `supabase test db` y `deno test` en verde (sin `scripts/verificar.sh` completo)

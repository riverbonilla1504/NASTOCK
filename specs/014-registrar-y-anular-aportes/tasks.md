# Tareas: HU-014 · Registrar y anular aportes

**Entrada**: [plan.md](plan.md), [spec.md](spec.md) · Una sola historia de usuario (US1), por capas.

- [X] T001 [US1] Migración `20261109130000_capital_tabla_y_evento.sql`: tipo, tabla, RLS de lectura para supervisores y evento `capital` (docs/06 §4.3, docs/09)
- [X] T002 [US1] Migración `20261109130002_capital_registrar_y_anular_aporte.sql`: `registrar_aporte` y `anular_aporte` con auditoría (CA-1 a CA-5)
- [X] T003 [US1] Pruebas pgTAP `supabase/tests/database/13_capital_aportes_test.sql`
- [X] T004 [US1] Actualizar `docs/17` (M-04)
- [X] T005 [US1] `supabase db reset` y `supabase test db` en verde (decisión de Javier: sin `scripts/verificar.sh` completo)

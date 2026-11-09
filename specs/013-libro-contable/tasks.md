# Tareas: HU-013 · Libro contable de doble partida

**Entrada**: [plan.md](plan.md), [spec.md](spec.md) · Una sola historia de usuario (US1), por capas.

- [X] T001 [US1] Migración `20261109120000_libro_tipos_y_tablas.sql`: tipos, `fondos`, `subcuentas`, `movimientos`, `asientos`, `CHECK`, índices únicos, revocación de escritura y políticas de lectura (docs/06 §4, docs/03 §4.3)
- [X] T002 [US1] Migración `20261109120002_libro_registrar_movimiento.sql`: `private.registrar_movimiento`, verificación diferida de suma cero y trigger de inmutabilidad (CA-2, CA-3, CA-4)
- [X] T003 [US1] Migración `20261109120004_libro_datos_iniciales.sql`: el fondo y sus cinco subcuentas fijas (CA-1)
- [X] T004 [US1] Migración `20261109120006_libro_verificacion_diaria.sql`: `private.verificar_libro()` y trabajo diario (CA-5; la alerta espera a HU-085)
- [X] T005 [US1] Pruebas pgTAP `supabase/tests/database/12_libro_contable_test.sql`: L1 a L5, no negativos, inmutabilidad, lectura por rol
- [X] T006 [US1] Actualizar `docs/06` §8.2 y `docs/17` (M-03)
- [X] T007 [US1] `supabase db reset` y `supabase test db` en verde (decisión de Javier: sin `scripts/verificar.sh` completo)

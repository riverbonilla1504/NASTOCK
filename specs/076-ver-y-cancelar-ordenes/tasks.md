# Tareas: HU-076

**Input**: spec.md y plan.md. US1 única; FR-171 y CA-1 a CA-5.

- [x] T001 Precisar el envío de cancelaciones aprobado en `docs/05-arquitectura.md`, `docs/10-integracion-bolsa.md` y el historial de `docs/13-decisiones-pendientes-riesgos.md`.
- [x] T002 [US1] Implementar RPC, solicitud y auditoría en `supabase/migrations/20261115140000_cancelar_orden.sql`.
- [x] T003 [US1] Agregar pruebas SQL en `supabase/tests/database/25_cancelar_orden_test.sql` para dueño, parcial, carrera, retención e idempotencia.
- [x] T004 [US1] Ampliar `supabase/functions/sincronizar-ordenes/manejador.ts` y pruebas para enviar solicitudes además del vencimiento por tiempo.
- [x] T005 [US1] Agregar `lib/features/ordenes/domain/mi_orden.dart`, repositorio, provider y pantalla; enlazar desde Mi cupo.
- [x] T006 [US1] Agregar widget y E2E en `test/features/ordenes/mis_ordenes_test.dart` e `integration_test/app_test.dart`.
- [x] T007 Actualizar mapa/catálogo en `docs/17-mapa-de-modulos.md` y `docs/15-calidad-pruebas-y-ci-cd.md`.
- [x] T008 Ejecutar `scripts/verificar.sh` completo y CI antes del PR y cierre de #99.

T001 → T002/T003 → T004 → T005 → T006/T007 → T008. La prueba independiente demuestra cancelación confirmada y conservación del dinero/llenados, sin permitir cancelar órdenes ajenas. No se reduce la suite para aprobar.

Validación: script completo (sin omitir E2E) aprobado con las cuatro historias juntas el 2026-11-15: [ejecución](https://github.com/riverbonilla1504/NASTOCK/actions/runs/43740991487). PR #204.

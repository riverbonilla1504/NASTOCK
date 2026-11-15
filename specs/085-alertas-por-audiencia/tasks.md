# Tareas: HU-085

**Input**: spec.md y plan.md. Una historia US1, pruebas obligatorias.

- [x] T001 Revisar issue #109 y aprobar/documentar privacidad personal en `docs/03-roles-y-permisos.md` y `docs/13-decisiones-pendientes-riesgos.md`.
- [x] T002 [US1] Crear tipos, tabla, índice parcial, RLS y funciones internas en `supabase/migrations/20261115130000_alertas_por_audiencia.sql` (CA-1/2/3/4).
- [x] T003 [US1] Conectar el símbolo no negociable dentro de la migración de alertas (CA-5).
- [x] T004 [US1] Agregar pgTAP de todos los CA en `supabase/tests/database/24_alertas_test.sql`.
- [x] T005 [US1] Agregar dominio, repositorio y pantalla en `lib/features/alertas/`; conectar `lib/app/destinos.dart` con foto/eventos.
- [x] T006 [US1] Verificar estados y tamaños en `test/features/alertas/alertas_test.dart`.
- [x] T007 [US1] Actualizar E2E en `integration_test/app_test.dart` y mapa en `docs/17-mapa-de-modulos.md`.
- [ ] T008 Ejecutar `scripts/verificar.sh` y CI, revisar aislamiento y publicar PR con `Closes #109`.

T001 → T002/T003 → T004 → T005 → T006/T007 → T008. Prueba independiente: cada rol solo recibe su audiencia y destinatario; duplicar no repite; resolver y volver a crear rearma. El símbolo desactivado produce alerta administrativa.

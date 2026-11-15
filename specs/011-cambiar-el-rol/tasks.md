# Tareas: HU-011 · Cambiar el rol de una cuenta

**Input**: spec.md, plan.md, research.md, data-model.md y contracts/cambiar-rol.md de esta carpeta.
**Organización**: una historia de usuario (US1), conservando CA-1 a CA-5 y FR-032/033/034. Las pruebas son obligatorias por la historia y por CLAUDE.md.

## Fase 1: Preparación

- [x] T001 Contrastar `specs/011-cambiar-el-rol/spec.md` con el issue #28 autenticado como yulbastidas y revisar sus dependencias.
- [x] T002 Generar el diseño en `specs/011-cambiar-el-rol/plan.md`, `research.md`, `data-model.md`, `contracts/cambiar-rol.md` y `quickstart.md`.
- [x] T003 Preparar las herramientas y la base simulada según `README.md`; verificar versiones antes de ejecutar `scripts/verificar.sh`.

## Fase 2: US1 · Cambiar el rol de una cuenta (P1)

- [x] T004 [US1] Agregar `supabase/tests/database/23_cambiar_rol_test.sql`: CA-1/CA-2, cupo en cero, devolución de efectivo, cierre, suma cero y auditoría (FR-033).
- [x] T005 [US1] Ampliar `supabase/tests/database/23_cambiar_rol_test.sql`: posiciones y órdenes vivas, permisos, sesión inválida, cuenta inexistente, acción propia, último administrador y atomicidad (CA-3/4/5, FR-032).
- [x] T006 [US1] Revisar bloqueos y estados vivos de migraciones de cupos/órdenes y agregar `supabase/migrations/20261115120000_cambiar_rol.sql` con RPC transaccional, auditoría y evento privado. Probar autorización por perfil con claims antiguos y proteger concurrencia (FR-032/033).
- [x] T007 [P] [US1] Agregar pruebas del evento de la cuenta actual, renovación fallida y cierre de sesión en `test/core/realtime/actualizacion_de_perfil_test.dart` (FR-034).
- [x] T008 [US1] Integrar la renovación por `perfil_actualizado` mediante `lib/features/auth/data/ingreso_repositorio.dart` y `lib/core/realtime/activador_de_tiempo_real.dart`; reutilizar la sesión y suscripciones existentes sin confiar en la carga para autorizar (FR-034).
- [x] T009 [US1] Agregar `test/app/cambio_de_rol_test.dart`: token nuevo, navegación nueva, redirección de ruta sin permiso y resuscripción de canales (CA-1, FR-034).
- [x] T010 [US1] Extender E2E-05 en `supabase/tests/e2e/05_cambio_de_rol_test.ts`, actualizar el catálogo y comprobar navegación por evento en `test/app/cambio_de_rol_test.dart` y los escenarios existentes de Chrome.

## Fase 3: Cierre

- [x] T011 Actualizar rutas y pruebas en `docs/17-mapa-de-modulos.md`, registrar errores no triviales en `docs/errores-conocidos.md` si corresponde y actualizar el estado real en `specs/011-cambiar-el-rol/tasks.md`.
- [x] T012 Ejecutar `scripts/verificar.sh` completo y revisar el diff sin secretos; completar `specs/011-cambiar-el-rol/quickstart.md` con resultados reales, sin marcar validaciones no ejecutadas.
- [x] T013 Preparar commit y PR de `011-cambiar-el-rol` con la plantilla de `.github/`, identidad yulbastidas y `Closes #28`; comprobar CI antes de integrar.

## Dependencias y ejecución

T001 → T002 → T003 → T004/T005 → T006 → T008 → T009 → T010 → T011 → T012 → T013. T007 puede prepararse con las pruebas SQL porque usa otro archivo; T008 depende de su contrato y de T006.

## Prueba independiente y alcance

US1 se acredita con todos los CA: transición contable válida y auditada, rechazo sin efectos parciales de operaciones inválidas, y nueva navegación al renovar la sesión. No agregar pantalla de HU-098 ni RN-56 de HU-065. No cerrar #28 con solo los documentos. El entregable mínimo es la historia completa validada.

Validación: script completo (sin omitir E2E) aprobado con las cuatro historias juntas el 2026-11-15: [ejecución](https://github.com/riverbonilla1504/NASTOCK/actions/runs/43740991487). PR #201.

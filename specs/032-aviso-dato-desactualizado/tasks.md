# Tareas · HU-032

## Preparación
- [x] T001 Revisar spec.md, docs/17, docs/18 y el flujo de M-05.
- [x] T002 Identificar el parámetro existente en supabase/migrations/20261108120000_catalogo_de_parametros.sql.

## US1 · Aviso y bloqueo de compra
- [x] T003 [US1] Conservar la hora del proveedor en supabase/migrations/20261116190000_momento_por_cotizacion.sql.
- [x] T004 [US1] Calcular vigencia en lib/features/mercado/presentation/frescura_provider.dart.
- [x] T005 [US1] Integrar aviso en lib/features/mercado/presentation/pagina_mercado.dart.
- [x] T006 [US1] Bloquear compra y confirmación en lib/features/ordenes/presentation/botones_de_orden.dart.
- [x] T007 [US1] Escribir pruebas de caducidad y recuperación en test/features/mercado/frescura_test.dart.
- [x] T008 [US1] Extender el contrato en supabase/tests/database/09_ingesta_de_precios_test.sql.
- [ ] T009 [US1] Completar y ejecutar pruebas de formulario y confirmación con reloj controlado.
- [ ] T010 [US1] Extender E2E-03 en integration_test/app_test.dart con ingesta detenida y recuperación.

## Verificación y entrega
- [x] T011 Actualizar docs/09 y docs/17 con el campo m y el proveedor de vigencia.
- [ ] T012 Ejecutar scripts/verificar.sh completo con SDK y dependencias del proyecto.
- [ ] T013 Revisar visualmente en Chrome y Android según DESIGN.md.
- [ ] T014 Crear PR de #51 solo después de la verificación.

Dependencias: T003 → T004 → T005/T006 → T007/T008 → T009/T010 → T012/T013 → T014.
Las pruebas de Postgres y Flutter se pueden ejecutar independientemente.
Las casillas de implementación no certifican pruebas aprobadas.

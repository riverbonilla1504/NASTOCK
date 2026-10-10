# TT-06 · Arnés E2E de backend y de la app

| Campo | Valor |
|---|---|
| Épica | [E-01 · Cimientos y calidad continua](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Prioridad | Alta |
| Módulos afectados | M-20, M-19 |
| Estimación | Por definir al refinar |
| Etiquetas | `tarea-tecnica` · `E-01` · `M-20` · `M-19` · `prioridad-alta` |

## Qué hay que hacer y por qué

Dejar corriendo las dos capas de pruebas de punta a punta con un escenario mínimo cada una: backend (`deno test` contra Supabase local con funciones servidas y proveedores simulados) y app (`integration_test` en Chrome). Cada historia agrega después su escenario del catálogo de 15 §4.

## Documentación fuente

15 §2 · 15 §3 · 15 §4 · 15 §6 · 05 §12

## Requisitos funcionales

Ninguno: este ítem no agrega un requisito funcional del producto.

## Criterio de terminado

- [ ] `supabase/tests/e2e/` tiene utilidades para actuar como distintos usuarios, fijar el reloj y elegir escenarios de los proveedores, y un escenario mínimo en verde.
- [ ] `integration_test/` y `test_driver/` abren la app en Chrome sin ventana con `flutter drive -d web-server` y comprueban la pantalla inicial.
- [ ] `scripts/verificar.sh` completo ejecuta los dos E2E y `--rapido` omite solo el de la app.
- [ ] El trabajo `e2e` de `ci.yml` se activa al existir estas carpetas y termina en verde.
- [ ] `scripts/verificar.sh` completo en verde y CI en verde.

## Tareas

- [ ] `supabase/tests/e2e/`: utilidades de sesión por usuario, de reloj y de escenarios, y un escenario mínimo.
- [ ] `integration_test/app_test.dart` y `test_driver/integration_test.dart` con un escenario mínimo de arranque.
- [ ] `supabase/tests/humo/`: estructura de la prueba de humo que usará el despliegue.
- [ ] Ejecutar `scripts/verificar.sh` completo en local y revisar que cada bloque corre.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-03 · Base de Supabase: esquema private, extensiones, Vault y ping](TT-03-base-de-supabase-esquema-private-extensiones-vault-y-ping.md) | El E2E de backend corre contra Supabase local. |
| Depende de | [TT-04 · Esqueleto de la app Flutter para Android y web](TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) | El E2E de la app necesita la app. |
| Depende de | [TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba](TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) | El E2E usa proveedores simulados y el reloj controlable. |
| Habilita | [TT-07 · Integración continua completa en cada PR](TT-07-integracion-continua-completa-en-cada-pr.md) | TT-07: CI ejecuta el E2E de backend y de la app. |
| Habilita | [HU-002 · Alta solo con invitación vigente](../E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md) | HU-002: agrega el escenario E2E-02. |
| Habilita | [HU-006 · Navegación y guardas según el rol](../E-02-identidad-y-acceso/HU-006-navegacion-y-guardas-segun-el-rol.md) | HU-006: agrega el escenario E2E-01. |
| Habilita | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | HU-015: agrega el escenario E2E-04. |
| Habilita | [HU-030 · Pantalla de mercado en vivo](../E-04-datos-de-mercado/HU-030-pantalla-de-mercado-en-vivo.md) | HU-030: agrega el escenario E2E-03. |
| Habilita | [HU-047 · Puntaje compuesto y elección de la mejor opción](../E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | HU-047: agrega el escenario E2E-07. |
| Habilita | [HU-048 · Pantalla Oportunidades con la explicación de cada evaluación](../E-06-ia-contexto-y-decision/HU-048-pantalla-oportunidades-con-la-explicacion-de-cada-evaluacion.md) | HU-048: agrega el escenario E2E-06. |
| Habilita | [HU-062 · Aprobar una sugerencia de mi cupo](../E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md) | HU-062: agrega el escenario E2E-08. |
| Habilita | [HU-065 · Decidir en Arriesgadas con doble aprobación](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) | HU-065: agrega el escenario E2E-09. |
| Habilita | [HU-066 · Vencimiento por tiempo y aviso previo](../E-07-sugerencias-y-decisiones/HU-066-vencimiento-por-tiempo-y-aviso-previo.md) | HU-066: agrega el escenario E2E-10. |
| Habilita | [HU-069 · Solicitar la liquidación de un cupo](../E-07-sugerencias-y-decisiones/HU-069-solicitar-la-liquidacion-de-un-cupo.md) | HU-069: agrega el escenario E2E-16. |
| Habilita | [HU-075 · Crear una orden manual en mi cupo](../E-08-ejecucion-y-broker/HU-075-crear-una-orden-manual-en-mi-cupo.md) | HU-075: agrega el escenario E2E-11. |
| Habilita | [HU-078 · Protección virtual en compras fraccionales](../E-08-ejecucion-y-broker/HU-078-proteccion-virtual-en-compras-fraccionales.md) | HU-078: agrega el escenario E2E-12. |
| Habilita | [HU-080 · Conciliación completa con pausa automática](../E-08-ejecucion-y-broker/HU-080-conciliacion-completa-con-pausa-automatica.md) | HU-080: agrega el escenario E2E-13. |
| Habilita | [HU-088 · Recibir avisos por push](../E-09-tiempo-real-y-notificaciones/HU-088-recibir-avisos-por-push.md) | HU-088: agrega el escenario E2E-15. |
| Habilita | [HU-108 · Consultar y exportar la bitácora](../E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md) | HU-108: agrega el escenario E2E-14. |

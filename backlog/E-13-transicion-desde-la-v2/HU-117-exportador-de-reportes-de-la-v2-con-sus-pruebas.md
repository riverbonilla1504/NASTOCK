# HU-117 · Exportador de reportes de la v2 con sus pruebas

| Campo | Valor |
|---|---|
| Épica | [E-13 · Transición desde la v2](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Administrador |
| Prioridad | Baja |
| Módulos afectados | M-15 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-13` · `M-15` · `prioridad-baja` |

## Historia

**Como** Administrador,  
**quiero** que el exportador de reportes de la v2 quede disponible con sus pruebas,  
**para** que la exportación CSV parta de código ya probado.

## Requisitos funcionales

- [FR-203 · Exportación CSV](../requisitos-funcionales/FR-203-exportacion-csv.md)

## Reglas

05 §11 · 01 §4

## Criterios de aceptación

- **CA-1** Dado `report_exporter.dart` con su prueba, cuando se copia, entonces queda en `lib/features/reportes/` y su prueba pasa.
- **CA-2** Dado un conjunto de filas, cuando se exporta, entonces el CSV sale con encabezados y con los montos en el formato de la app.
- **CA-3** Dado el exportador, cuando se usa en web y en Android, entonces genera el archivo en las dos plataformas.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Copiar `lib/services/report_exporter.dart` y su prueba desde el repositorio v2.
- [ ] Adaptarlo al formato de dinero y de fechas de `lib/core/`.
- [ ] Correr `flutter test`.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-04 · Esqueleto de la app Flutter para Android y web](../E-01-cimientos-y-calidad-continua/TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) | Se copia dentro del esqueleto de la app. |
| Habilita | [HU-095 · Exportar reportes en CSV](../E-10-cartera-y-reportes/HU-095-exportar-reportes-en-csv.md) | HU-095: usa el exportador copiado de la v2. |
| Habilita | [HU-108 · Consultar y exportar la bitácora](../E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md) | HU-108: exporta con el exportador de la v2. |

## Notas técnicas

Lo usan la exportación de la bitácora ([HU-108](../E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md)) y los reportes CSV ([HU-095](../E-10-cartera-y-reportes/HU-095-exportar-reportes-en-csv.md)).

## Documentación a actualizar

Ninguna.

## Definición de terminado

Lista de `docs/14` §6, la misma del formulario de historia:

- [ ] Criterios de aceptación y casos borde cumplidos
- [ ] `scripts/verificar.sh` completo en verde (incluye E2E) y CI en verde
- [ ] Escenario E2E agregado o actualizado
- [ ] RLS y pruebas pgTAP si toca datos; escrituras solo por RPC
- [ ] `docs/` actualizada (y historial 13 §4) si cambió una regla
- [ ] `docs/17` actualizado si cambiaron rutas, tablas o funciones
- [ ] Error no trivial registrado en `docs/errores-conocidos.md`
- [ ] Desplegada en el proyecto MVP con la prueba de humo en verde

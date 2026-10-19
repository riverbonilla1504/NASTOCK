# HU-108 · Consultar y exportar la bitácora

| Campo | Valor |
|---|---|
| Épica | [E-12 · Seguridad, auditoría y cumplimiento](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-17, M-16 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-12` · `M-17` · `M-16` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** consultar la bitácora con filtros y exportarla,  
**para** revisar lo que pasó y entregarlo cuando me lo pidan.

## Requisitos funcionales

- [FR-221 · Consulta de la bitácora](../requisitos-funcionales/FR-221-consulta-de-la-bitacora.md)
- [FR-218 · Bitácora de acciones sensibles](../requisitos-funcionales/FR-218-bitacora-de-acciones-sensibles.md)

## Reglas

PM-60 · 11 §4.1 · 11 §4.4

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando abre Bitácora, entonces ve los registros con momento, actor, acción y entidad, y puede filtrarlos por persona, acción, entidad y rango de fechas.
- **CA-2** Dado un filtro aplicado, cuando exporta, entonces obtiene un CSV con esos registros.
- **CA-3** Dadas las acciones sensibles de la entrega (invitar, suspender, registrar y confirmar un aporte, asignar un cupo, cambiar un parámetro y encender un interruptor), cuando se ejecutan, entonces cada una aparece en la bitácora y la cadena de hash se verifica completa.
- **CA-4** (permiso) Dado un Usuario o un Analista, cuando abre la pantalla o consulta `auditoria`, entonces no tiene acceso.

## Casos borde

—

## Escenario E2E

E2E-14 (nuevo)

## Tareas

- [ ] App: `lib/features/admin/bitacora/` con los filtros y la exportación CSV.
- [ ] Función que recalcula y verifica la cadena de hash.
- [ ] Pruebas pgTAP de la verificación y pruebas de widget de la pantalla.
- [ ] E2E-14: las acciones sensibles quedan auditadas y la cadena de hash se verifica.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Consulta la tabla `auditoria`. |
| Depende de | [HU-097 · Sección de Administración y guía de primeros pasos](../E-11-administracion/HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) | Es una entrada de la sección de Administración. |
| Depende de | [HU-117 · Exportador de reportes de la v2 con sus pruebas](../E-13-transicion-desde-la-v2/HU-117-exportador-de-reportes-de-la-v2-con-sus-pruebas.md) | Exporta con el exportador de la v2. |
| Depende de | [HU-018 · Asignar y reducir cupos](../E-03-fondo-y-libro-contable/HU-018-asignar-y-reducir-cupos.md) | El escenario audita aportes y cupos. |
| Depende de | [HU-033 · Parámetros configurables con rango e historial](../E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md) | El escenario audita un cambio de parámetro. |
| Depende de | [HU-034 · Encender y apagar los interruptores del fondo](../E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md) | El escenario audita un interruptor. |
| Depende de | [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) | El escenario audita una suspensión. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-14. |
| Habilita | [HU-110 · Verificación semanal de la cadena de hash](HU-110-verificacion-semanal-de-la-cadena-de-hash.md) | HU-110: usa la función que verifica la cadena. |

## Notas técnicas

Sin notas adicionales.

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

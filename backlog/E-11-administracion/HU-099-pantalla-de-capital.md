# HU-099 · Pantalla de capital

| Campo | Valor |
|---|---|
| Épica | [E-11 · Administración](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-16, M-04 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-11` · `M-16` · `M-04` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** registrar aportes y retiros y ver su estado,  
**para** gobernar el capital del fondo desde la app.

## Requisitos funcionales

- [FR-209 · Pantalla de capital](../requisitos-funcionales/FR-209-pantalla-de-capital.md)

## Reglas

PM-40 · PM-41 · PM-45 · 02 §3 · 02 §4 · 04 §8

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando abre Capital, entonces ve la lista de aportes y retiros con su monto, su referencia, su estado, quién lo registró y cuándo.
- **CA-2** Dado el formulario de aporte, cuando lo envía tras la confirmación, entonces el aporte aparece como registrado y pasa a confirmado sin recargar cuando la conciliación lo confirma.
- **CA-3** Dado un aporte registrado, cuando elige anularlo, entonces la app pide el motivo y lo anula; en un aporte confirmado esa opción no está.
- **CA-4** Dado el formulario de retiro, cuando elige la subcuenta de origen, entonces solo puede elegir Reserva, Arriesgadas o la bolsa común, y ve el disponible de cada una.
- **CA-5** (permiso) Dado un Analista, cuando consulta `movimientos_capital`, entonces los ve en solo lectura; un Usuario no recibe filas.
- **CA-6** Dado el formulario de ajuste, cuando lo envía con sus asientos y su justificación tras la confirmación, entonces el ajuste queda registrado.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-04.

## Tareas

- [ ] App: `lib/features/admin/capital/` con la lista y los formularios de aporte, anulación y retiro.
- [ ] App: confirmación con el componente de [HU-009](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) y actualización con el evento `capital`.
- [ ] Pruebas de widget de los formularios y de los mensajes de error.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-097 · Sección de Administración y guía de primeros pasos](HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) | Es una entrada de la sección de Administración. |
| Depende de | [HU-014 · Registrar y anular aportes](../E-03-fondo-y-libro-contable/HU-014-registrar-y-anular-aportes.md) | Registra y anula aportes. |
| Depende de | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | Muestra la confirmación del aporte. |
| Depende de | [HU-016 · Registrar retiros de capital](../E-03-fondo-y-libro-contable/HU-016-registrar-retiros-de-capital.md) | Registra retiros. |
| Depende de | [HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) | Confirma los movimientos de dinero. |
| Depende de | [HU-022 · Registrar ajustes contables](../E-03-fondo-y-libro-contable/HU-022-registrar-ajustes-contables.md) | Registra ajustes. |

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

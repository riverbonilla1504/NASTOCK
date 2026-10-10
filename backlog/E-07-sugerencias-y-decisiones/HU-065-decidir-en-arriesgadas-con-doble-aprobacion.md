# HU-065 · Decidir en Arriesgadas con doble aprobación

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-09 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** aprobar o rechazar las sugerencias de Arriesgadas, con una segunda aprobación de otro Analista cuando el monto es alto,  
**para** que el riesgo mayor del fondo lo validen dos personas distintas.

## Requisitos funcionales

- [FR-147 · Decisión de un Analista sobre Arriesgadas](../requisitos-funcionales/FR-147-decision-de-un-analista-sobre-arriesgadas.md)
- [FR-148 · Doble aprobación](../requisitos-funcionales/FR-148-doble-aprobacion.md)
- [FR-149 · Anulación de la primera aprobación](../requisitos-funcionales/FR-149-anulacion-de-la-primera-aprobacion.md)
- [FR-143 · Retención de fondos al aprobar](../requisitos-funcionales/FR-143-retencion-de-fondos-al-aprobar.md)

## Reglas

PM-21 · RN-52 · RN-53 · RN-56 · RR-13 · 08 §1 · 08 §7.2 · 08 §8 · D-05 · D-20 · D-33

## Criterios de aceptación

- **CA-1** Dada una sugerencia de Arriesgadas sin doble aprobación, cuando un Analista la aprueba, entonces pasa a aprobada, se retienen los fondos y se crea la orden.
- **CA-2** Dada una sugerencia con `requiere_doble`, cuando el Analista A la aprueba, entonces pasa a `pendiente_segunda`, no se retiene nada y los demás Analistas reciben `segunda_aprobacion`.
- **CA-3** (caso borde) CB-24: Dado el Analista A, cuando intenta dar también la segunda aprobación, entonces responde `MISMO_ANALISTA` y su primera decisión no cambia.
- **CA-4** (caso borde) CB-23: Dados dos Analistas que aprueban a la vez, cuando llegan las dos llamadas, entonces una queda como primera y la otra como segunda aprobación.
- **CA-5** (caso borde) CB-26: Dados un Analista que aprueba y otro que rechaza, cuando ocurre, entonces la sugerencia queda rechazada: un rechazo basta.
- **CA-6** (caso borde) CB-10: Dado que cambia el rol o se suspende al Analista que dio la primera aprobación, cuando ocurre, entonces esa decisión queda anulada, la sugerencia vuelve a pendiente y se registra `decision.anulada`.
- **CA-7** (permiso) Dado un Usuario o un Administrador, cuando intenta aprobar una sugerencia de Arriesgadas, entonces recibe `NO_AUTORIZADO`.

## Casos borde

CB-10, CB-23, CB-24, CB-26

## Escenario E2E

E2E-09 (nuevo)

## Tareas

- [ ] RPC `aprobar_sugerencia`: rama de Analista con la primera y la segunda aprobación, RN-52, bloqueo de fila y retención solo en la aprobación final.
- [ ] Migración: anulación de la primera aprobación (RN-56) dentro de `cambiar_rol` y de `private.suspender_cuenta`.
- [ ] Notificación `segunda_aprobacion` a los otros Analistas.
- [ ] App: botones Aprobar y Rechazar en la Bandeja de riesgo con confirmación.
- [ ] Pruebas pgTAP: primera y segunda aprobación, mismo Analista, concurrencia, rechazo y anulación.
- [ ] E2E-09: dos Analistas distintos; el mismo no cuenta dos veces; un rechazo basta.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-064 · Bandeja de riesgo del Analista](HU-064-bandeja-de-riesgo-del-analista.md) | Se decide desde la Bandeja de riesgo. |
| Depende de | [HU-062 · Aprobar una sugerencia de mi cupo](HU-062-aprobar-una-sugerencia-de-mi-cupo.md) | Extiende `aprobar_sugerencia` y usa la retención y la orden. |
| Depende de | [HU-063 · Rechazar una sugerencia con motivo](HU-063-rechazar-una-sugerencia-con-motivo.md) | Usa `rechazar_sugerencia`. |
| Depende de | [HU-011 · Cambiar el rol de una cuenta](../E-02-identidad-y-acceso/HU-011-cambiar-el-rol-de-una-cuenta.md) | Anula la primera aprobación al cambiar el rol. |
| Depende de | [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) | Anula la primera aprobación al suspender. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-09. |
| Habilita | [HU-070 · Aprobar las ventas de liquidación](HU-070-aprobar-las-ventas-de-liquidacion.md) | HU-070: usa la decisión del Analista. |

## Notas técnicas

El Administrador no aprueba compras ni ventas (D-20). Si el segundo Analista se suspende después de una primera aprobación, la sugerencia sigue esperando y vence si nadie más decide (CB-25).

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

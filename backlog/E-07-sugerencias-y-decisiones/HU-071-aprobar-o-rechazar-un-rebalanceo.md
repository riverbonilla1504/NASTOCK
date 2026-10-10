# HU-071 · Aprobar o rechazar un rebalanceo

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-09, M-04 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `M-04` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** aprobar o rechazar el rebalanceo que propone el sistema,  
**para** que el dinero solo se mueva entre bolsillos con mi decisión.

## Requisitos funcionales

- [FR-157 · Decisión de un rebalanceo](../requisitos-funcionales/FR-157-decision-de-un-rebalanceo.md)

## Reglas

PM-43 · RN-34 · RN-36 · RN-37 · 08 §1 · D-08 · D-10

## Criterios de aceptación

- **CA-1** Dada una sugerencia de rebalanceo, cuando el Administrador la aprueba, entonces se registra un movimiento `rebalanceo` con las transferencias propuestas, sin ninguna orden en el broker, y se registra `rebalanceo.aprobado`.
- **CA-2** Dado que el efectivo disponible cambió y ya no alcanza, cuando aprueba, entonces responde `FONDOS_INSUFICIENTES` y la sugerencia sigue pendiente.
- **CA-3** Dado el Administrador, cuando la rechaza con un motivo, entonces pasa a rechazada y se registra `rebalanceo.rechazado`.
- **CA-4** (permiso) Dado un Analista o un Usuario, cuando intenta decidir un rebalanceo, entonces recibe `NO_AUTORIZADO`.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `aprobar_sugerencia` y `rechazar_sugerencia`: rama de rebalanceo con `decide_rol = administrador` y movimiento `rebalanceo` por `private.registrar_movimiento`.
- [ ] Auditoría `rebalanceo.aprobado` y `rebalanceo.rechazado`, evento `rebalanceo` en el canal `admin` y `resumen_cambio`.
- [ ] Notificación `sugerencia_nueva` a los Administradores cuando se propone.
- [ ] Pruebas pgTAP: aprobación, sin efectivo suficiente, rechazo y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-024 · Propuesta de rebalanceo tras el cierre](../E-03-fondo-y-libro-contable/HU-024-propuesta-de-rebalanceo-tras-el-cierre.md) | Decide la propuesta del sistema. |
| Depende de | [HU-062 · Aprobar una sugerencia de mi cupo](HU-062-aprobar-una-sugerencia-de-mi-cupo.md) | Extiende `aprobar_sugerencia`. |
| Depende de | [HU-063 · Rechazar una sugerencia con motivo](HU-063-rechazar-una-sugerencia-con-motivo.md) | Usa `rechazar_sugerencia`. |
| Habilita | [HU-105 · Pantalla de rebalanceos](../E-11-administracion/HU-105-pantalla-de-rebalanceos.md) | HU-105: decide las sugerencias de rebalanceo. |

## Notas técnicas

Es la única forma, además del retiro, de que salga dinero de la Reserva (RN-37). La pantalla está en [HU-105](../E-11-administracion/HU-105-pantalla-de-rebalanceos.md).

## Documentación a actualizar

07 §7.5 fija el vencimiento de compras y de ventas, pero no dice cuánto vive una sugerencia de rebalanceo, que nace después del cierre. Precisarlo en `docs/` antes de implementar.

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

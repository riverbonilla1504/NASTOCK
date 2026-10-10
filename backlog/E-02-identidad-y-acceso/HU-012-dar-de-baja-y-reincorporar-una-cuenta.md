# HU-012 · Dar de baja y reincorporar una cuenta

| Campo | Valor |
|---|---|
| Épica | [E-02 · Identidad y acceso](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-02, M-04 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-02` · `M-02` · `M-04` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** dar de baja a quien se retira de RiTech y reincorporarlo si vuelve,  
**para** cerrar su cupo de forma ordenada sin perder su historial.

## Requisitos funcionales

- [FR-036 · Baja de una cuenta](../requisitos-funcionales/FR-036-baja-de-una-cuenta.md)
- [FR-037 · Reincorporación de una cuenta](../requisitos-funcionales/FR-037-reincorporacion-de-una-cuenta.md)
- [FR-032 · Protección del último administrador y de la acción sobre uno mismo](../requisitos-funcionales/FR-032-proteccion-del-ultimo-administrador-y-de-la-accion-sobre-uno-mismo.md)

## Reglas

PM-53 · RN-40 · RN-50 · RN-51 · RN-57 · 02 §11 · D-31

## Criterios de aceptación

- **CA-1** Dado un cupo sin posiciones ni órdenes vivas, cuando el Administrador da de baja la cuenta, entonces el efectivo restante vuelve a `usuarios_comun` con un movimiento `cierre_cupo`, la subcuenta se cierra, la cuenta queda bloqueada en Auth y se registran `cuenta.baja` y `cupo.cerrado`.
- **CA-2** Dado un cupo con posiciones u órdenes vivas, cuando se intenta la baja, entonces responde `CUPO_CON_POSICIONES`: primero se liquida.
- **CA-3** (caso borde) CB-06: Dada una cuenta de baja, cuando el Administrador la reincorpora, entonces vuelve a activo, se desbloquea en Auth y recibe un cupo nuevo en 0; el cupo anterior sigue cerrado con su historial.
- **CA-4** Dada una cuenta de baja, cuando un Analista o un Administrador consulta sus operaciones, entonces el historial sigue completo.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando intenta la baja o la reincorporación, entonces recibe `NO_AUTORIZADO`; sobre el último Administrador responde `ULTIMO_ADMIN` (CB-09).

## Casos borde

CB-03, CB-06, CB-09

## Escenario E2E

E2E-16 (actualizado)

## Tareas

- [ ] Migración: `private.dar_de_baja` y `private.reincorporar`: cierre del cupo con `private.registrar_movimiento`, cupo nuevo con `private.crear_cupo` y auditoría.
- [ ] Función `admin-usuarios`: acciones de baja y de reincorporación con bloqueo y desbloqueo en Auth y `sesion_revocada`.
- [ ] App: acciones de baja y de reincorporación en la pantalla de usuarios, y oferta de reincorporar al invitar un correo de baja (CB-03).
- [ ] Pruebas pgTAP: baja con cupo vacío, baja con posiciones, reincorporación y permisos.
- [ ] E2E-16 actualizado: baja y reincorporación después de la liquidación.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-010 · Suspender y reactivar una cuenta](HU-010-suspender-y-reactivar-una-cuenta.md) | Extiende la función `admin-usuarios` y el bloqueo en Auth. |
| Depende de | [HU-018 · Asignar y reducir cupos](../E-03-fondo-y-libro-contable/HU-018-asignar-y-reducir-cupos.md) | Mueve el efectivo del cupo a `usuarios_comun`. |
| Depende de | [HU-070 · Aprobar las ventas de liquidación](../E-07-sugerencias-y-decisiones/HU-070-aprobar-las-ventas-de-liquidacion.md) | La baja exige el cupo ya liquidado. |
| Depende de | [HU-098 · Pantalla de usuarios e invitaciones](../E-11-administracion/HU-098-pantalla-de-usuarios-e-invitaciones.md) | Las acciones viven en la pantalla de usuarios. |

## Notas técnicas

Nunca se borra a un empleado que operó: su historial es parte de la contabilidad del fondo (RN-40).

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

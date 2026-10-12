# HU-018 · Asignar y reducir cupos

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-04 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-04` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** asignar dinero de la bolsa común al cupo de un empleado y reducirlo,  
**para** repartir el 25 % de Usuarios entre los empleados.

## Requisitos funcionales

- [FR-050 · Asignación de cupo](../requisitos-funcionales/FR-050-asignacion-de-cupo.md)
- [FR-051 · Reducción de cupo](../requisitos-funcionales/FR-051-reduccion-de-cupo.md)

## Reglas

PM-42 · RN-16 · RN-17 · RN-19 · 02 §5

## Criterios de aceptación

- **CA-1** Dado `usuarios_comun` con 2.500 disponibles, cuando el Administrador asigna 400 a un Usuario, entonces el libro registra usuarios_comun −400 y cupo +400 y se registra `cupo.asignado`.
- **CA-2** (caso borde) CB-14: Dada una asignación mayor al disponible de `usuarios_comun`, cuando se intenta, entonces responde `FONDOS_INSUFICIENTES`.
- **CA-3** (caso borde) CB-16: Dado un cupo con casi todo invertido, cuando el Administrador lo reduce, entonces solo puede hacerlo hasta su disponible; por encima responde `FONDOS_INSUFICIENTES`.
- **CA-4** Dado `cupos.maximo_usd` configurado, cuando una asignación dejaría el cupo por encima de ese máximo, entonces responde `CUPO_SUPERA_MAXIMO`.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando llama `asignar_cupo` o `reducir_cupo`, entonces recibe `NO_AUTORIZADO`.
- **CA-6** Dado un cupo con disponible, cuando el Administrador lo reduce por un monto que no lo supera, entonces el dinero pasa del cupo a `usuarios_comun` y se registra `cupo.reducido`.

## Casos borde

CB-14, CB-16

## Escenario E2E

E2E-04 (actualizado)

## Tareas

- [ ] RPC `asignar_cupo(usuario_id, monto)` y `reducir_cupo(usuario_id, monto)` con los movimientos `asignacion_cupo` y `reduccion_cupo`, auditoría y eventos `cupo` (canal del Usuario) y `resumen_cambio`.
- [ ] Migración: parámetro `cupos.maximo_usd`.
- [ ] Pruebas pgTAP `capital_*`: asignar, reducir, límites y permisos.
- [ ] E2E-04 actualizado: asignación de un cupo después del reparto.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-017 · Cupo al aceptar la invitación](HU-017-cupo-al-aceptar-la-invitacion.md) | Los cupos nacen al aceptar la invitación. |
| Depende de | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | `usuarios_comun` recibe dinero con el aporte confirmado. |
| Habilita | [HU-012 · Dar de baja y reincorporar una cuenta](../E-02-identidad-y-acceso/HU-012-dar-de-baja-y-reincorporar-una-cuenta.md) | HU-012: mueve el efectivo del cupo a `usuarios_comun`. |
| Habilita | [HU-019 · Ver mi cupo](HU-019-ver-mi-cupo.md) | HU-019: muestra el dinero que se asigna al cupo. |
| Habilita | [HU-037 · Motor de políticas: reglas de la propuesta](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) | HU-037: RR-03 a RR-05 usan el disponible y el patrimonio de la subcuenta. |
| Habilita | [HU-059 · Reparto de una señal de Usuarios en sugerencias por cupo](../E-07-sugerencias-y-decisiones/HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) | HU-059: calcula cada sugerencia con el disponible del cupo. |
| Habilita | [HU-100 · Pantalla de cupos](../E-11-administracion/HU-100-pantalla-de-cupos.md) | HU-100: asigna y reduce cupos. |
| Habilita | [HU-108 · Consultar y exportar la bitácora](../E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md) | HU-108: el escenario audita aportes y cupos. |
| Habilita | [HU-109 · Aislamiento verificado por tabla y por función](../E-12-seguridad-auditoria-y-cumplimiento/HU-109-aislamiento-verificado-por-tabla-y-por-funcion.md) | HU-109: prueba el aislamiento entre cupos. |

## Notas técnicas

Reducir un cupo no vende posiciones: para eso está la liquidación ([HU-069](../E-07-sugerencias-y-decisiones/HU-069-solicitar-la-liquidacion-de-un-cupo.md)). La pantalla está en [HU-100](../E-11-administracion/HU-100-pantalla-de-cupos.md).

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

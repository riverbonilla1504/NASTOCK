# HU-100 · Pantalla de cupos

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
**quiero** ver la bolsa común y el cupo de cada empleado y asignar o reducir dinero,  
**para** repartir el bolsillo de Usuarios con la información a la vista.

## Requisitos funcionales

- [FR-210 · Pantalla de cupos](../requisitos-funcionales/FR-210-pantalla-de-cupos.md)

## Reglas

PM-42 · RN-16 · RN-17 · 02 §5

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando abre Cupos, entonces ve el disponible de `usuarios_comun` y cada cupo con su titular, su efectivo, su disponible y su patrimonio.
- **CA-2** Dado un cupo, cuando asigna o reduce un monto tras la confirmación, entonces los saldos se actualizan; si falla, ve el mensaje de `FONDOS_INSUFICIENTES` o de `CUPO_SUPERA_MAXIMO`.
- **CA-3** Dado un cambio de saldos, cuando ocurre, entonces la pantalla se actualiza en vivo.
- **CA-4** (permiso) Dado un Usuario o un Analista, cuando abre esta pantalla, entonces el enrutador lo lleva a `/inicio`.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-04.

## Tareas

- [ ] App: `lib/features/admin/cupos/` con la lista de cupos y los formularios de asignar y reducir.
- [ ] App: confirmación de cada movimiento y actualización con los eventos.
- [ ] Pruebas de widget de la lista, de los formularios y de los mensajes de error.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-097 · Sección de Administración y guía de primeros pasos](HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) | Es una entrada de la sección de Administración. |
| Depende de | [HU-018 · Asignar y reducir cupos](../E-03-fondo-y-libro-contable/HU-018-asignar-y-reducir-cupos.md) | Asigna y reduce cupos. |
| Depende de | [HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) | Confirma los movimientos de dinero. |
| Habilita | [HU-069 · Solicitar la liquidación de un cupo](../E-07-sugerencias-y-decisiones/HU-069-solicitar-la-liquidacion-de-un-cupo.md) | HU-069: la acción vive en la pantalla de cupos. |

## Notas técnicas

La acción de solicitar la liquidación de un cupo se agrega en [HU-069](../E-07-sugerencias-y-decisiones/HU-069-solicitar-la-liquidacion-de-un-cupo.md).

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

# HU-017 · Cupo al aceptar la invitación

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-04, M-01 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-04` · `M-01` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** recibir mi cupo al aceptar la invitación, con el monto inicial que definió el Administrador si la bolsa común lo cubre,  
**para** tener dónde operar desde mi primer ingreso.

## Requisitos funcionales

- [FR-049 · Cupo al aceptar la invitación](../requisitos-funcionales/FR-049-cupo-al-aceptar-la-invitacion.md)

## Reglas

RN-18 · RN-20 · 04 §6 · 02 §11

## Criterios de aceptación

- **CA-1** Dadas una invitación de Usuario con cupo inicial de 400 y `usuarios_comun` con 2.500, cuando la persona ingresa por primera vez, entonces se crea su subcuenta de cupo y se le asignan 400 con un movimiento `asignacion_cupo`.
- **CA-2** (caso borde) CB-15: Dado un cupo inicial que `usuarios_comun` no cubre, cuando la persona ingresa, entonces entra igual con el cupo en 0 y se crea la alerta `cupo_inicial_no_asignado` para el Administrador.
- **CA-3** Dada una invitación de Analista o de Administrador, cuando la persona ingresa, entonces no se crea ningún cupo.
- **CA-4** Dados los Usuarios que ingresaron antes de existir el libro, cuando se aplica la migración, entonces cada uno recibe su cupo en 0.
- **CA-5** (aislamiento) Dado un Usuario, cuando consulta `subcuentas`, entonces solo ve su cupo.

## Casos borde

CB-15

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-04.

## Tareas

- [ ] Migración: `private.crear_cupo(usuario, monto)`: subcuenta de tipo `cupo`, asignación inicial si `usuarios_comun` la cubre y alerta si no.
- [ ] Migración: `private.al_crear_usuario` llama a `crear_cupo` cuando el rol es Usuario, y relleno de cupos en 0 para los Usuarios ya existentes.
- [ ] Migración: índice único de un cupo abierto por persona.
- [ ] Pruebas pgTAP: cupo con monto, cupo sin fondos suficientes, roles sin cupo y lectura solo del propio.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-013 · Libro contable de doble partida](HU-013-libro-contable-de-doble-partida.md) | El cupo es una subcuenta del libro. |
| Depende de | [HU-002 · Alta solo con invitación vigente](../E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md) | Extiende el trigger de alta. |
| Depende de | [HU-085 · Alertas del sistema por audiencia](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) | Crea la alerta `cupo_inicial_no_asignado`. |
| Habilita | [HU-011 · Cambiar el rol de una cuenta](../E-02-identidad-y-acceso/HU-011-cambiar-el-rol-de-una-cuenta.md) | HU-011: usa `private.crear_cupo` y el cierre del cupo. |
| Habilita | [HU-018 · Asignar y reducir cupos](HU-018-asignar-y-reducir-cupos.md) | HU-018: los cupos nacen al aceptar la invitación. |

## Notas técnicas

Si `crear_cupo` no puede asignar el monto, no hace fallar el ingreso (04 §6). Cuando asigna, registra `cupo.asignado`.

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

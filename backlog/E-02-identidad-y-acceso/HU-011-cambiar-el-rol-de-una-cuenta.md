# HU-011 · Cambiar el rol de una cuenta

| Campo | Valor |
|---|---|
| Épica | [E-02 · Identidad y acceso](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-02, M-04 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-02` · `M-02` · `M-04` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** cambiar el rol de una persona,  
**para** que sus permisos sigan a su función real en RiTech.

## Requisitos funcionales

- [FR-033 · Cambio de rol](../requisitos-funcionales/FR-033-cambio-de-rol.md)
- [FR-034 · Navegación actualizada al cambiar el rol](../requisitos-funcionales/FR-034-navegacion-actualizada-al-cambiar-el-rol.md)
- [FR-032 · Protección del último administrador y de la acción sobre uno mismo](../requisitos-funcionales/FR-032-proteccion-del-ultimo-administrador-y-de-la-accion-sobre-uno-mismo.md)

## Reglas

PM-51 · RN-50 · RN-51 · RN-54 · RN-55 · 04 §8 · D-01

## Criterios de aceptación

- **CA-1** Dado un Analista, cuando el Administrador lo cambia a Usuario, entonces se le crea un cupo en 0, se registra `cuenta.rol_cambiado` y su app renueva el token y rearma la navegación al recibir `perfil_actualizado`.
- **CA-2** Dado un Usuario con el cupo sin posiciones ni órdenes vivas, cuando pasa a otro rol, entonces el efectivo de su cupo vuelve a `usuarios_comun` y el cupo se cierra.
- **CA-3** (caso borde) CB-10: Dado un Usuario con posiciones u órdenes vivas, cuando se intenta cambiar su rol, entonces la función responde `CUPO_CON_POSICIONES`.
- **CA-4** (caso borde) CB-09: Dado el último Administrador activo, cuando se intenta cambiar su rol, entonces responde `ULTIMO_ADMIN`; y sobre uno mismo, `AUTO_ACCION`.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando llama `cambiar_rol`, entonces recibe `NO_AUTORIZADO`.

## Casos borde

CB-09, CB-10

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `cambiar_rol(usuario_id, rol)` con RN-50, RN-51, RN-54 y RN-55: movimiento `cierre_cupo` o `private.crear_cupo`, auditoría y evento `perfil_actualizado`.
- [ ] App: al recibir `perfil_actualizado`, forzar la renovación del token y rearmar la navegación.
- [ ] Pruebas pgTAP de cada regla y de cada error.
- [ ] Prueba de widget: la navegación cambia tras `perfil_actualizado`.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-001 · Perfiles, rol actual y lecturas por rol](HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) | Cambia `perfiles.rol`. |
| Depende de | [HU-017 · Cupo al aceptar la invitación](../E-03-fondo-y-libro-contable/HU-017-cupo-al-aceptar-la-invitacion.md) | Usa `private.crear_cupo` y el cierre del cupo. |
| Depende de | [HU-084 · Gestor de tiempo real en la app](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) | La app escucha `perfil_actualizado`. |
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Registra `cuenta.rol_cambiado`. |
| Habilita | [HU-065 · Decidir en Arriesgadas con doble aprobación](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) | HU-065: anula la primera aprobación al cambiar el rol. |
| Habilita | [HU-098 · Pantalla de usuarios e invitaciones](../E-11-administracion/HU-098-pantalla-de-usuarios-e-invitaciones.md) | HU-098: usa `cambiar_rol`. |

## Notas técnicas

RN-56 (anular la primera aprobación del Analista que cambia de rol) se completa en [HU-065](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md), cuando existen las sugerencias. La pantalla está en [HU-098](../E-11-administracion/HU-098-pantalla-de-usuarios-e-invitaciones.md).

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

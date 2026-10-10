# HU-098 · Pantalla de usuarios e invitaciones

| Campo | Valor |
|---|---|
| Épica | [E-11 · Administración](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-16, M-02 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-11` · `M-16` · `M-02` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** ver todas las cuentas y las invitaciones con su estado y actuar sobre ellas,  
**para** gestionar desde una sola pantalla quién usa la plataforma.

## Requisitos funcionales

- [FR-208 · Pantalla de usuarios e invitaciones](../requisitos-funcionales/FR-208-pantalla-de-usuarios-e-invitaciones.md)

## Reglas

PM-50 · PM-51 · PM-52 · 03 §3 · 03 §6

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando abre Usuarios e invitaciones, entonces ve cada cuenta con nombre, correo, rol y estado, y cada invitación con su estado y su vencimiento.
- **CA-2** Dada una cuenta, cuando el Administrador elige suspender, reactivar o cambiar el rol, entonces la app pide confirmación, llama la función correspondiente y muestra el resultado o el mensaje del código de error (`ULTIMO_ADMIN`, `AUTO_ACCION` o `CUPO_CON_POSICIONES`).
- **CA-3** Dado un cambio en una cuenta o en una invitación, cuando ocurre, entonces la lista se actualiza con los eventos `cuenta` e `invitacion` del canal `admin`.
- **CA-4** (permiso) Dado un Analista, cuando consulta `invitaciones` por la API, entonces no recibe filas.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: lista de cuentas e invitaciones en `lib/features/admin/usuarios/` con filtros por rol y por estado.
- [ ] App: acciones de suspender, reactivar y cambiar rol con confirmación, sobre `admin-usuarios` y `cambiar_rol`.
- [ ] Pruebas de widget de la lista, de las acciones y de los mensajes de error.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-097 · Sección de Administración y guía de primeros pasos](HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) | Es una entrada de la sección de Administración. |
| Depende de | [HU-003 · Invitar a una persona y revocar invitaciones](../E-02-identidad-y-acceso/HU-003-invitar-a-una-persona-y-revocar-invitaciones.md) | Incluye el formulario y la lista de invitaciones. |
| Depende de | [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) | Usa la función `admin-usuarios`. |
| Depende de | [HU-011 · Cambiar el rol de una cuenta](../E-02-identidad-y-acceso/HU-011-cambiar-el-rol-de-una-cuenta.md) | Usa `cambiar_rol`. |
| Habilita | [HU-012 · Dar de baja y reincorporar una cuenta](../E-02-identidad-y-acceso/HU-012-dar-de-baja-y-reincorporar-una-cuenta.md) | HU-012: las acciones viven en la pantalla de usuarios. |

## Notas técnicas

Dar de baja y reincorporar se agregan en [HU-012](../E-02-identidad-y-acceso/HU-012-dar-de-baja-y-reincorporar-una-cuenta.md).

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

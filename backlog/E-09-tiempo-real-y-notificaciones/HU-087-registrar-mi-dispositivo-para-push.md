# HU-087 · Registrar mi dispositivo para push

| Campo | Valor |
|---|---|
| Épica | [E-09 · Tiempo real y notificaciones](README.md) |
| Entrega (hito) | R5 · Protegido y avisado |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-14 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-09` · `M-14` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** que mi dispositivo quede registrado para recibir avisos y que se dé de baja cuando cierro sesión,  
**para** recibir push solo en los dispositivos donde tengo la sesión abierta.

## Requisitos funcionales

- [FR-193 · Registro del dispositivo](../requisitos-funcionales/FR-193-registro-del-dispositivo.md)
- [FR-023 · Cierre de sesión](../requisitos-funcionales/FR-023-cierre-de-sesion.md)
- [FR-029 · Suspensión de una cuenta](../requisitos-funcionales/FR-029-suspension-de-una-cuenta.md)

## Reglas

PM-03 · 09 §5.5 · 04 §4.5 · RN-57

## Criterios de aceptación

- **CA-1** Dada una sesión iniciada en Android, cuando la app obtiene el token de FCM, entonces lo registra con `registrar_dispositivo`; cuando FCM lo renueva, lo actualiza.
- **CA-2** Dado un cierre de sesión, cuando ocurre, entonces la app llama `eliminar_dispositivo` y ese dispositivo deja de recibir push.
- **CA-3** Dada una cuenta que se suspende, cuando ocurre, entonces se borran todos sus dispositivos.
- **CA-4** Dado un dispositivo sin uso en 60 días, cuando corre la limpieza, entonces se borra.
- **CA-5** (aislamiento) Dado cualquier rol, cuando consulta `dispositivos`, entonces solo ve los propios.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-15.

## Tareas

- [ ] Migración: tabla `dispositivos` (06 §5.1) con RLS y RPC `registrar_dispositivo(token, plataforma)` y `eliminar_dispositivo(token)`.
- [ ] Migración: borrado de los dispositivos en `private.suspender_cuenta` y limpieza a los 60 días sin uso.
- [ ] App: `lib/core/push/` con `firebase_messaging`: permiso, token, renovación y borrado al cerrar sesión.
- [ ] Pruebas pgTAP y pruebas unitarias del registro.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-005 · Ingresar con Google en Android y web](../E-02-identidad-y-acceso/HU-005-ingresar-con-google-en-android-y-web.md) | Registra el token al iniciar sesión. |
| Depende de | [HU-007 · Cerrar sesión](../E-02-identidad-y-acceso/HU-007-cerrar-sesion.md) | Borra el token al cerrar sesión. |
| Depende de | [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) | Borra los dispositivos al suspender. |
| Depende de | [TT-02 · Cuentas, conexiones y secretos de los servicios externos](../E-01-cimientos-y-calidad-continua/TT-02-cuentas-conexiones-y-secretos-de-los-servicios-externos.md) | Necesita Firebase Cloud Messaging configurado. |
| Habilita | [HU-088 · Recibir avisos por push](HU-088-recibir-avisos-por-push.md) | HU-088: envía a los dispositivos registrados. |

## Notas técnicas

Se permiten varios dispositivos por persona; cada uno registra su token (04 §8). En web, el push es opcional en el MVP (09 §5.2). La baja de una cuenta ([HU-012](../E-02-identidad-y-acceso/HU-012-dar-de-baja-y-reincorporar-una-cuenta.md)) también borra sus dispositivos.

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

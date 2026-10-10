# HU-007 · Cerrar sesión

| Campo | Valor |
|---|---|
| Épica | [E-02 · Identidad y acceso](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Usuario |
| Prioridad | Media |
| Módulos afectados | M-01 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-02` · `M-01` · `prioridad-media` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** cerrar mi sesión,  
**para** que nadie más use la app con mi cuenta en ese dispositivo.

## Requisitos funcionales

- [FR-023 · Cierre de sesión](../requisitos-funcionales/FR-023-cierre-de-sesion.md)

## Reglas

04 §4.5 · 09 §7

## Criterios de aceptación

- **CA-1** Dada una sesión abierta, cuando la persona cierra sesión, entonces la app cancela sus suscripciones de tiempo real y llama `signOut()`, que revoca el refresh token.
- **CA-2** Dado un cierre de sesión en Android, cuando la persona vuelve a entrar, entonces Google le permite elegir cuenta.
- **CA-3** Dado un cierre de sesión, cuando termina, entonces la app queda en `/ingreso` y no conserva en pantalla datos de la sesión anterior.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: acción de cerrar sesión en el menú de perfil: cancelar canales, `supabase.auth.signOut()` y cerrar la sesión de `google_sign_in`.
- [ ] App: limpiar los providers que guardan datos de la sesión.
- [ ] Pruebas de widget del cierre de sesión.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-005 · Ingresar con Google en Android y web](HU-005-ingresar-con-google-en-android-y-web.md) | Cierra la sesión que abre el ingreso. |
| Habilita | [HU-087 · Registrar mi dispositivo para push](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md) | HU-087: borra el token al cerrar sesión. |

## Notas técnicas

El borrado del token de push al cerrar sesión (04 §4.5, paso 2) se agrega en [HU-087](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md).

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

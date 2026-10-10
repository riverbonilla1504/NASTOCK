# HU-005 · Ingresar con Google en Android y web

| Campo | Valor |
|---|---|
| Épica | [E-02 · Identidad y acceso](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-01 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-02` · `M-01` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador invitado,  
**quiero** entrar a la app con mi cuenta de Google de RiTech desde Android o desde el navegador,  
**para** usar la plataforma sin crear ni recordar otra contraseña.

## Requisitos funcionales

- [FR-012 · Inicio de sesión con Google](../requisitos-funcionales/FR-012-inicio-de-sesion-con-google.md)
- [FR-022 · Mensajes de error de ingreso](../requisitos-funcionales/FR-022-mensajes-de-error-de-ingreso.md)

## Reglas

PM-01 · D-12 · 04 §4 · 04 §11

## Criterios de aceptación

- **CA-1** Dada una persona invitada, cuando toca "Entrar con Google" en Android, entonces el ingreso nativo entrega el `id_token` a Supabase y la persona queda en el inicio de su rol.
- **CA-2** Dada una persona invitada, cuando entra desde la web, entonces la redirección OAuth con PKCE preselecciona la cuenta corporativa y vuelve a la app con la sesión iniciada.
- **CA-3** Dada una cuenta suspendida o de baja, cuando intenta ingresar, entonces ve "Tu cuenta está suspendida. Comunícate con el administrador."
- **CA-4** Dado un dispositivo sin conexión, cuando intenta ingresar, entonces ve "No hay conexión. Revisa tu internet e inténtalo de nuevo."; y si cierra la ventana de Google, vuelve a la pantalla de ingreso sin mensaje.

## Casos borde

—

## Escenario E2E

Sin escenario propio: el ingreso con Google no se puede automatizar (04 §1). E2E-01 usa el ingreso con correo del modo pruebas.

## Tareas

- [ ] App: pantalla de ingreso en `lib/features/auth/` con `google_sign_in` en Android (`serverClientId` del cliente Web) y `signInWithOAuth` con PKCE y el parámetro `hd` en web.
- [ ] App: `sesionProvider` sobre el estado de autenticación de `supabase_flutter`.
- [ ] App: los mensajes de 04 §11 para cada fallo; el detalle técnico va al registro y no a la pantalla.
- [ ] App: ingreso con correo solo cuando está definido `MODO_PRUEBAS` (CI), para los usuarios de prueba.
- [ ] Configuración de Supabase: URLs de redirección del dominio web y de `com.ritech.inversiones://login-callback`.
- [ ] Pruebas de widget de la pantalla y de los mensajes de error.
- [ ] Prueba manual de 04 §3, paso 10: la cuenta invitada entra, la no invitada del dominio es rechazada y la cuenta personal de Gmail la rechaza Google.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-04 · Esqueleto de la app Flutter para Android y web](../E-01-cimientos-y-calidad-continua/TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) | La pantalla se construye sobre el esqueleto de la app. |
| Depende de | [TT-02 · Cuentas, conexiones y secretos de los servicios externos](../E-01-cimientos-y-calidad-continua/TT-02-cuentas-conexiones-y-secretos-de-los-servicios-externos.md) | Necesita los clientes OAuth de Google y el proveedor configurado en Supabase. |
| Depende de | [HU-002 · Alta solo con invitación vigente](HU-002-alta-solo-con-invitacion-vigente.md) | El primer ingreso depende del hook y del trigger de alta. |
| Habilita | [HU-006 · Navegación y guardas según el rol](HU-006-navegacion-y-guardas-segun-el-rol.md) | HU-006: necesita una sesión con rol. |
| Habilita | [HU-007 · Cerrar sesión](HU-007-cerrar-sesion.md) | HU-007: cierra la sesión que abre el ingreso. |
| Habilita | [HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles](HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) | HU-009: protege la sesión que abre el ingreso. |
| Habilita | [HU-084 · Gestor de tiempo real en la app](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) | HU-084: abre los canales al iniciar sesión. |
| Habilita | [HU-087 · Registrar mi dispositivo para push](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md) | HU-087: registra el token al iniciar sesión. |
| Habilita | [HU-111 · Avisos de privacidad y de no asesoría](../E-12-seguridad-auditoria-y-cumplimiento/HU-111-avisos-de-privacidad-y-de-no-asesoria.md) | HU-111: el aviso se presenta tras el primer ingreso. |

## Notas técnicas

Sin tablas nuevas. La API de `google_sign_in` cambió en su versión 7: seguir la guía vigente de Supabase (04 §4.4).

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

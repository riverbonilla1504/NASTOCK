# Investigación: HU-005 · Ingresar con Google en Android y web

Sin "NEEDS CLARIFICATION" abiertos. Las decisiones de fondo vienen de `docs/04` y de la decisión del 2026-11-08 (spec); aquí quedan las que se resolvieron al planear.

## R-1 · Ingreso nativo en Android con `google_sign_in` 7

- **Decisión**: `GoogleSignIn.instance.initialize(serverClientId: GOOGLE_WEB_CLIENT_ID)` una sola vez; `authenticate()`; con la cuenta, `authorizationClient.authorizationForScopes(['email','profile']) ?? authorizeScopes([...])`; `supabase.auth.signInWithIdToken(provider: google, idToken, accessToken)`.
- **Razón**: es la guía vigente de Supabase para Flutter (`docs/04` §4.4 remite a ella; EC-018). Pasar el `accessToken` evita el rechazo por `at_hash` cuando el token lo trae. `google_sign_in` 7.2.0 (2025-09-17) exige Flutter 3.29+; el proyecto usa 3.47.
- **Cierre de la ventana**: `GoogleSignInException` con `code == GoogleSignInExceptionCode.canceled` → cancelado, sin mensaje (CA-4). Otras excepciones del paquete → `inesperado`, salvo las de red → `sinConexion`.
- **Alternativas**: `signInWithOAuth` también en Android (abre el navegador; peor experiencia y `docs/04` §4.4 pide el nativo); pasar solo `idToken` (el snippet de `docs/04`; falla si el token trae `at_hash`).
- **Pendiente de la prueba manual**: que `authorizeScopes` no muestre una pantalla de permiso sobrante para `email` y `profile`.

## R-2 · Web con PKCE y sin `hd`

- **Decisión**: `signInWithOAuth(OAuthProvider.google, queryParams: {'prompt': 'select_account'})`, con `redirectTo` omitido en web (vuelve a la URL de la app, que debe estar en las URLs permitidas de Supabase). `supabase_flutter` usa PKCE por omisión y limpia la URL al volver.
- **Razón**: decisión de Javier del 2026-11-08: sin Workspace, `hd` dejaría fuera a todo el equipo. `prompt=select_account` obliga a elegir cuenta cuando hay varias sesiones de Google abiertas.
- **Errores de regreso**: el rechazo del hook en el flujo OAuth vuelve con `error`, `error_code` y `error_description` en la URL; `supabase_flutter` lo emite como error de `onAuthStateChange` (`notifyException`). El repositorio escucha ese flujo de errores.

## R-3 · Cómo reconocer cada fallo

- **Hook "antes de crear usuario"** (HU-002): responde HTTP 403 con el mensaje en el cuerpo y **sin código de error propio** (el E2E-02 comprueba el estado y el texto). La app no puede distinguir los tres rechazos por código: reconoce el mensaje por prefijo y, por pedido del coordinador (HU-004 está cambiando esos textos), **muestra el texto que llega del servidor**; la última columna es el respaldo si el servidor no trae mensaje.

  | Rechazo | Texto viejo del hook (en `main`) | Texto nuevo (decisión) | Prefijo que reconoce la app | Respaldo propio de la app |
  |---|---|---|---|---|
  | Sin invitación vigente | "Tu correo no tiene una invitación vigente. Pídele una al administrador." | igual | `Tu correo no tiene una invitación vigente` | el mismo |
  | Dominio no permitido | "Solo se admiten cuentas corporativas de RiTech." | "Solo se admiten cuentas de Google invitadas." | `Solo se admiten cuentas` | "Solo se admiten cuentas de Google invitadas." |
  | Proveedor no permitido | "Solo puedes ingresar con tu cuenta de Google de RiTech." | "Solo puedes ingresar con tu cuenta de Google." | `Solo puedes ingresar con tu cuenta de Google` | "Solo puedes ingresar con tu cuenta de Google." |

- **Cuenta suspendida o de baja**: Auth bloquea al usuario (`ban`, `docs/04` §10) y responde con código `user_banned` (en el ingreso nativo y con correo). En el flujo web llega como error de URL con `error_code=user_banned`; se reconoce también por la palabra "banned" del mensaje.
- **Sin conexión**: `AuthRetryableFetchException`, `SocketException`, `ClientException` (web) y `TimeoutException`.
- **Todo lo demás**: `inesperado` con "No pudimos iniciar tu sesión. Inténtalo de nuevo."; el detalle va al registro técnico (`dart:developer` `log`), nunca a la pantalla (CA-6).

## R-4 · Sesión en almacenamiento seguro

- **Decisión**: `AlmacenamientoSeguroDeSesion extends LocalStorage` (`initialize`, `hasAccessToken`, `accessToken`, `removePersistedSession`, `persistSession`) sobre `FlutterSecureStorage`, con la clave `supabase.auth.token`; se pasa en `FlutterAuthClientOptions(localStorage:)` solo si `!kIsWeb`.
- **Razón**: `docs/04` §8 y FR-026. En web se deja el almacenamiento por omisión del navegador (inevitable, mitigado por el JWT de 15 min).
- **Versión**: `flutter_secure_storage` 11.2.0 (2026-09-16). En Android usa EncryptedSharedPreferences/Keystore sin configuración extra; `minSdk` del proyecto es el de Flutter.

## R-5 · Guarda del enrutador

- **Decisión**: `redirect` de `go_router` que lee `sesionProvider`; `refreshListenable` conectado al mismo proveedor para que el ingreso y el cierre de sesión redirijan solos. Solo `sin sesión → /ingreso` y `con sesión en /ingreso → /inicio`; el resto de las guardas de `docs/05` §9.3 es de HU-006.
- **Alternativa**: un `ShellRoute` con la lógica en la pantalla; rechazada porque HU-006 necesita guardas por ruta y mezclarlo aquí obligaría a rehacerlo.

## R-6 · Componente de confirmación (FR-028)

- **Decisión**: `DialogoDeConfirmacion` y la función `confirmarAccion(...)`; un controlador con los estados de `docs/08` §9.3 (`inactivo`, `confirmando`, `enviando`, `hecho`, `cancelado`, `error`). El diálogo repite **monto y símbolo**, el botón de confirmar pasa a "Procesando…" mientras se envía (`BotonPrimario(enviando:)`) y el error se muestra con `AvisoEnLinea.deError`. Sin biometría (D-61).
- **Razón**: lo usarán HU-075, HU-099 y HU-100; se construye una vez, sin reglas de negocio de ninguna de ellas. La entrada de `DESIGN.md` y del catálogo es parte del trabajo (docs/15 §12).

## R-7 · Qué queda como paso manual

La nube no se configura desde el repositorio (`despliegue.yml` no hace `config push`): usuarios de prueba de Google, `Site URL` y URLs de redirección de Supabase, orígenes JavaScript autorizados del cliente Web, el cliente Android con el SHA-1 de cada llave de firma y la variable `GOOGLE_WEB_CLIENT_ID`. El detalle va en "Pasos manuales" del relevo.

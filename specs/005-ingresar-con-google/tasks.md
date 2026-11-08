---
description: "Tareas de HU-005 · Ingresar con Google en Android y web"
---

# Tareas: HU-005 · Ingresar con Google en Android y web

**Entrada**: [plan.md](plan.md), [spec.md](spec.md), [data-model.md](data-model.md), [contracts/interfaces-de-la-app.md](contracts/interfaces-de-la-app.md), [research.md](research.md).

Una sola historia de usuario (US1). Cada fase es una capa con sus pruebas y termina en un commit. Sin `hd`: la decisión del 2026-11-08 lo quita (spec, "Ajustes por la decisión").

## Fase 1 · Preparación (commit 1)

- [ ] T001 Agrega `google_sign_in` ^7.2.0 y `flutter_secure_storage` ^11.2.0 a `pubspec.yaml` y corre `flutter pub get` (actualiza `pubspec.lock`)
- [ ] T002 [P] `lib/core/configuracion/entorno.dart`: campo `googleWebClientId` (`String.fromEnvironment('GOOGLE_WEB_CLIENT_ID')`, vacío si falta) y `googleConfigurado`; ampliar `test/core/configuracion/entorno_test.dart`

## Fase 2 · Base en `core/` (commit 2)

- [ ] T003 [P] [US1] `lib/core/supabase/almacenamiento_seguro.dart`: `AlmacenamientoSeguroDeSesion extends LocalStorage` sobre `FlutterSecureStorage` (clave `supabase.auth.token`); `lib/core/supabase/cliente_supabase.dart`: `iniciarSupabase` lo pasa en `FlutterAuthClientOptions(localStorage:)` solo si `!kIsWeb` (FR-026, `docs/04` §8); `test/core/supabase/almacenamiento_seguro_test.dart` con un almacén falso en memoria
- [ ] T004 [P] [US1] `lib/core/errores/fallo_de_ingreso.dart`: `TipoDeFalloDeIngreso` y `FalloDeIngreso` con los textos de `data-model.md` (sin "corporativa" ni "de RiTech"); `traducirError` reconoce `FalloDeIngreso`; `test/core/errores/fallo_de_ingreso_test.dart` y ampliar `traduccion_de_errores_test.dart` (FR-022)

## Fase 3 · Piezas del sistema de diseño (commit 3)

- [ ] T005 [P] [US1] `lib/shared/widgets/campo.dart`: parámetro `oculto` (contraseña) y `accion` del teclado; ampliar `test/shared/widgets/campo_test.dart`
- [ ] T006 [US1] `lib/shared/widgets/dialogo_de_confirmacion.dart`: `DialogoDeConfirmacion` y `confirmarAccion` con los estados de `docs/08` §9.3 (inactivo, confirmando, enviando, hecho, cancelado, error), repitiendo monto y símbolo, "Procesando…" mientras envía, error con `AvisoEnLinea.deError`, sin biometría (FR-028, D-61); `test/shared/widgets/dialogo_de_confirmacion_test.dart` (los seis estados, claro y oscuro)

## Fase 4 · Datos de `features/auth/` (commit 4)

- [ ] T007 [P] [US1] `lib/features/auth/data/clasificador_de_fallos.dart`: excepción de Auth o de red → `FalloDeIngreso` (`user_banned` → `cuentaSuspendida`; `AuthRetryableFetchException`, `SocketException`, `ClientException`, `TimeoutException` → `sinConexion`; mensaje del hook por prefijo, textos viejos y nuevos, → `sinInvitacion`, `dominioNoPermitido`, `proveedorNoPermitido`; lo demás → `inesperado`, con el detalle al registro técnico y no a la pantalla); `test/features/auth/data/clasificador_de_fallos_test.dart` (CA-3, CA-4, CA-5, CA-6)
- [ ] T008 [P] [US1] `lib/features/auth/data/google_nativo.dart`: `ProveedorDeGoogleNativo` sobre `GoogleSignIn.instance` de la versión 7 (`initialize` una sola vez con `serverClientId`, `authenticate`, autorización de `email` y `profile`; `GoogleSignInExceptionCode.canceled` → `GoogleCanceladoException`)
- [ ] T009 [US1] `lib/features/auth/data/ingreso_repositorio.dart` y `lib/features/auth/domain/resultado_de_ingreso.dart`: `ingresarConGoogle` (Android: `signInWithIdToken` con `idToken` y `accessToken`; web: `signInWithOAuth` con PKCE y `prompt=select_account`, **sin `hd`**), `ingresarConCorreo` (`signInWithPassword`), `fallosDeRegreso` (errores del flujo OAuth web), `cerrarSesionDeGoogle`; `test/features/auth/data/ingreso_repositorio_test.dart` con falsos de Supabase y de Google (CA-1, CA-2, CA-4)

## Fase 5 · Sesión y pantalla de ingreso (commit 5)

- [ ] T010 [US1] `/impeccable shape` de la pantalla de ingreso (a partir de la historia y de `DESIGN.md`); el brief queda en el relevo
- [ ] T011 [US1] `lib/features/auth/presentation/sesion_provider.dart`: `sesionProvider` sobre `onAuthStateChange` (con la sesión inicial; sin Supabase configurado, sin sesión); `test/features/auth/presentation/sesion_provider_test.dart`
- [ ] T012 [US1] `lib/features/auth/presentation/ingreso_controlador.dart`: estados inactivo, ingresando y fallo; cancelar vuelve a inactivo sin mensaje; los fallos del repositorio y los de regreso pasan por `traducirError`; `test/features/auth/presentation/ingreso_controlador_test.dart`
- [ ] T013 [US1] `lib/features/auth/presentation/pagina_de_ingreso.dart`: pantalla con "Entrar con Google" (botón primario), aviso de error en línea, aviso de configuración que falta, formulario de correo y contraseña **solo** con `MODO_PRUEBAS`; solo tokens de `lib/app/tema.dart` y componentes de `lib/shared/widgets/`; `test/features/auth/presentation/pagina_de_ingreso_test.dart` (inactivo, ingresando, cada fallo con su texto exacto, cancelado sin mensaje, sin configuración, correo oculto sin `MODO_PRUEBAS`, escala de texto grande, claro y oscuro)
- [ ] T014 [US1] `/impeccable audit` y `/impeccable polish` de la pantalla, revisándola en Chrome (y en el emulador de Android si la memoria lo permite); lo hallado se corrige aquí; el par de colores nuevo, si lo hay, a `test/app/tema_test.dart`

## Fase 6 · Enrutador y E2E de la app (commit 6)

- [ ] T015 [US1] `lib/app/enrutador.dart`: `Rutas.ingreso`, `redirect` por `sesionProvider` (sin sesión → `/ingreso`; con sesión en `/ingreso` → `/inicio`; el catálogo queda fuera de la guarda) y `refreshListenable`; `test/app/enrutador_test.dart`. Las guardas por estado y rol son de HU-006
- [ ] T016 [US1] Actualiza `test/app/aplicacion_test.dart` y `test/app/catalogo_test.dart` al nuevo comportamiento (sin sesión abre en `/ingreso`; con sesión, en `/inicio`) sin relajar ninguna comprobación
- [ ] T017 [US1] `integration_test/app_test.dart`: abre en la pantalla de ingreso conectada al backend, ingresa con un usuario de la semilla por correo y llega a la pantalla de inicio (la prueba de humo de TT-04 adaptada; E2E-01 es de HU-006)

## Fase 7 · Cierre (commit 7)

- [ ] T018 [P] `DESIGN.md`: entradas del diálogo de confirmación y de la pantalla de ingreso (textos incluidos); `lib/app/catalogo/pagina_componentes.dart`: entradas del diálogo y del campo de contraseña
- [ ] T019 [P] `docs/17`: M-01 (`lib/features/auth/`, `lib/core/supabase/almacenamiento_seguro.dart`, `lib/core/errores/fallo_de_ingreso.dart`, pruebas de la app) y la ruta `/ingreso`; sin tocar las secciones de `docs/` que cambia HU-004
- [ ] T020 Tras `git fetch origin && git rebase origin/main`, `scripts/verificar.sh` completo en verde (con el candado de Supabase local)
- [ ] T021 Cuerpo del PR (`.github/pull_request_template.md`, "Closes #22") y relevo con "Pasos manuales" en `C:\Users\Javier\Desktop\Nastock.md\`; prueba manual de `docs/04` §3, paso 10, queda para Javier (necesita cuentas de Google reales)

## Dependencias

T001 → T003, T004, T008 (usan los paquetes). T002 → T008, T009. T004 → T007, T009, T012. T005 → T013. T006 es independiente de las demás. T007, T008 → T009. T009 → T012 → T013 → T015 → T017. T010 → T013. T014 sigue a T013. T018 y T019 siguen a T017. T020 sigue a todas.

Paralelizables: T002 con T001; T003, T004, T005 entre sí; T007 con T008; T018 con T019.

## Estrategia

Todo es parte de US1; el orden de capas deja el sistema compilando y las pruebas en verde en cada commit. Primero lo que no depende de nada (T001 a T006), luego la forma de la pantalla (T010) antes de construirla (T013). El E2E de la app (T017) y `verificar.sh` completo (T020) son la salida.

# Plan de implementación: HU-005 · Ingresar con Google en Android y web

**Rama**: `005-ingresar-con-google` | **Fecha**: 2026-11-08 | **Especificación**: [spec.md](spec.md)

## Resumen

La persona invitada entra con su cuenta de Google: en Android con ingreso nativo (`google_sign_in` 7, `serverClientId` del cliente Web) que entrega el `id_token` a Supabase, y en web con `signInWithOAuth` con PKCE, **sin `hd`** (decisión del 2026-11-08: Gmail personal, ver spec). Cada fallo muestra el texto de `docs/04` §11 y nunca el detalle técnico. Sin migraciones, tablas ni Edge Functions: es una historia **solo de la app**, por capas y cada una con sus pruebas: (1) `core/`: sesión en almacenamiento seguro (`LocalStorage` sobre `flutter_secure_storage`) y `GOOGLE_WEB_CLIENT_ID` en `Entorno`; (2) `core/errores/`: `FalloDeIngreso` con sus textos, reconocido por `traducirError`; (3) `features/auth/`: repositorio de ingreso, `sesionProvider`, controlador y pantalla de ingreso (con el ingreso por correo solo si `MODO_PRUEBAS`); (4) `app/enrutador.dart`: la guarda "sin sesión → `/ingreso`"; (5) `shared/widgets/`: el componente común de confirmación (solo diálogo, estados de `docs/08` §9.3) y el campo de contraseña; (6) el E2E de la app existente pasa por el ingreso con correo del modo pruebas.

## Contexto técnico

**Lenguaje/Versión**: Dart 3.13 / Flutter 3.47 (`pubspec.yaml`: `sdk: ^3.13.7`).

**Dependencias nuevas**: `google_sign_in` ^7.2.0 (API de la versión 7: `GoogleSignIn.instance`, `initialize`, `authenticate`; EC-018) y `flutter_secure_storage` ^11.2.0 (Keychain/Keystore; solo en móvil, `docs/04` §8). Ambas gratis y ya nombradas en `docs/05` §3.1; ninguna agrega un servicio ni un plan de pago. Sin `mocktail`: las pruebas usan falsos escritos a mano, como las de `core/perfil/`.

**Almacenamiento**: la sesión de `supabase_flutter` (móvil: almacenamiento seguro del sistema; web: el del navegador). Sin datos nuevos en la base.

**Pruebas**: `flutter test` (widget y unitarias, junto a las existentes en `test/`) y el E2E de la app (`integration_test/app_test.dart`, `flutter drive` en Chrome) con el ingreso por correo del modo pruebas. **No** se automatiza el ingreso con Google (`docs/04` §1); se prueba a mano (`docs/04` §3, paso 10).

**Plataforma**: Android (APK) y web. iOS fuera del MVP (`docs/05` §3.1).

**Restricciones**: la persona nunca ve texto crudo de una excepción (`traducirError`, `DESIGN.md`); ninguna llave en la app (el ID del cliente Web **no** es secreto y viaja por `--dart-define=GOOGLE_WEB_CLIENT_ID`, que `despliegue.yml` ya pasa); correo + contraseña solo con `MODO_PRUEBAS` (CI y local).

**Alcance**: dos pantallas nuevas (ingreso y el diálogo de confirmación como componente), una guarda, dos paquetes. Sin biometría (FR-027 no se construye, D-61).

## Revisión de la constitución

Cumple `CLAUDE.md`:

- Sin escrituras a la base ni RPC nuevas; la autorización sigue leyendo `perfiles` (el hook de token solo da claims para la interfaz).
- Ninguna llave en la app: la llave publicable y el ID del cliente Web no son secretos; la llave secreta no aparece (`verificar.sh` lo comprueba).
- El ingreso con correo solo existe con `MODO_PRUEBAS` y, aun si se activara en la nube, el hook lo rechaza (`auth.proveedores_permitidos = ["google"]`).
- Pantallas con los tokens de `lib/app/tema.dart` y los componentes de `lib/shared/widgets/` (D-67); lo que falta (campo de contraseña, diálogo de confirmación) se agrega al sistema con su prueba y su entrada en `DESIGN.md`.
- Los cambios de `docs/` que trae la decisión del 2026-11-08 son de HU-004; esta historia no edita `docs/04`, `docs/11` ni `docs/13`.

Reevaluada tras el diseño: sin violaciones.

## Alcance frente a HU-006 y HU-007

| Pieza | Dueño | Aquí |
|---|---|---|
| Pantalla de ingreso, `sesionProvider`, mensajes de §11, correo del modo pruebas | HU-005 | Sí |
| Guarda "sin sesión → `/ingreso`" y "con sesión en `/ingreso` → `/inicio`" | HU-005 (sin ella el ingreso no tiene a dónde volver) | Sí, solo esa |
| `/cuenta-suspendida`, guardas por rol (`/admin/*`, `/riesgo/*`), menú por rol, E2E-01 | HU-006 (su CA-3 y sus tareas) | No |
| Cerrar sesión (`signOut` y cierre de `google_sign_in`) | HU-007 | No; el repositorio deja `cerrarSesionDeGoogle()` para que HU-007 lo llame |
| Registro de dispositivo, canales de Realtime al iniciar sesión | HU-087, HU-084 | No |

CA-3 en esta historia: Supabase responde "usuario bloqueado" (`user_banned`) al ingreso y la pantalla de ingreso muestra el mensaje. La pantalla `/cuenta-suspendida` (para quien ya tiene un token vigente y pasa a `app_estado ≠ activo`) es de HU-006.

## Decisiones de diseño

- **El texto lo pone la app.** El repositorio traduce toda excepción de ingreso a un `FalloDeIngreso` (`sinInvitacion`, `dominioNoPermitido`, `proveedorNoPermitido`, `cuentaSuspendida`, `sinConexion`, `inesperado`) con el texto de `docs/04` §11 ajustado por la decisión. La clasificación mira el código de error de Auth (`user_banned`), el tipo de excepción (red: `AuthRetryableFetchException`, `SocketException`, `ClientException`) y, para los rechazos del hook, el mensaje que trae (el hook no pone código). El reconocimiento del mensaje del hook es **tolerante**: acepta los textos viejos y los nuevos, porque el cambio de texto del hook (migración) no es de esta historia. Lo desconocido es `inesperado` y el detalle va a `debugPrint`/`logging`, no a la pantalla (CA-6).
- **Cerrar la ventana de Google no es un fallo.** `GoogleSignInException(canceled)` en Android y el regreso a la pantalla sin sesión en web devuelven `ResultadoDeIngreso.cancelado`: la pantalla vuelve a "inactivo" sin mensaje (CA-4). Sin conexión: el ingreso nativo falla antes de Supabase (`GoogleSignInException` de red) o `signInWithIdToken` lanza error de red; ambos son `sinConexion`.
- **`id_token` y `accessToken`.** Se sigue la guía vigente de Supabase (04 §4.4 la remite): tras `authenticate()` se pide la autorización de `email` y `profile` y se pasan `idToken` y `accessToken` a `signInWithIdToken`; así funciona con o sin `at_hash` en el token. Si la prueba manual muestra una pantalla de permiso sobrante, se evalúa quitar el `accessToken` (nota en el relevo).
- **Web: errores de regreso.** Un rechazo del hook en el flujo OAuth vuelve a la app con el error en la URL y `supabase_flutter` lo emite como error del flujo `onAuthStateChange`. El repositorio expone ese flujo de errores y el controlador lo traduce al mismo `FalloDeIngreso`. Al volver, la URL se limpia (lo hace `supabase_flutter`).
- **`sesionProvider`** es un `StreamProvider<Session?>` sobre `onAuthStateChange` (con la sesión inicial). El enrutador lo escucha con un `refreshListenable` y redirige. Sin Supabase configurado (la app abre igual y avisa) no hay sesión y el enrutador lleva a `/ingreso`, que repite el aviso de configuración.
- **El catálogo de componentes** (`/catalogo`, solo debug o `MODO_PRUEBAS`) queda fuera de la guarda: es una herramienta, no una pantalla de la app.
- **Almacenamiento seguro** solo en móvil: `kIsWeb` usa el de `supabase_flutter` por omisión. `AlmacenamientoSeguroDeSesion` recibe un `FlutterSecureStorage` por constructor para probarlo con un falso en memoria.
- **Textos de la pantalla** que no están en `docs/`: título, ayuda, botón y nota de "Solo cuentas invitadas". Son decisión visual y de tono (D-67), salen de `/impeccable shape` y se anotan en `DESIGN.md`; ninguno habla de "corporativa" ni "de RiTech".
- **E2E de la app.** `integration_test/app_test.dart` hoy asume que la app abre en la pantalla inicial. Con la guarda abre en `/ingreso`; el escenario pasa a: abrir → pantalla de ingreso conectada al backend → ingresar con el correo del modo pruebas (usuario de la semilla) → pantalla de inicio. No es E2E-01 (de HU-006); es la misma prueba de humo adaptada, y deja listo el ingreso por correo que E2E-01 reutiliza.
- **Configuración de Supabase (nube):** `despliegue.yml` solo hace `supabase db push`, no `config push`; por eso `Site URL`, URLs de redirección y los clientes de Google son **pasos manuales de Javier** (relevo). `supabase/config.toml` local no cambia: Google no corre en local y reiniciar el stack compartido no se justifica.

## Estructura del código

### Documentación de esta funcionalidad

```text
specs/005-ingresar-con-google/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── interfaces-de-la-app.md
└── tasks.md            # /speckit-tasks
```

### Código

```text
lib/
├── app/
│   ├── enrutador.dart                  # + Rutas.ingreso, guarda por sesión, refreshListenable
│   ├── aplicacion.dart                 # (sin cambios de comportamiento)
│   └── catalogo/pagina_componentes.dart # + entradas: diálogo de confirmación y campo de contraseña
├── core/
│   ├── configuracion/entorno.dart      # + googleWebClientId (GOOGLE_WEB_CLIENT_ID)
│   ├── errores/
│   │   ├── fallo_de_ingreso.dart       # tipos de fallo y sus textos (04 §11)
│   │   └── traduccion_de_errores.dart  # reconoce FalloDeIngreso
│   └── supabase/
│       ├── almacenamiento_seguro.dart  # LocalStorage sobre flutter_secure_storage
│       └── cliente_supabase.dart       # iniciarSupabase usa el almacenamiento seguro en móvil
├── features/auth/
│   ├── data/
│   │   ├── ingreso_repositorio.dart    # interfaz + implementación Supabase
│   │   ├── google_nativo.dart          # envoltura de GoogleSignIn.instance (probable con falsos)
│   │   └── clasificador_de_fallos.dart # excepción de Auth/red → FalloDeIngreso
│   ├── domain/
│   │   └── resultado_de_ingreso.dart   # exito | cancelado
│   └── presentation/
│       ├── sesion_provider.dart        # sesionProvider
│       ├── ingreso_controlador.dart    # estado: inactivo | ingresando | fallo
│       └── pagina_de_ingreso.dart      # pantalla de ingreso
└── shared/widgets/
    ├── campo.dart                      # + parámetro `oculto` (contraseña)
    └── dialogo_de_confirmacion.dart    # componente común de confirmación (FR-028)

test/
├── app/enrutador_test.dart             # guarda por sesión
├── core/errores/fallo_de_ingreso_test.dart
├── core/supabase/almacenamiento_seguro_test.dart
├── features/auth/…                     # clasificador, repositorio, controlador, pantalla, sesión
└── shared/widgets/dialogo_de_confirmacion_test.dart, campo_test.dart (ampliada)
integration_test/app_test.dart          # ingreso con correo del modo pruebas
```

**Decisión de estructura**: la de `docs/05` §9.1 (`data/` · `domain/` · `presentation/`). Los errores de ingreso viven en `core/errores/` porque `traducirError` (en `core/`) los reconoce y `core/` no importa de `features/`.

## Seguimiento de complejidad

Sin violaciones que justificar.

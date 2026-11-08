# Guía de validación: HU-005 · Ingresar con Google en Android y web

Cómo comprobar que la historia funciona de punta a punta. Los detalles de interfaz están en [contracts/interfaces-de-la-app.md](contracts/interfaces-de-la-app.md) y los textos en [data-model.md](data-model.md).

## 1. Automático (sin Google)

Con el candado de Supabase local tomado (ver el relevo):

```bash
scripts/verificar.sh --rapido     # analiza y prueba la app y el backend; para iterar
scripts/verificar.sh              # completo, incluye el E2E de la app en Chrome (obligatorio al terminar)
```

Esperado:

- Pruebas de widget de la pantalla de ingreso (inactivo, ingresando, cada fallo, cancelado, sin configuración, ingreso con correo solo con `MODO_PRUEBAS`), del clasificador de fallos, del repositorio, del almacenamiento seguro y de la guarda del enrutador.
- Pruebas del diálogo de confirmación (los seis estados de `docs/08` §9.3, monto y símbolo repetidos, "Procesando…").
- E2E de la app: abre en `/ingreso` conectado al backend, ingresa con un usuario de la semilla por correo y llega a la pantalla de inicio.

## 2. Manual con Google (`docs/04` §3, paso 10)

Requiere los pasos manuales del relevo hechos (cliente Web y Android de Google Cloud, usuarios de prueba, URLs de Supabase). Con tres cuentas de Gmail:

| Cuenta | Android | Web | Esperado |
|---|---|---|---|
| Invitada y en la lista de usuarios de prueba | ✔ | ✔ | Entra y queda en la pantalla de inicio (CA-1, CA-2) |
| En la lista de usuarios de prueba pero **sin invitación vigente** | ✔ | ✔ | "Tu correo no tiene una invitación vigente. Pídele una al administrador." (CA-5) |
| Fuera de la lista de usuarios de prueba | ✔ | ✔ | Google la rechaza ("acceso bloqueado"); no llega a la app (CA-7) |

Además: sin conexión → "No hay conexión. Revisa tu internet e inténtalo de nuevo." (CA-4); cerrar la ventana de Google → vuelve a la pantalla de ingreso sin mensaje (CA-4); una cuenta suspendida de prueba → "Tu cuenta está suspendida. Comunícate con el administrador." (CA-3); en Android, cerrar y abrir la app conserva la sesión (FR-026).

Lanzar la app a mano: `flutter run -d chrome --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_PUBLISHABLE_KEY=… --dart-define=GOOGLE_WEB_CLIENT_ID=…` (valores del proyecto MVP; no se escriben en el repositorio).

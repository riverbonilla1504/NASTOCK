# Plan: HU-007 · Cerrar sesión

**Rama**: `007-cerrar-sesion` (#172) · **Módulos**: M-01, M-16 · **Fuentes**: `docs/04` §8.

- **App**: `lib/features/auth/presentation/menu_de_cuenta.dart` (hoja de cuenta con correo y rol, y confirmación antes de cerrar) y `cierre_de_sesion.dart` (cierra los canales de tiempo real, llama `signOut` de Supabase y cierra `google_sign_in`).
- **Raíz de Riverpod** (`lib/app/raiz_de_providers.dart`): se reinicia entera al cerrar sesión para no conservar datos de la sesión anterior (CA-3).
- **Navegación** (`lib/app/cascaron_de_navegacion.dart`): ítem "Salir" al final de la isla en teléfono y al pie del riel en ventanas anchas; nunca queda como pestaña actual.

Decisiones sin regla explícita en `docs/`:
- El borrado del token de push queda para HU-087 (push fuera del MVP, D-62).

Pruebas: `flutter test test/features/auth/presentation/menu_de_cuenta_test.dart` (14) y `test/app/cascaron_de_navegacion_test.dart`.

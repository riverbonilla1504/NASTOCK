# Cómo comprobar HU-116

## 1. Pruebas de la app (CA-6 a CA-10 y CA-12)

```bash
flutter analyze
flutter test
```

Esperado: sin advertencias. Pasan las pruebas de `test/shared/widgets/`, `test/app/` y `test/core/formato/`, incluidas las de `MensajeDeError` y de la app de TT-04.

## 2. Catálogo en Chrome (CA-10, CA-11)

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_PUBLISHABLE_KEY=llave-local
```

Abrir `/#/catalogo`, o el enlace "Catálogo de componentes" de la pantalla de inicio, que solo aparece en debug. Esperado: todos los componentes en claro y, con el interruptor de la barra, en oscuro.

## 3. Catálogo en el emulador Android (CA-11)

```bash
flutter run -d emulator-5554
```

Esperado: lo mismo que en Chrome. Capturar con `adb exec-out screencap -p > catalogo.png`, también en oscuro (`adb shell cmd uimode night yes`) y con texto grande (`adb shell settings put system font_scale 1.3`). Restaurar ambos ajustes al terminar.

## 4. Sin el catálogo (CA-10)

En una compilación sin debug y sin `MODO_PRUEBAS` (`flutter build web --release`), `/#/catalogo` no tiene pantalla.

## 5. Todo

Con el candado del stack compartido tomado (`mkdir C:/Users/Javier/.nastock-supabase-candado`, y `rmdir` al terminar):

```bash
scripts/verificar.sh
```

Esperado: verde.

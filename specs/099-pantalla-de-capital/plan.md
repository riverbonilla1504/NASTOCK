# Plan de implementación: HU-099 · Pantalla de capital

**Rama**: `099-pantalla-de-capital` (apilada sobre `097-seccion-de-administracion`) · **Spec**: [spec.md](spec.md) · **Módulos**: M-04 y M-16 (`docs/17`)

## Resumen

Solo app. Alcance del MVP corto (D-58, D-61): registrar, anular y ver aportes, con su confirmación en vivo. Sin retiros (HU-016), ajustes (HU-022) ni biometría (HU-009); la confirmación usa el componente común.

## Por capas

1. `domain/movimiento_de_capital.dart`: modelo de `movimientos_capital` con el nombre de quien registró.
2. `data/capital_repositorio.dart`: lee aportes y llama las RPC `registrar_aporte` y `anular_aporte`.
3. `presentation/capital_provider.dart`: foto por la API; el evento `capital` del canal `admin` (y la reconexión) vuelve a pedirla sin mostrar la carga (CA-2).
4. Formulario de aporte con validación local y confirmación (`confirmarAccion`), lista con chips de estado y anulación con motivo (solo en aportes registrados, CA-3), y la subruta `/admin/capital` que habilita la entrada de Administración.

## Decisiones

- CA-1 pide «aportes y retiros»; en el MVP corto la lista muestra solo aportes (nota «MVP corto» de la historia).
- La anulación no mueve dinero, así que pide el motivo en un diálogo propio y no usa la confirmación de dinero.
- Monto: hasta dos decimales y mayor que cero, igual que la base.

## Pruebas

`test/features/admin/capital/capital_test.dart`: modelo, lista, formulario, anulación, errores y el evento en vivo. `flutter analyze` y `flutter test` completos en verde. Sin E2E-04 (pruebas mínimas por decisión de Javier).

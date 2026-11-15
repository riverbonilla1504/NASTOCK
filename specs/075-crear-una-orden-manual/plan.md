# Plan: HU-075 · Crear una orden manual en mi cupo

**Rama**: `075-crear-una-orden-manual` (#193) · **Módulos**: M-10, M-16 · **Fuentes**: `docs/08` §7.5 · `docs/02` §6 · RN-23 · D-60, D-61, D-63, D-65.

- **Migración** (`20261110150000_crear_orden_manual.sql`): `public.crear_orden_manual(id, simbolo, lado, cantidad)` solo para el Usuario sobre su propio cupo (Analista y Administrador: `NO_AUTORIZADO`). Valida la cantidad entera (`PARAMETRO_FUERA_DE_RANGO`), el mercado (`MERCADO_CERRADO`) y las reglas con `private.validar_operacion` (`REGLA_RR_xx`); retiene los fondos, fija el límite con la banda de precio, precarga stop y objetivo con los parámetros del cupo, crea la orden con origen `manual` y la encola. Reintentar con el mismo id devuelve la misma orden.
- **App** (`lib/features/ordenes/`): `domain/orden_manual.dart`, `data/ordenes_repositorio.dart` y `presentation/botones_de_orden.dart` (botones Comprar y Vender en el detalle de Mercado, solo para el Usuario; formulario con cantidad entera y diálogo de confirmación).

Decisiones sin regla explícita en `docs/`:
- La cantidad inválida responde `PARAMETRO_FUERA_DE_RANGO` (no hay un código propio en `docs/06` §9); vender en corto es RR-15.
- El diálogo estima el monto con el precio actual; la RPC fija el límite con la banda.

Pruebas: pgTAP `21_crear_orden_manual_test.sql` (48) · `flutter test test/features/ordenes` (6).

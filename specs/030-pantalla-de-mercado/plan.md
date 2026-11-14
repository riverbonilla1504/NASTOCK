# Plan: HU-030 · Pantalla de mercado en vivo

**Rama**: `030-pantalla-de-mercado` y `030-precio-con-mercado-cerrado`, integradas en la demo (#171) y en #174, #175 · **Módulos**: M-04, M-16 · **Fuentes**: `docs/08` §6 · `docs/09` §1 · D-71.

- **App** (`lib/features/mercado/`): `data/mercado_repositorio.dart` (cotizaciones, lista blanca, estado del mercado y series de la gráfica), `presentation/mercado_provider.dart` (cotizaciones con eventos `cotizaciones` del gestor de tiempo real, estado del mercado, cuenta regresiva), `pagina_mercado.dart` (lista con filtro por bolsillo, detalle con Comprar y Vender), `encabezado_del_mercado.dart` (estado y cuenta regresiva en hora de Bogotá) y `grafica_de_mercado.dart` (1D · 1M · 1Y · All con `lib/shared/widgets/selector_de_rango.dart`).
- **Base**: barras de minuto de todas las acciones de la lista blanca del día en curso (D-71, #175).

Decisiones sin regla explícita en `docs/`:
- Con el mercado cerrado se muestra el último cierre con su fecha.

Pruebas: `flutter test test/features/mercado` (23) y el E2E de la app (`integration_test/app_test.dart`, Inicio es Mercado).

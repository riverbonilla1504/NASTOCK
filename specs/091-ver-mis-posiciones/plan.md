# Plan: HU-091 · Ver mis posiciones y sus protecciones

**Rama**: `091-ver-mis-posiciones` (#194) · **Módulos**: M-16 · **Fuentes**: `docs/08` §9.2 · `docs/09` §3 · D-63.

- **App** (`lib/features/cupo/`): `domain/posicion.dart` (cantidad, costo promedio, último precio, valor, ganancia no realizada, antigüedad y protección), `data/cupo_repositorio.dart`, `presentation/posiciones_provider.dart` (foto por la API y eventos `posicion` del canal del usuario, valorada con las cotizaciones en vivo) y `tarjeta_de_posicion.dart`, dentro de `pagina_mi_cupo.dart`.
- **Sin SQL nuevo**: usa las tablas, la vista y la RLS de HU-074.

Decisiones sin regla explícita en `docs/`:
- Una posición sin protección se muestra como tal, porque las protecciones las crea HU-077.

Pruebas: `flutter test test/features/cupo` (`posiciones_de_mi_cupo_test.dart`, 13, y `mi_cupo_test.dart`).

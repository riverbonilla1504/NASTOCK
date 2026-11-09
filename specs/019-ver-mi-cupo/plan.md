# Plan: HU-019 · Ver mi cupo

**Rama**: `019-ver-mi-cupo` (apilada sobre HU-018, HU-017 y HU-013) · **Módulos**: M-15, M-04 · **Fuentes**: `docs/06` §6, `docs/02` §2 y §13, RN-20, `docs/12` CB-80, `docs/09` §3-§4.

- **BD** (`20261109190000_mi_cupo.sql`): `public.mi_cupo()` sin parámetros (lee `auth.uid()`); solo el Usuario (`NO_AUTORIZADO`/`SESION_INVALIDA`). Devuelve efectivo, retenido, disponible, invertido, patrimonio, resultado realizado (del libro: ventas del cupo), no realizado, rendimiento, `fondo_con_capital` (hay un aporte en el libro) y versión.
- **App** (`lib/features/cupo/`): modelo `MiCupo`, `CupoRepositorio` (solo la RPC), `MiCupoNotifier` sobre `FotoYEventosNotifier` (foto + eventos `cupo` del canal `usuario:{id}`) y `PaginaMiCupo` con tokens y widgets compartidos (`Tarjeta`, `CifraUsd`, `Variacion`, estados). Destino «Mi cupo» del menú del Usuario.

Decisiones sin regla explícita en `docs/`:
- Mientras no existan posiciones (HU-091) el patrimonio es efectivo + invertido (a costo) y el no realizado es 0; el rendimiento es nulo hasta las fotos diarias (HU-021). La pantalla dice «Sin datos aún» y avisa que el invertido va a costo.
- «Fondo sin capital» = no hay ningún movimiento `aporte` en el libro.

Pruebas: pgTAP `15_mi_cupo_test.sql` (16); `flutter test test/features/cupo` (9 pruebas de widget).

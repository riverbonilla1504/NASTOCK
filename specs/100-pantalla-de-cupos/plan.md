# Plan: HU-100 · Pantalla de cupos

**Rama**: `100-pantalla-de-cupos` · **Módulo**: M-16 (usa M-04) · **Fuentes**: `docs/03` PM-42, `docs/02` RN-16/RN-17, `docs/09` §3-§4, `docs/14` §4.1 (D-61: confirmación común, sin biometría).

Solo app, sin SQL: el Administrador ya lee `subcuentas` y `perfiles` por su RLS (HU-013) y escribe por `asignar_cupo` / `reducir_cupo` (HU-018).

- `lib/features/admin/cupos/`: modelo `SubcuentaDeCupo`, `CuposRepositorio` (lectura + las dos RPC), `cuposProvider` sobre `FotoYEventosNotifier` (evento `resumen_cambio` del canal `fondo`, que publica el trigger de `subcuentas`), `PaginaCupos` y `FormularioDeMovimientoDeCupo` (hoja inferior → confirmación común → RPC).
- Ruta `/admin/cupos` como subruta de Administración (guarda de `/admin/*`: Usuario y Analista vuelven a `/inicio`) y una entrada en `PaginaAdministracion`.
- `confirmarAccion` gana el parámetro opcional `rotuloDelSimbolo` (por defecto `Símbolo`) para decir `Cupo`.
- Errores: el catálogo de `docs/06` §9 (`FONDOS_INSUFICIENTES`, `CUPO_SUPERA_MAXIMO`) dentro del diálogo de confirmación.

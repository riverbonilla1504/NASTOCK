# Plan: HU-018 · Asignar y reducir cupos

**Rama**: `018-asignar-y-reducir-cupos` (apilada sobre HU-017 y HU-013) · **Módulo**: M-04 · **Fuentes**: `docs/02` RN-16, RN-17, RN-19; `docs/03` PM-42; `docs/06` §8.1 y §9; `docs/09` §3-§4; `docs/12` CB-14, CB-16.

Una migración (`20261109170000_asignar_y_reducir_cupos.sql`):
1. `private.mover_cupo(usuario, monto, sentido)`: valida sesión y rol (Administrador), monto, cupo abierto; asignar ≤ disponible de `usuarios_comun` (`FONDOS_INSUFICIENTES`) y cupo + monto ≤ `cupos.maximo_usd` si hay (`CUPO_SUPERA_MAXIMO`); reducir ≤ disponible del cupo; mueve con `registrar_movimiento` (`asignacion_cupo` / `reduccion_cupo`) y audita `cupo.asignado` / `cupo.reducido`.
2. `public.asignar_cupo` y `public.reducir_cupo` (envoltorios, solo `authenticated`).
3. Trigger de `subcuentas`: eventos `cupo` (canal del dueño) y `resumen_cambio` (canal `fondo`), sin montos.
El parámetro `cupos.maximo_usd` ya existe (HU-033).

Decisión: «cupo» para el máximo es efectivo + invertido (lo que la persona tiene asignado) tras la asignación; no está explícito en `docs/`.
Pruebas: `14_asignar_y_reducir_cupos_test.sql` (31). El E2E-04 no existe aún (llega con los aportes).

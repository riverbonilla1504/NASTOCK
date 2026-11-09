# Plan: HU-017 · Cupo al aceptar la invitación

**Rama**: `017-cupo-al-aceptar-la-invitacion` (apilada sobre HU-013) · **Módulos**: M-04, M-01 · **Fuentes**: `docs/02` RN-18/RN-20, `docs/04` §6, `docs/06` §8.2, `docs/12` CB-15.

Una migración (`20261109150000_crear_cupo_y_alta.sql`):
1. `private.crear_cupo(usuario, monto)`: crea la subcuenta `cupo` (bolsillo usuarios); si `usuarios_comun` cubre el monto, lo asigna con `registrar_movimiento('asignacion_cupo')` y audita `cupo.asignado`; si no, queda en 0 y no falla (aviso en el registro; la alerta es de HU-085). Idempotente.
2. `private.al_crear_usuario` (HU-002) llama a `crear_cupo` si el rol es Usuario.
3. Relleno: cada Usuario no dado de baja sin cupo recibe el suyo en 0 (CA-4).
El índice único de un cupo abierto por persona ya lo creó HU-013. Lectura del propio cupo: política de HU-013 (CA-5).

Pruebas: `supabase/tests/database/13_cupo_al_aceptar_invitacion_test.sql` (21).

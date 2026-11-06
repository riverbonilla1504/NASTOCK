# Modelo de datos (Fase 1): HU-001 · Perfiles, rol actual y lecturas por rol

Fuente: `docs/06` §3 (enumeraciones) y §5.1 (identidad). Los nombres y tipos son los de `docs/`.

## Tipos

| Tipo | Valores |
|---|---|
| `public.rol_app` | `usuario` · `analista` · `administrador` |
| `public.estado_cuenta` | `activo` · `suspendido` · `baja` |

## Tabla `public.perfiles`

| Columna | Tipo | Reglas |
|---|---|---|
| `id` | `uuid` | Clave primaria. Referencia a `auth.users (id)`. |
| `email` | `text` | No nulo, único, en minúsculas (`check (email = lower(email))`). No se edita (RN-58). |
| `nombre` | `text` | No nulo. |
| `rol` | `rol_app` | No nulo. Un solo rol por persona (D-01). |
| `estado` | `estado_cuenta` | No nulo, por defecto `activo`. |
| `recibe_sugerencias` | `boolean` | No nulo, por defecto `true` (PM-15). |
| `preferencias_push` | `jsonb` | No nulo, por defecto `'{}'` (`docs/09` §5.3). |
| `invitacion_id` | `uuid` | Nulo. Sin llave foránea hasta HU-002 (research D-3). |
| `suspendido_en` | `timestamptz` | Nulo. |
| `baja_en` | `timestamptz` | Nulo. |
| `creado_en` | `timestamptz` | No nulo, por defecto `now()`. |
| `actualizado_en` | `timestamptz` | No nulo, por defecto `now()`. |
| `version` | `int` | No nulo, por defecto `1`. |

`auth.users` lleva la identidad; `perfiles` lleva el rol y el estado. Nadie borra un perfil (`docs/06` §1, "Borrado"): el estado `baja` reemplaza al borrado.

## Seguridad

- RLS activo; una sola política: `perfiles_lectura` (select, `authenticated`).
- `authenticated` solo tiene `select`; `anon` no tiene ningún privilegio. Ninguna política de escritura.
- Quién escribe: los triggers y funciones `security definer` de las historias siguientes (HU-002 crea la fila; HU-010, HU-011 y HU-012 cambian estado y rol).

## Matriz de lectura

| Quien consulta | Estado de su cuenta | Filas que recibe |
|---|---|---|
| Usuario | activo | la suya |
| Analista | activo | todas |
| Administrador | activo | todas |
| Cualquiera | suspendido, de baja o sin perfil | ninguna |

## Funciones

Ver [contracts/funciones-y-hook.md](contracts/funciones-y-hook.md).

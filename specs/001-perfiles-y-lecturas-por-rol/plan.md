# Plan de implementación: HU-001 · Perfiles, rol actual y lecturas por rol

**Rama**: `001-perfiles-y-lecturas-por-rol` | **Fecha**: 2026-11-06 | **Especificación**: [spec.md](spec.md)

**Entrada**: especificación de `specs/001-perfiles-y-lecturas-por-rol/spec.md`. Historia: [`backlog/E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md`](../../backlog/E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) (issue #18).

## Resumen

Cada cuenta tiene un único rol y un estado guardados en `perfiles`, y toda lectura se filtra por ellos. El plan construye, por capas y cada una con sus pruebas pgTAP: (1) los tipos `rol_app` y `estado_cuenta` y la tabla `perfiles` con RLS y sin escritura directa; (2) `private.rol_actual()` y `private.es_supervisor()`; (3) la política de lectura de `perfiles`; (4) el hook `private.token_personalizado`, registrado en `supabase/config.toml` (la duración del JWT de 900 s ya está desde TT-03); (5) `perfilProvider` en la app, que lee los claims y la fila de `perfiles` y solo entra cuando TT-04 está en `main`.

## Contexto técnico

**Lenguaje/Versión**: SQL y PL/pgSQL (Postgres de Supabase local); Dart/Flutter 3.47 para la capa de app.

**Dependencias principales**: Supabase CLI 2.122 (stack local con Docker), `supabase_auth_admin` (servicio de Auth que ejecuta el hook), pgTAP, `supabase_flutter` y Riverpod (los trae TT-04).

**Almacenamiento**: Postgres. Tabla nueva `public.perfiles`; tipos nuevos `public.rol_app` y `public.estado_cuenta`.

**Pruebas**: pgTAP en `supabase/tests/database/` (convención de TT-03: `NN_nombre_test.sql`); `flutter test` para `perfilProvider`.

**Plataforma de destino**: Supabase (local, CI y proyecto MVP) y app Flutter (Android y web).

**Tipo de proyecto**: base de datos + app móvil/web. Sin Edge Functions.

**Metas de rendimiento**: las políticas usan `(select ...)` para que Postgres evalúe una vez por consulta (`docs/06` §7, regla 4).

**Restricciones**: la autorización lee `perfiles`, nunca los claims (CA-6, `docs/03` §4.1); funciones `security definer` con `set search_path = ''` (`supabase db lint --fail-on warning`); ningún rol de la API escribe en `perfiles`; ninguna llave en el repositorio.

**Escala/Alcance**: decenas de cuentas (empleados de RiTech). Una tabla, dos funciones de autorización, un hook.

## Revisión de la constitución (Constitution Check)

| Principio o invariante | Cumple | Cómo |
|---|---|---|
| I · `docs/` es la fuente de verdad | Sí | Tabla, funciones y hook salen de `docs/06` §5.1, `docs/03` §4.1–§4.3 y `docs/04` §7. Las dos aclaraciones que no están literales en `docs/` van a [research.md](research.md) (D-1 y D-2) y no cambian ninguna regla. |
| II · Documentación primero | Sí | Ninguna regla nueva: no hace falta tocar `docs/` salvo `docs/17` (rutas de pruebas y de la app). |
| IV · Investigación acotada | Sí | Solo M-02 y la parte de M-01 que es el hook; secciones de `docs/` de la historia. |
| V · Errores conocidos | Sí | Se aplican EC-009 (grants del hook, prueba como `supabase_auth_admin`) y EC-010 (`search_path`). |
| VI · Verificación de punta a punta | Sí | `scripts/verificar.sh` completo antes de terminar; la historia no tiene escenario E2E propio. |
| VII · Alcance y costo | Sí | Nada de pago ni de servicios nuevos. |
| Invariante 4 (RLS y escritura solo por RPC) | Sí | RLS activo en `perfiles`, sin políticas de escritura y sin privilegios de escritura para `anon` ni `authenticated`. |
| Invariante 5 (autorización lee `perfiles`) | Sí | `rol_actual()` consulta la tabla; el hook solo escribe claims para la interfaz. |
| Invariante 6 (sin llaves) | Sí | No se usa ninguna llave. |

Sin violaciones: no hay tabla de complejidad.

## Estructura del proyecto

### Documentación de esta historia

```text
specs/001-perfiles-y-lecturas-por-rol/
├── spec.md
├── plan.md              # Este archivo
├── research.md          # Decisiones de diseño (Fase 0)
├── data-model.md        # La tabla perfiles (Fase 1)
├── quickstart.md        # Cómo comprobar la historia (Fase 1)
├── contracts/           # Funciones, hook y política (Fase 1)
├── checklists/
└── tasks.md             # /speckit-tasks
```

### Código fuente

```text
supabase/
├── config.toml                                              # + [auth.hook.custom_access_token]
├── migrations/
│   ├── <ts>_perfiles_tipos_y_tabla.sql                      # rol_app, estado_cuenta, perfiles, RLS, sin escritura
│   ├── <ts>_rol_actual_y_es_supervisor.sql                  # private.rol_actual(), private.es_supervisor()
│   ├── <ts>_perfiles_politica_de_lectura.sql                # política perfiles_lectura
│   └── <ts>_token_personalizado.sql                         # private.token_personalizado + grants
└── tests/database/
    ├── 02_perfiles_rls_test.sql                             # lectura por rol, cuenta no activa, escritura bloqueada
    └── 03_perfiles_roles_y_token_test.sql                   # rol_actual/es_supervisor, CA-6 y claims del token
lib/core/                                                    # perfilProvider (solo con TT-04 en main)
test/core/                                                   # prueba de perfilProvider
docs/17-mapa-de-modulos.md                                   # M-01 y M-02: rutas reales
```

**Decisión de estructura**: las migraciones siguen el orden de capas de la historia (tipos y tabla → funciones → política → hook). Las pruebas siguen la carpeta que ya usa TT-03 (`supabase/tests/database/`) y no la de `docs/17`, que dice `supabase/tests/rls_*.sql`; se corrige `docs/17` al terminar.

## Capas y orden

| # | Capa | Entrega | Cubre | Pruebas |
|---|---|---|---|---|
| 1 | Tipos y tabla | Migración 1 | CA-4 (parte), FR-020 | `02_`: RLS activo, sin políticas de escritura, sin privilegios de escritura |
| 2 | Funciones de autorización | Migración 2 | CA-2, CA-6, FR-019 | `03_`: `rol_actual()` por rol y por estado; `es_supervisor()` |
| 3 | Política de lectura | Migración 3 | CA-3, CA-4, CA-2 | `02_`: qué ve cada rol; cuenta suspendida o de baja no recibe filas; INSERT/UPDATE/DELETE rechazados |
| 4 | Hook del token | Migración 4 + `config.toml` | CA-1, CA-5, FR-018 | `03_`: el hook corre como `supabase_auth_admin` (EC-009); claims; perfil inexistente. CA-5 y el registro se comprueban con un inicio de sesión real en el stack local ([quickstart.md](quickstart.md)) |
| 5 | App | `perfilProvider` | FR-018, FR-019 (parte de interfaz) | `flutter test` con claims y fila de `perfiles` simulados; depende de TT-04 |

## Riesgos y puntos abiertos

- **`perfiles.invitacion_id`**: `docs/06` §5.1 lo declara con `references invitaciones`, pero esa tabla la crea HU-002 y a su vez apunta a `perfiles`. HU-001 crea la columna sin la llave foránea y HU-002 la agrega al crear `invitaciones` (D-3 de [research.md](research.md)).
- **Pruebas que insertan en `auth.users`**: cuando HU-002 agregue el trigger `al_crear_usuario`, cualquier alta en `auth.users` intentará crear un perfil. Las pruebas de esta historia inhabilitan los triggers solo al crear las cuentas de prueba (`session_replication_role = replica`) para no depender de ese trigger.
- **Stack local compartido**: `config.toml` solo se lee al arrancar el stack; para comprobar el hook de verdad hay que reiniciarlo con el candado tomado.

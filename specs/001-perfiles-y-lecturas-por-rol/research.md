# Investigación (Fase 0): HU-001 · Perfiles, rol actual y lecturas por rol

No quedó ninguna duda sin resolver. Estas son las decisiones de diseño que `docs/` no escribe literalmente y cómo se resolvieron sin cambiar ninguna regla.

## D-1 · La fila propia de `perfiles` también exige cuenta activa

- **Decisión**: la política de lectura de `perfiles` solo deja ver algo si `private.rol_actual()` no es NULL. Dentro de eso, el supervisor ve todas las filas y cualquier otra persona, la suya.
- **Razón**: el patrón de `docs/03` §4.3 (`es_supervisor() or dueño = auth.uid()`) dejaría a una cuenta suspendida leer su propia fila. Eso choca con `docs/03` §4.2 ("si está suspendida, de baja o no existe, devuelve NULL y todas las políticas niegan"), con `docs/04` §10 ("no ve ni modifica datos, inmediato") y con CA-2 ("no recibe ninguna fila"). La app de una cuenta suspendida sabe su estado por `app_estado` del token, no por leer `perfiles`.
- **Alternativas**: dejar la fila propia a una cuenta suspendida (descartada: contradice CA-2).

## D-2 · Privilegios de escritura quitados además de no tener políticas

- **Decisión**: se revoca `insert`, `update`, `delete`, `truncate`, `references` y `trigger` sobre `perfiles` a `anon` y `authenticated`, y solo se concede `select` a `authenticated`. Tampoco hay políticas de escritura.
- **Razón**: CA-4 pide que la base de datos "rechace" la escritura directa y FR-020 pide "no conceder" escritura. Con solo RLS, un `UPDATE` o `DELETE` no falla: afecta cero filas sin error. Sin el privilegio, falla con `42501` (permiso denegado) y la prueba lo puede afirmar.
- **Alternativas**: solo RLS sin políticas (descartada: el rechazo sería silencioso).
- **Fuera de alcance**: `service_role` se salta RLS por diseño de Supabase y conserva sus privilegios por defecto. `docs/06` §7 (regla 3) lo gobierna con "las Edge Functions solo llaman funciones `private`"; no se cambia aquí.

## D-3 · `invitacion_id` sin llave foránea hasta HU-002

- **Decisión**: la columna `invitacion_id uuid` existe con su comentario y sin `references`. HU-002 agrega la restricción cuando crea `invitaciones`.
- **Razón**: `docs/06` §5.1 declara `invitacion_id uuid references invitaciones`, pero HU-001 va antes que HU-002 (que crea `invitaciones` y `estado_invitacion`) y `invitaciones` apunta a `perfiles`, así que la dependencia es circular. Es un orden de construcción, no una regla.
- **Alternativas**: crear `invitaciones` aquí (descartada: es de HU-002 y trae su RLS y su índice único).

## D-4 · Forma del hook y permisos de `supabase_auth_admin`

- **Decisión**: el hook es el de `docs/04` §7 (`security definer`, `set search_path = ''`). Se concede `execute` y `usage` sobre el esquema `private` a `supabase_auth_admin` y se revoca `execute` a `public`, `anon` y `authenticated`. No se da `select` sobre `perfiles` a `supabase_auth_admin`: el hook lee con los privilegios de su dueño.
- **Razón**: EC-009 (login que falla por permisos del hook) se previene con una prueba que ejecuta el hook como `supabase_auth_admin`. Pasa también `security definer` por EC-010.
- **Alternativas**: dar `select` y una política a `supabase_auth_admin` como en `docs/04` §5 (innecesario con `security definer`).

## D-5 · Las políticas llaman a `private.rol_actual()` sin `usage` sobre `private`

- **Decisión**: `authenticated` recibe `execute` sobre `private.rol_actual()` y `private.es_supervisor()`, y no `usage` sobre el esquema `private`.
- **Razón**: `00_base_test.sql` (TT-03) exige que `authenticated` no use el esquema `private`. Postgres comprueba `usage` del esquema al resolver el nombre, no al ejecutar una política ya guardada, así que la política funciona. La prueba de lectura lo demuestra.
- **Alternativas**: dar `usage` (descartada: rompe la prueba de TT-03 y la regla de que la API no usa `private`).

## D-6 · Cómo se prueba cada criterio

| Criterio | Cómo |
|---|---|
| CA-1 | pgTAP: el hook con `user_id` de un analista activo devuelve `app_rol = analista` y `app_estado = activo`; se ejecuta como `supabase_auth_admin`. Real: inicio de sesión local y lectura del JWT. |
| CA-2 | pgTAP: con una cuenta suspendida (creada ya suspendida, porque suspender llega con HU-010) `rol_actual()` es NULL y `select` sobre `perfiles` devuelve cero filas. |
| CA-3 | pgTAP: como Usuario ve su fila; como Analista y Administrador ven todas. |
| CA-4 | pgTAP: `INSERT`, `UPDATE`, `DELETE` como `authenticated` y como `anon` fallan con `42501`. |
| CA-5 | Real: inicio de sesión local y `exp - iat = 900` en el JWT. `config.toml` ya trae `jwt_expiry = 900` desde TT-03; la prueba no puede leerlo desde SQL. |
| CA-6 | pgTAP: se cambia el rol en `perfiles` y se consulta con el claim viejo; `rol_actual()` y la política usan el rol nuevo. |

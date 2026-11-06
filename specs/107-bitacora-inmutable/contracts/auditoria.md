# Contratos: tabla, funciones, política y trigger de la bitácora

Fuente: `docs/06` §5.6, §7 y §8.2, `docs/11` §4 y `docs/03` §4.3. Las decisiones están en [research.md](../research.md).

## Permisos de `public.auditoria`

| Rol | `select` | `insert` / `update` / `delete` / `truncate` |
|---|---|---|
| `anon` | no (`42501`) | no (`42501`) |
| `authenticated` | sí, filtrado por la política | no (`42501`) |
| `service_role` | no (`42501`) | no (`42501`) |
| dueño (`postgres`) | sí | `insert` solo desde `auditar`; `update`, `delete` y `truncate` los rechaza el trigger |

La secuencia de `id` también se revoca a los roles de la API.

## Política `auditoria_lectura`

```sql
create policy auditoria_lectura on public.auditoria
for select to authenticated
using ((select private.rol_actual()) = 'administrador');
```

Sin políticas de escritura. Un Usuario, un Analista, una cuenta no activa o una sesión sin perfil reciben cero filas.

## `private.hash_auditoria(...) → text`

```text
private.hash_auditoria(
  p_hash_anterior text, p_momento timestamptz, p_actor uuid, p_actor_rol rol_app,
  p_accion text, p_entidad text, p_entidad_id text,
  p_antes jsonb, p_despues jsonb, p_detalle jsonb, p_origen text
) returns text
```

- `language sql stable`, `set search_path = ''`.
- Devuelve `encode(sha256(convert_to(contenido, 'UTF8')), 'hex')`.
- `contenido` es la unión, en este orden y con el separador `U+001F`, de: `p_hash_anterior`, `p_momento` en UTC como `YYYY-MM-DD"T"HH24:MI:SS.US"Z"`, `p_actor` en texto, `p_actor_rol`, `p_accion`, `p_entidad`, `p_entidad_id`, `p_antes`, `p_despues` y `p_detalle` como texto de `jsonb`, y `p_origen`. Un campo nulo entra vacío. Es la fórmula de `docs/11` §4.3.
- Sin permisos para `public`, `anon`, `authenticated` ni `service_role`. La usan `auditar` y la verificación de HU-108.

## `private.auditar(...) → bigint`

```text
private.auditar(
  p_actor uuid, p_accion text, p_entidad text, p_entidad_id text,
  p_detalle jsonb default null, p_antes jsonb default null,
  p_despues jsonb default null, p_origen text default null
) returns bigint
```

- `language plpgsql security definer set search_path = ''`.
- Orden de trabajo: (1) valida que `p_accion` y `p_entidad` no estén vacíos; (2) `lock table public.auditoria in share row exclusive mode`; (3) lee el `hash` del último registro (por `id`) o usa 64 ceros; (4) toma `momento = private.ahora()`; (5) lee `actor_rol` de `perfiles` por `p_actor`; (6) decide `origen` (`p_origen`, o `sistema` sin actor y `app` con actor); (7) calcula el hash con `private.hash_auditoria`, pasándole el rol y el origen ya decididos; (8) inserta y devuelve el `id`.
- Falla con una excepción `auditar: …` si `p_accion` o `p_entidad` vienen vacíos o nulos, y con `23514` si el origen no es válido.
- Si la transacción que la llama se revierte, el registro también (`docs/11` §4.2, EC-012).
- Solo guarda lo que recibe: no lee el token ni las cabeceras de la sesión.
- Sin `execute` para `public`, `anon`, `authenticated` ni `service_role`; la llaman otras funciones `security definer`, triggers y las Edge Functions por la conexión directa (D-66).

## Trigger de inmutabilidad

```text
private.rechazar_cambio_auditoria() returns trigger   -- search_path = ''
auditoria_inmutable  before update or delete or truncate on public.auditoria for each statement
```

Lanza `auditoria: la bitácora es inmutable (<operación> no permitido)`. Por sentencia: rechaza también un `UPDATE` o `DELETE` que no alcanzaría ninguna fila. Rechaza incluso al dueño de la tabla y a un rol al que se le hubieran concedido privilegios.

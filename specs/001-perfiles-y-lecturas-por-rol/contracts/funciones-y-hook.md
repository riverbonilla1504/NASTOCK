# Contratos: funciones de autorización, política y hook

Fuente: `docs/03` §4.1–§4.3 y `docs/04` §7.

## `private.rol_actual() → public.rol_app`

- `language sql stable security definer set search_path = ''`.
- Devuelve el rol de `auth.uid()` en `perfiles` solo si `estado = 'activo'`; en cualquier otro caso (suspendida, de baja, sin perfil, sin sesión) devuelve `NULL`.
- Lee `perfiles`, nunca los claims del token (CA-6).
- Permisos: `execute` para `authenticated`; revocado a `public` y `anon`. El esquema `private` sigue sin `usage` para la API.

## `private.es_supervisor() → boolean`

- `language sql stable security definer set search_path = ''`.
- `coalesce(private.rol_actual() in ('analista', 'administrador'), false)`.
- Mismos permisos que `rol_actual()`.

## Política `perfiles_lectura`

```sql
create policy perfiles_lectura on public.perfiles
for select to authenticated
using (
  (select private.rol_actual()) is not null
  and (
    (select private.es_supervisor())
    or id = (select auth.uid())
  )
);
```

## `private.token_personalizado(event jsonb) → jsonb`

- `language plpgsql stable security definer set search_path = ''`.
- Entrada: el evento del hook de Auth (`user_id`, `claims`, ...). Salida: el mismo evento con `claims.app_rol` y `claims.app_estado` leídos de `perfiles` (`null` si la persona no tiene perfil).
- Permisos: `execute` y `usage` sobre `private` solo para `supabase_auth_admin`; revocado a `public`, `anon` y `authenticated`.
- Registro: `supabase/config.toml`, sección `[auth.hook.custom_access_token]`, `uri = "pg-functions://postgres/private/token_personalizado"`. En la nube se registra a mano en Authentication → Hooks (`docs/04` §3, paso 7).
- Los claims son solo para la interfaz. Ninguna política ni función de autorización los lee.

## Duración del token

`supabase/config.toml` → `[auth] jwt_expiry = 900` (ya está desde TT-03).

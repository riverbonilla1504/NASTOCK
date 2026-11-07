-- HU-002 · Hook "antes de crear usuario" de Auth.
-- Fuentes: docs/04 §5 y §11 (mensajes), docs/12 CB-01, CB-02, CB-92. Se registra en
-- supabase/config.toml ([auth.hook.before_user_created]); en la nube, a mano en
-- Authentication → Hooks (docs/04 §3, paso 7).

-- Arma el error que Auth devuelve a la app: {"error": {"http_code", "message"}}.
create function private.error_auth(p_codigo int, p_mensaje text)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select jsonb_build_object('error', jsonb_build_object('http_code', p_codigo, 'message', p_mensaje))
$$;

comment on function private.error_auth(int, text) is
  'Arma el error que un hook de Auth devuelve para rechazar la operación (docs/04 §5).';

create function private.antes_de_crear_usuario(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email     text := lower(coalesce(event->'user'->>'email', ''));
  v_proveedor text := event->'user'->'app_metadata'->>'provider';
  v_dominio   text := split_part(v_email, '@', 2);
begin
  if not exists (
    select 1 from public.parametros
    where clave = 'auth.proveedores_permitidos' and valor ? coalesce(v_proveedor, '')
  ) then
    return private.error_auth(403, 'Solo puedes ingresar con tu cuenta de Google de RiTech.');
  end if;

  if not exists (
    select 1 from public.parametros
    where clave = 'auth.dominios_permitidos' and valor ? v_dominio
  ) then
    return private.error_auth(403, 'Solo se admiten cuentas corporativas de RiTech.');
  end if;

  if not exists (
    select 1 from public.invitaciones
    where lower(email) = v_email and estado = 'pendiente' and expira_en > private.ahora()
  ) then
    return private.error_auth(403,
      'Tu correo no tiene una invitación vigente. Pídele una al administrador.');
  end if;

  return '{}'::jsonb;
end;
$$;

comment on function private.antes_de_crear_usuario(jsonb) is
  'Hook de Auth: rechaza el alta sin proveedor permitido, dominio permitido e invitación pendiente y vigente (docs/04 §5).';

-- Solo el servicio de Auth lo ejecuta (EC-009).
grant usage on schema private to supabase_auth_admin;
revoke all on function private.error_auth(int, text) from public, anon, authenticated;
revoke all on function private.antes_de_crear_usuario(jsonb) from public, anon, authenticated;
grant execute on function private.error_auth(int, text) to supabase_auth_admin;
grant execute on function private.antes_de_crear_usuario(jsonb) to supabase_auth_admin;

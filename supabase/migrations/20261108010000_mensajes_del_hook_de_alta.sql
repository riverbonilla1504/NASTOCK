-- HU-004 · Mensajes del hook "antes de crear usuario" tras la decisión de Gmail (docs/13 §4, 3.20).
-- Fuentes: docs/04 §5 y §11. RiTech no tiene Google Workspace: el equipo entra con Gmail personal, así que
-- los mensajes ya no hablan de "cuentas corporativas de RiTech".
-- La migración de HU-002 (20261107150004) ya está integrada y las migraciones solo van hacia adelante:
-- aquí se redefine la función con create or replace. No cambia ninguna regla, solo dos textos; los
-- permisos (solo supabase_auth_admin) se conservan.

create or replace function private.antes_de_crear_usuario(event jsonb)
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
    return private.error_auth(403, 'Solo puedes ingresar con tu cuenta de Google.');
  end if;

  if not exists (
    select 1 from public.parametros
    where clave = 'auth.dominios_permitidos' and valor ? v_dominio
  ) then
    return private.error_auth(403, 'Solo se admiten cuentas de Google invitadas.');
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

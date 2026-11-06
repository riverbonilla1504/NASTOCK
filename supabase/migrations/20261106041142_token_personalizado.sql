-- HU-001 · Hook "token personalizado" de Auth.
-- Fuentes: docs/04 §7 y §8, docs/03 §4.1. Se registra en supabase/config.toml
-- ([auth.hook.custom_access_token]); en la nube, a mano en Authentication → Hooks (docs/04 §3, paso 7).
--
-- Agrega al JWT los claims app_rol y app_estado leídos de perfiles. Son SOLO para que la app arme
-- su interfaz: ninguna política ni función de autorización los lee (CA-6).

create function private.token_personalizado(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_rol    text;
  v_estado text;
  v_claims jsonb := event->'claims';
begin
  select p.rol::text, p.estado::text into v_rol, v_estado
  from public.perfiles p
  where p.id = (event->>'user_id')::uuid;

  v_claims := jsonb_set(v_claims, '{app_rol}',    coalesce(to_jsonb(v_rol),    'null'::jsonb));
  v_claims := jsonb_set(v_claims, '{app_estado}', coalesce(to_jsonb(v_estado), 'null'::jsonb));
  return jsonb_set(event, '{claims}', v_claims);
end;
$$;

comment on function private.token_personalizado(jsonb) is
  'Hook de Auth: agrega los claims app_rol y app_estado al token, solo para la interfaz (docs/04 §7).';

-- El servicio de Auth es el único que lo puede ejecutar (EC-009). Como la función es security
-- definer, lee perfiles con los privilegios de su dueño y no necesita select ni política propios.
grant usage on schema private to supabase_auth_admin;
grant execute on function private.token_personalizado(jsonb) to supabase_auth_admin;
revoke execute on function private.token_personalizado(jsonb) from public, anon, authenticated;

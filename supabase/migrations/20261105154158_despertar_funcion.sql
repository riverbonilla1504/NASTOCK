-- TT-03 · private.despertar_funcion(nombre).
-- Fuentes: docs/05 §4 y §7 (pg_net con el secreto interno leído de Vault), §10.1 (secretos en Vault).
--
-- Despierta una Edge Function con un POST que no espera respuesta. La URL base y el
-- secreto interno salen de Vault (url_funciones y secreto_interno). Devuelve el id de
-- la solicitud de pg_net.

create function private.despertar_funcion(nombre text)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url     text;
  v_secreto text;
begin
  -- Solo nombres de función: minúsculas, números y guiones (evita armar otra URL).
  if nombre is null or nombre !~ '^[a-z0-9]+(-[a-z0-9]+)*$' then
    raise exception 'despertar_funcion: nombre de función inválido'
      using detail = coalesce(nombre, '(nulo)');
  end if;

  select ds.decrypted_secret into v_url
    from vault.decrypted_secrets ds
   where ds.name = 'url_funciones';

  select ds.decrypted_secret into v_secreto
    from vault.decrypted_secrets ds
   where ds.name = 'secreto_interno';

  if v_url is null or v_secreto is null then
    raise exception 'despertar_funcion: faltan url_funciones o secreto_interno en Vault'
      using detail = 'Ver docs/16 §3.2 (nube) y supabase/seed.sql (local)';
  end if;

  return net.http_post(
    url     := rtrim(v_url, '/') || '/' || nombre,
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-secreto-interno', v_secreto
               ),
    body    := '{}'::jsonb
  );
end;
$$;

comment on function private.despertar_funcion(text) is
  'POST sin esperar respuesta a una Edge Function, con la URL y el secreto interno de Vault (docs/05 §7).';

revoke all on function private.despertar_funcion(text) from public, anon, authenticated;

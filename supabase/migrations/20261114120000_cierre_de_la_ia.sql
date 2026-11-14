-- D-72 · Cierre de la IA del MVP con JEV (HU-046 CA-3 y CA-5).
-- Fuentes: docs/07 §2 (cuándo corre), docs/03 §2 (PM-58: correr un ciclo ahora es del Administrador).
--
-- 1. El agente lee el interruptor `ia_activa`: apagado, el ciclo queda `omitido` (`ia_apagada`).
-- 2. `despertar_funcion` acepta un cuerpo, para decirle al agente con qué disparador corre.
-- 3. `lanzar_ciclo()`: el Administrador corre un ciclo con disparador `manual`.

-- 1. Hora, mercado e interruptor para el ciclo. Sin fila en `fondos`, la IA cuenta como apagada.
drop function private.estado_del_agente();

create function private.estado_del_agente()
returns table (ahora timestamptz, mercado_en_ventana boolean, ia_activa boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select private.ahora(),
         private.mercado_en_ventana(interval '0 minutes'),
         coalesce((select f.ia_activa from public.fondos f limit 1), false)
$$;

comment on function private.estado_del_agente() is
  'Hora, ventana del mercado e interruptor ia_activa para el ciclo del agente (docs/07 §2, D-72).';

revoke all on function private.estado_del_agente() from public, anon, authenticated;

-- 2. Despertar una función con un cuerpo JSON. La versión de un argumento sigue igual (cuerpo vacío).
create function private.despertar_funcion(nombre text, cuerpo jsonb)
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
    body    := coalesce(cuerpo, '{}'::jsonb)
  );
end;
$$;

comment on function private.despertar_funcion(text, jsonb) is
  'Como despertar_funcion(text), con un cuerpo JSON para la función (docs/05 §7, D-72).';

revoke all on function private.despertar_funcion(text, jsonb) from public, anon, authenticated;

-- 3. Correr un ciclo ahora (PM-58, HU-046 CA-5). El agente decide si puede correr: si hay otro en
-- curso responde que se omitió, y con ia_activa apagado el ciclo queda `omitido`.
create function public.lanzar_ciclo()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_rol   public.rol_app := private.rol_actual();
begin
  if v_rol is null then
    raise exception 'SESION_INVALIDA';
  end if;
  if v_rol <> 'administrador' then
    raise exception 'NO_AUTORIZADO';
  end if;

  perform private.despertar_funcion('agente', jsonb_build_object('disparador', 'manual'));
  perform private.auditar(v_actor, 'ciclo.lanzado', 'ciclos_agente', null,
                          jsonb_build_object('disparador', 'manual'));
end;
$$;

comment on function public.lanzar_ciclo() is
  'Administrador (PM-58, HU-046 CA-5): despierta al agente para un ciclo con disparador manual. Usuario y Analista: NO_AUTORIZADO.';

revoke all on function public.lanzar_ciclo() from public, anon;
grant execute on function public.lanzar_ciclo() to authenticated;

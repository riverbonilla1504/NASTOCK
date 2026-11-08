-- HU-004 · Primer administrador por configuración de despliegue.
-- Fuentes: docs/04 §9 (mecanismo, historial 3.21) y §1 (dominio, 3.20), docs/06 §5.1 (invitaciones),
-- docs/13 Q-08, CA-1 a CA-4 de HU-004.
--
-- El correo llega como el secreto de GitHub ADMIN_INICIAL_EMAIL. supabase/config.toml lo declara en
-- [db.vault] y `supabase db push` lo guarda en Vault (admin_inicial_email) justo antes de aplicar las
-- migraciones pendientes. Una migración no lee variables de entorno; sí lee Vault. Sin ese secreto
-- (local y CI, donde la semilla ya trae al administrador de prueba) no se crea ninguna invitación.
--
-- La migración corre una sola vez por proyecto: si el secreto se cargó mal o la invitación venció sin
-- usarse, una migración nueva vuelve a llamar a la función. Ninguna de las dos funciones la ejecuta
-- un rol de la API (solo el dueño, que es quien aplica las migraciones).

-- Deja los dominios permitidos en ["gmail.com"] (Q-08) solo si están vacíos: HU-002 los crea vacíos y
-- ninguna historia los cargaba (HU-101 exige tener ya un administrador). Devuelve si cambió algo.
create function private.cargar_dominio_inicial()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_filas int;
begin
  update public.parametros
     set valor = '["gmail.com"]'::jsonb,
         actualizado_en = now(),
         version = version + 1
   where clave = 'auth.dominios_permitidos'
     and valor = '[]'::jsonb;
  get diagnostics v_filas = row_count;
  return v_filas > 0;
end;
$$;

comment on function private.cargar_dominio_inicial() is
  'Arranque (docs/04 §9): deja auth.dominios_permitidos en ["gmail.com"] solo si estaba vacío. Devuelve si lo cambió.';

-- Crea la invitación pendiente del primer Administrador con el correo de Vault. Devuelve su id, o nulo si
-- no hizo nada: no hay correo configurado, ya existe un administrador o ya hay una invitación vigente.
create function private.crear_invitacion_inicial()
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text;
  v_id    uuid;
begin
  select lower(btrim(ds.decrypted_secret)) into v_email
    from vault.decrypted_secrets ds
   where ds.name = 'admin_inicial_email';

  if v_email is null or v_email = '' then
    return null;
  end if;

  -- Si el arranque ya ocurrió (hay un administrador), no hace nada: CA-2.
  if exists (select 1 from public.perfiles where rol = 'administrador') then
    return null;
  end if;

  -- Un correo mal escrito, o de un dominio que el hook de alta rechazaría, dejaría a todos fuera y la
  -- migración no se repite sola: mejor que falle ahora y se corrija el secreto.
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+$' then
    raise exception 'ADMIN_INICIAL_EMAIL no tiene forma de correo (docs/04 §9)'
      using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.parametros
     where clave = 'auth.dominios_permitidos' and valor ? split_part(v_email, '@', 2)
  ) then
    raise exception 'El dominio de ADMIN_INICIAL_EMAIL no está en auth.dominios_permitidos (docs/04 §9)'
      using errcode = '22023';
  end if;

  -- Una pendiente ya vencida pasa a vencida (como invitar_usuario, docs/13 3.2) para poder reemitirla.
  update public.invitaciones
     set estado = 'vencida'
   where email = v_email and estado = 'pendiente' and expira_en <= private.ahora();

  if exists (select 1 from public.invitaciones where email = v_email and estado = 'pendiente') then
    return null;
  end if;

  insert into public.invitaciones (email, rol, creada_por, expira_en)
  values (v_email, 'administrador', null, private.ahora() + interval '7 days')
  returning id into v_id;

  perform private.auditar(null, 'cuenta.invitada', 'invitaciones', v_id::text,
                          jsonb_build_object('rol', 'administrador', 'origen', 'despliegue'));
  return v_id;
end;
$$;

comment on function private.crear_invitacion_inicial() is
  'Arranque (docs/04 §9): crea la invitación de Administrador para admin_inicial_email (Vault). No hace nada sin correo, con un administrador existente o con una invitación vigente.';

revoke all on function private.cargar_dominio_inicial() from public, anon, authenticated;
revoke all on function private.crear_invitacion_inicial() from public, anon, authenticated;

-- El arranque: una vez, al aplicar esta migración.
select private.cargar_dominio_inicial();
select private.crear_invitacion_inicial();

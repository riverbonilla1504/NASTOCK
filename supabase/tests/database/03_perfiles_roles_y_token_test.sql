-- HU-001 · private.rol_actual(), private.es_supervisor() y el hook private.token_personalizado.
-- Criterios: CA-1, CA-2, CA-6 (backlog/E-02-identidad-y-acceso/HU-001-*.md). Reglas: docs/03 §4.1–§4.2, docs/04 §7.
-- CA-5 (token de 15 minutos) y el registro del hook en config.toml no se pueden leer desde SQL: se comprueban con
-- un inicio de sesión real (specs/001-perfiles-y-lecturas-por-rol/quickstart.md).
begin;
create extension if not exists pgtap with schema extensions;
select plan(38);

-- Cuentas de prueba ---------------------------------------------------------------------------
-- 0001 usuario · 0002 analista · 0003 administrador · 0004 analista suspendida · 0005 administrador de baja.
-- 0009 tiene sesión pero ninguna fila en perfiles.
-- Suspender llega con HU-010 (R2): por eso las cuentas no activas se crean ya así (CA-2).
-- Los triggers se inhabilitan solo al crear las filas de auth.users, para que estas pruebas no
-- dependan del trigger que HU-002 agrega sobre esa tabla; las llaves foráneas de perfiles siguen vigentes.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'suspendida@prueba.test'),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test');
set local session_replication_role = origin;

insert into public.perfiles (id, email, nombre, rol, estado) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario', 'activo'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista de prueba', 'analista', 'activo'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador', 'activo'),
  ('00000000-0000-4000-8000-000000000004', 'suspendida@prueba.test', 'Analista suspendida', 'analista', 'suspendido'),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test', 'Administrador de baja', 'administrador', 'baja');

-- private.rol_actual(): el rol sale de perfiles y solo si la cuenta está activa (docs/03 §4.2) -------
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is(private.rol_actual(), 'usuario'::public.rol_app, 'rol_actual() de una cuenta activa con rol usuario');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is(private.rol_actual(), 'analista'::public.rol_app, 'rol_actual() de una cuenta activa con rol analista');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is(private.rol_actual(), 'administrador'::public.rol_app, 'rol_actual() de una cuenta activa con rol administrador');
-- Los dos tokens siguen trayendo app_estado = activo (token vigente), pero la autorización no los lee (CA-2).
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated", "app_rol": "analista", "app_estado": "activo"}';
select ok(private.rol_actual() is null, 'rol_actual() es NULL con la cuenta suspendida aunque el token siga vigente');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000005", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select ok(private.rol_actual() is null, 'rol_actual() es NULL con la cuenta de baja aunque el token siga vigente');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000009", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select ok(private.rol_actual() is null, 'rol_actual() es NULL si la persona no tiene perfil');
set local request.jwt.claims to '';
select ok(private.rol_actual() is null, 'rol_actual() es NULL sin sesión');

-- private.es_supervisor() -----------------------------------------------------------------------------
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is(private.es_supervisor(), false, 'es_supervisor() es falso para un Usuario');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is(private.es_supervisor(), true, 'es_supervisor() es verdadero para un Analista');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is(private.es_supervisor(), true, 'es_supervisor() es verdadero para un Administrador');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated"}';
select is(private.es_supervisor(), false, 'es_supervisor() es falso para un Analista suspendido');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000005", "role": "authenticated"}';
select is(private.es_supervisor(), false, 'es_supervisor() es falso para un Administrador de baja');
set local request.jwt.claims to '';
select is(private.es_supervisor(), false, 'es_supervisor() es falso sin sesión');

-- Permisos y forma de las funciones (EC-010) ----------------------------------------------------------
select ok(has_function_privilege('authenticated', 'private.rol_actual()', 'execute'), 'authenticated puede ejecutar rol_actual()');
select ok(not has_function_privilege('anon', 'private.rol_actual()', 'execute'), 'anon no puede ejecutar rol_actual()');
select ok(has_function_privilege('authenticated', 'private.es_supervisor()', 'execute'), 'authenticated puede ejecutar es_supervisor()');
select ok(not has_function_privilege('anon', 'private.es_supervisor()', 'execute'), 'anon no puede ejecutar es_supervisor()');
select ok(not has_schema_privilege('authenticated', 'private', 'usage'), 'authenticated sigue sin usar el esquema private');
select is(
  (select count(*)::int from pg_proc p
    where p.oid in ('private.rol_actual()'::regprocedure, 'private.es_supervisor()'::regprocedure,
                    'private.token_personalizado(jsonb)'::regprocedure)
      and p.prosecdef and p.proconfig = array['search_path=""']),
  3, 'rol_actual, es_supervisor y token_personalizado son security definer con search_path vacío');

-- Hook private.token_personalizado: lo ejecuta el servicio de Auth (EC-009) -------------------------------
-- supabase test db se conecta como postgres, que no es miembro de supabase_auth_admin (Supabase reserva esa
-- membresía a los superusuarios), así que el hook no se puede correr con SET ROLE. Se comprueban los permisos
-- que ese rol necesita (execute sobre la función y usage sobre private) y que la función lee perfiles con los
-- privilegios de su dueño, sin que RLS se lo impida. La ejecución real como supabase_auth_admin se comprueba
-- con un inicio de sesión en el stack local (quickstart.md).
select ok(has_function_privilege('supabase_auth_admin', 'private.token_personalizado(jsonb)', 'execute'),
          'supabase_auth_admin puede ejecutar el hook');
select ok(has_schema_privilege('supabase_auth_admin', 'private', 'usage'), 'supabase_auth_admin puede usar el esquema private');
select ok(not has_function_privilege('anon', 'private.token_personalizado(jsonb)', 'execute'), 'anon no puede ejecutar el hook');
select ok(not has_function_privilege('authenticated', 'private.token_personalizado(jsonb)', 'execute'),
          'authenticated no puede ejecutar el hook');
select is((select pg_get_userbyid(proowner)::text from pg_proc where oid = 'private.token_personalizado(jsonb)'::regprocedure),
          (select pg_get_userbyid(relowner)::text from pg_class where oid = 'public.perfiles'::regclass),
          'el hook pertenece al dueño de perfiles, así que lee la tabla con sus privilegios');
select ok(not (select relforcerowsecurity from pg_class where oid = 'public.perfiles'::regclass),
          'perfiles no fuerza RLS sobre su dueño, así que el hook (security definer) no necesita política propia');

do $$
begin
  perform set_config('prueba.hook_analista', private.token_personalizado(jsonb_build_object(
    'user_id', '00000000-0000-4000-8000-000000000002',
    'authentication_method', 'token_refresh',
    'claims', jsonb_build_object('sub', '00000000-0000-4000-8000-000000000002', 'role', 'authenticated', 'aal', 'aal1')
  ))::text, true);
  perform set_config('prueba.hook_suspendida', private.token_personalizado(jsonb_build_object(
    'user_id', '00000000-0000-4000-8000-000000000004',
    'claims', jsonb_build_object('sub', '00000000-0000-4000-8000-000000000004', 'role', 'authenticated')
  ))::text, true);
  perform set_config('prueba.hook_baja', private.token_personalizado(jsonb_build_object(
    'user_id', '00000000-0000-4000-8000-000000000005',
    'claims', jsonb_build_object('sub', '00000000-0000-4000-8000-000000000005', 'role', 'authenticated')
  ))::text, true);
  perform set_config('prueba.hook_sin_perfil', private.token_personalizado(jsonb_build_object(
    'user_id', '00000000-0000-4000-8000-000000000009',
    'claims', jsonb_build_object('sub', '00000000-0000-4000-8000-000000000009', 'role', 'authenticated')
  ))::text, true);
end;
$$;

select is(current_setting('prueba.hook_analista')::jsonb -> 'claims' ->> 'app_rol', 'analista',
          'CA-1: el token de un analista activo trae app_rol = analista');
select is(current_setting('prueba.hook_analista')::jsonb -> 'claims' ->> 'app_estado', 'activo',
          'CA-1: el token de un analista activo trae app_estado = activo');
select is(current_setting('prueba.hook_analista')::jsonb -> 'claims' ->> 'sub', '00000000-0000-4000-8000-000000000002',
          'el hook conserva los demás claims del token');
select is(current_setting('prueba.hook_analista')::jsonb ->> 'authentication_method', 'token_refresh',
          'el hook conserva el resto del evento');
select is(current_setting('prueba.hook_suspendida')::jsonb -> 'claims' ->> 'app_estado', 'suspendido',
          'el token de una cuenta suspendida trae app_estado = suspendido');
select is(current_setting('prueba.hook_suspendida')::jsonb -> 'claims' ->> 'app_rol', 'analista',
          'y su app_rol sigue siendo el de perfiles');
select is(current_setting('prueba.hook_baja')::jsonb -> 'claims' ->> 'app_estado', 'baja',
          'el token de una cuenta de baja trae app_estado = baja');
select is(jsonb_typeof(current_setting('prueba.hook_sin_perfil')::jsonb -> 'claims' -> 'app_rol'), 'null',
          'sin perfil, app_rol va como null');
select is(jsonb_typeof(current_setting('prueba.hook_sin_perfil')::jsonb -> 'claims' -> 'app_estado'), 'null',
          'sin perfil, app_estado va como null');

-- CA-6: la autorización usa perfiles y no el rol que trae el token ----------------------------------------
-- Un Usuario asciende a analista, pero su token todavía dice usuario.
update public.perfiles set rol = 'analista' where id = '00000000-0000-4000-8000-000000000001';
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated", "app_rol": "usuario", "app_estado": "activo"}';
select is(private.rol_actual(), 'analista'::public.rol_app, 'CA-6: rol_actual() usa el rol nuevo de perfiles y no el del token');
set local role authenticated;
select is((select count(*)::int from public.perfiles where id::text like '00000000-0000-4000-8000-00000000000%'), 5,
          'CA-6: la política de lectura ya lo trata como analista aunque el token diga usuario');
reset role;

-- Un Administrador baja a usuario, pero su token todavía dice administrador.
update public.perfiles set rol = 'usuario' where id = '00000000-0000-4000-8000-000000000003';
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is(private.rol_actual(), 'usuario'::public.rol_app, 'CA-6: rol_actual() usa el rol rebajado de perfiles y no el del token');
set local role authenticated;
select is((select count(*)::int from public.perfiles where id::text like '00000000-0000-4000-8000-00000000000%'), 1,
          'CA-6: la política de lectura ya no le deja ver todos los perfiles aunque el token diga administrador');
reset role;

select * from finish();
rollback;

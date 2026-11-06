-- HU-001 · Tabla perfiles: estructura, RLS, lectura por rol, cuenta no activa y escritura directa bloqueada.
-- Criterios: CA-2, CA-3, CA-4 (backlog/E-02-identidad-y-acceso/HU-001-*.md). Reglas: docs/03 §4.2–§4.4, docs/06 §5.1 y §7.
begin;
create extension if not exists pgtap with schema extensions;
select plan(38);

-- Cuentas de prueba ---------------------------------------------------------------------------
-- 0001 usuario · 0002 analista · 0003 administrador · 0004 suspendido (rol usuario) · 0005 de baja.
-- 0009 tiene sesión pero ninguna fila en perfiles.
-- Suspender llega con HU-010 (R2): por eso la cuenta suspendida y la de baja se crean ya así (CA-2).
-- Los triggers se inhabilitan solo al crear las filas de auth.users, para que estas pruebas no
-- dependan del trigger que HU-002 agrega sobre esa tabla; las llaves foráneas de perfiles siguen vigentes.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test'),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test');
set local session_replication_role = origin;

-- La fila del usuario omite estado, recibe_sugerencias, preferencias_push y version: usa sus valores por defecto.
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario');
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista de prueba', 'analista', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test', 'Suspendido de prueba', 'usuario', 'suspendido', now(), null),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test', 'De baja de prueba', 'usuario', 'baja', null, now());

-- Estructura (docs/06 §3 y §5.1) ----------------------------------------------------------------
select has_type('public', 'rol_app', 'existe el tipo rol_app');
select enum_has_labels('public', 'rol_app', array['usuario', 'analista', 'administrador'],
                       'rol_app tiene los tres roles');
select has_type('public', 'estado_cuenta', 'existe el tipo estado_cuenta');
select enum_has_labels('public', 'estado_cuenta', array['activo', 'suspendido', 'baja'],
                       'estado_cuenta tiene los tres estados');
select has_table('public', 'perfiles', 'existe la tabla perfiles');
select columns_are('public', 'perfiles', array[
  'id', 'email', 'nombre', 'rol', 'estado', 'recibe_sugerencias', 'preferencias_push',
  'invitacion_id', 'suspendido_en', 'baja_en', 'creado_en', 'actualizado_en', 'version'
], 'perfiles tiene las columnas de docs/06 §5.1');
select fk_ok('public', 'perfiles', 'id', 'auth', 'users', 'id', 'perfiles.id referencia a auth.users');
select is(
  (select (estado, recibe_sugerencias, preferencias_push, version)::text
     from public.perfiles where id = '00000000-0000-4000-8000-000000000001'),
  '(activo,t,{},1)',
  'los valores por defecto son estado activo, recibe_sugerencias, preferencias vacías y versión 1');
select throws_ok(
  $$insert into public.perfiles (id, email, nombre, rol) values (gen_random_uuid(), 'Mayusculas@prueba.test', 'x', 'usuario')$$,
  '23514', null, 'el correo debe estar en minúsculas');
select throws_ok(
  $$update public.perfiles set email = 'usuario@prueba.test' where id = '00000000-0000-4000-8000-000000000002'$$,
  '23505', null, 'el correo es único');

-- RLS activo, una sola política y sin privilegios de escritura (CA-4, FR-020) ---------------------
select ok((select relrowsecurity from pg_class where oid = 'public.perfiles'::regclass), 'perfiles tiene RLS activo');
select is((select count(*)::int from pg_policies where schemaname = 'public' and tablename = 'perfiles'), 1,
          'perfiles tiene una sola política');
select is((select cmd from pg_policies where schemaname = 'public' and tablename = 'perfiles'), 'SELECT',
          'la única política es de lectura');
select is((select roles::text from pg_policies where schemaname = 'public' and tablename = 'perfiles'), '{authenticated}',
          'la política de lectura es para authenticated');
select table_privs_are('public', 'perfiles', 'authenticated', array['SELECT'],
                       'authenticated solo tiene select sobre perfiles');
select table_privs_are('public', 'perfiles', 'anon', array[]::text[], 'anon no tiene ningún privilegio sobre perfiles');

-- Lectura por rol (CA-3) --------------------------------------------------------------------------
set local role authenticated;

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select count(*)::int from public.perfiles where id::text like '00000000-0000-4000-8000-00000000000%'), 1,
          'un Usuario ve una sola fila de perfiles');
select is((select id from public.perfiles where id::text like '00000000-0000-4000-8000-00000000000%'),
          '00000000-0000-4000-8000-000000000001'::uuid, 'y esa fila es la suya');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is((select count(*)::int from public.perfiles where id::text like '00000000-0000-4000-8000-00000000000%'), 5,
          'un Analista ve todos los perfiles');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is((select count(*)::int from public.perfiles where id::text like '00000000-0000-4000-8000-00000000000%'), 5,
          'un Administrador ve todos los perfiles');

-- Cuenta no activa: token vigente, ninguna fila (CA-2) -------------------------------------------
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is((select count(*)::int from public.perfiles), 0,
          'una cuenta suspendida con token vigente no recibe ninguna fila, ni la suya');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000005", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is((select count(*)::int from public.perfiles), 0,
          'una cuenta de baja con token vigente no recibe ninguna fila');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000009", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is((select count(*)::int from public.perfiles), 0, 'una sesión sin perfil no recibe ninguna fila');

set local request.jwt.claims to '';
select is((select count(*)::int from public.perfiles), 0, 'sin identidad en el token no se recibe ninguna fila');

reset role;

set local role anon;
select throws_ok($$select * from public.perfiles$$, '42501', null, 'anon no puede leer perfiles');
reset role;

-- Escritura directa bloqueada para cualquier rol (CA-4) -------------------------------------------
set local role authenticated;

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select throws_ok(
  $$insert into public.perfiles (id, email, nombre, rol) values (gen_random_uuid(), 'otro@prueba.test', 'Otro', 'administrador')$$,
  '42501', null, 'un Usuario no puede insertar en perfiles');
select throws_ok($$update public.perfiles set rol = 'administrador' where id = '00000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'un Usuario no puede subirse el rol');
select throws_ok($$delete from public.perfiles where id = '00000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'un Usuario no puede borrar su perfil');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select throws_ok(
  $$insert into public.perfiles (id, email, nombre, rol) values (gen_random_uuid(), 'otro@prueba.test', 'Otro', 'usuario')$$,
  '42501', null, 'un Analista no puede insertar en perfiles');
select throws_ok($$update public.perfiles set estado = 'suspendido' where id = '00000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'un Analista no puede cambiar el estado de un perfil');
select throws_ok($$delete from public.perfiles where id = '00000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'un Analista no puede borrar un perfil');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok(
  $$insert into public.perfiles (id, email, nombre, rol) values (gen_random_uuid(), 'otro@prueba.test', 'Otro', 'usuario')$$,
  '42501', null, 'un Administrador no puede insertar en perfiles');
select throws_ok($$update public.perfiles set rol = 'analista' where id = '00000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'un Administrador no puede cambiar el rol directo en la tabla');
select throws_ok($$delete from public.perfiles where id = '00000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'un Administrador no puede borrar un perfil');

reset role;

set local role anon;
select throws_ok(
  $$insert into public.perfiles (id, email, nombre, rol) values (gen_random_uuid(), 'otro@prueba.test', 'Otro', 'usuario')$$,
  '42501', null, 'anon no puede insertar en perfiles');
select throws_ok($$update public.perfiles set rol = 'administrador'$$, '42501', null, 'anon no puede actualizar perfiles');
select throws_ok($$delete from public.perfiles$$, '42501', null, 'anon no puede borrar perfiles');
reset role;

select is(
  (select string_agg(right(id::text, 1) || ':' || rol || ':' || estado, ',' order by id)
     from public.perfiles where id::text like '00000000-0000-4000-8000-00000000000%'),
  '1:usuario:activo,2:analista:activo,3:administrador:activo,4:usuario:suspendido,5:usuario:baja',
  'los intentos de escritura no cambiaron ningún perfil');

select * from finish();
rollback;

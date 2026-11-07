-- HU-107 · Tabla auditoria: estructura, RLS, permisos de escritura y lectura por rol.
-- Criterios: CA-3 (permiso: ningún rol de la API escribe, ni la llave secreta) y CA-5 (aislamiento: un
-- Usuario o un Analista no recibe filas). Reglas: docs/06 §5.6 y §7, docs/03 §4.3, docs/11 §4.3 y §4.4.
begin;
create extension if not exists pgtap with schema extensions;
select plan(54);

-- Cuentas de prueba ---------------------------------------------------------------------------
-- 0001 usuario · 0002 analista · 0003 administrador · 0004 administrador suspendido ·
-- 0005 administrador de baja · 0009 con sesión pero sin fila en perfiles.
-- Los triggers se inhabilitan solo al crear las filas de auth.users, para que estas pruebas no dependan
-- del trigger que HU-002 agrega sobre esa tabla.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test'),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test');
set local session_replication_role = origin;

insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista de prueba', 'analista', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test', 'Suspendido de prueba', 'administrador', 'suspendido', now(), null),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test', 'De baja de prueba', 'administrador', 'baja', null, now());

-- Tres registros insertados por el dueño con valores literales: en esta capa private.auditar() aún no existe.
insert into public.auditoria (momento, accion, entidad, entidad_id, origen, hash_anterior, hash) values
  ('2026-01-01 00:00:00+00', 'prueba.uno', 'prueba05', '1', 'sistema', repeat('a', 64), repeat('1', 64)),
  ('2026-01-01 00:00:01+00', 'prueba.dos', 'prueba05', '2', 'sistema', repeat('1', 64), repeat('2', 64)),
  ('2026-01-01 00:00:02+00', 'prueba.tres', 'prueba05', '3', 'sistema', repeat('2', 64), repeat('3', 64));

-- Estructura (docs/06 §5.6) ----------------------------------------------------------------------
select has_table('public', 'auditoria', 'existe la tabla auditoria');
select columns_are('public', 'auditoria', array[
  'id', 'momento', 'actor_id', 'actor_rol', 'accion', 'entidad', 'entidad_id',
  'antes', 'despues', 'detalle', 'origen', 'hash_anterior', 'hash'
], 'auditoria tiene las columnas de docs/06 §5.6');
select col_is_pk('public', 'auditoria', 'id', 'id es la clave primaria');
select col_is_unique('public', 'auditoria', array['hash_anterior'], 'hash_anterior es único');
select col_type_is('public', 'auditoria', 'id', 'bigint', 'id es bigint');
select col_type_is('public', 'auditoria', 'momento', 'timestamp with time zone', 'momento es timestamptz');
select col_type_is('public', 'auditoria', 'actor_rol', 'public', 'rol_app', 'actor_rol usa el tipo rol_app');
select is(
  (select array_agg(a.attname::text order by a.attnum)
     from pg_attribute a
    where a.attrelid = 'public.auditoria'::regclass and a.attnum > 0 and not a.attisdropped and a.attnotnull),
  array['id', 'momento', 'accion', 'entidad', 'origen', 'hash_anterior', 'hash'],
  'son obligatorias id, momento, acción, entidad, origen y los dos hashes; actor, valores y detalle pueden ser nulos');
select throws_ok(
  $$insert into public.auditoria (id, momento, accion, entidad, origen, hash_anterior, hash)
    values (99, now(), 'x', 'x', 'app', repeat('e', 64), repeat('f', 64))$$,
  '428C9', null, 'el id lo genera la base de datos y no se puede fijar a mano');
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x', 'x', 'otro', repeat('e', 64), repeat('f', 64))$$,
  '23514', null, 'el origen solo puede ser app, sistema, cron o auth');
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), '  ', 'x', 'app', repeat('e', 64), repeat('f', 64))$$,
  '23514', null, 'la acción no puede estar vacía');
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x', '', 'app', repeat('e', 64), repeat('f', 64))$$,
  '23514', null, 'la entidad no puede estar vacía');
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x', 'x', 'app', repeat('e', 64), repeat('F', 64))$$,
  '23514', null, 'el hash debe ser hexadecimal en minúsculas de 64 caracteres');
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x', 'x', 'app', repeat('e', 63), repeat('f', 64))$$,
  '23514', null, 'el hash anterior también debe tener 64 caracteres');
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x', 'x', 'app', repeat('1', 64), repeat('f', 64))$$,
  '23505', null, 'dos registros no pueden colgar del mismo hash anterior');

-- RLS activo, una sola política de lectura y sin privilegios de escritura (CA-3) ---------------------
select ok((select relrowsecurity from pg_class where oid = 'public.auditoria'::regclass), 'auditoria tiene RLS activo');
select is((select count(*)::int from pg_policies where schemaname = 'public' and tablename = 'auditoria'), 1,
          'auditoria tiene una sola política');
select is((select cmd from pg_policies where schemaname = 'public' and tablename = 'auditoria'), 'SELECT',
          'la única política es de lectura');
select is((select roles::text from pg_policies where schemaname = 'public' and tablename = 'auditoria'), '{authenticated}',
          'la política de lectura es para authenticated');
select table_privs_are('public', 'auditoria', 'authenticated', array['SELECT'],
                       'authenticated solo tiene select sobre auditoria');
select table_privs_are('public', 'auditoria', 'anon', array[]::text[], 'anon no tiene ningún privilegio sobre auditoria');
select table_privs_are('public', 'auditoria', 'service_role', array[]::text[],
                       'service_role (la llave secreta) no tiene ningún privilegio sobre auditoria');
select sequence_privs_are('public', 'auditoria_id_seq', 'authenticated', array[]::text[],
                          'authenticated no tiene privilegios sobre la secuencia del id');
select sequence_privs_are('public', 'auditoria_id_seq', 'anon', array[]::text[],
                          'anon no tiene privilegios sobre la secuencia del id');
select sequence_privs_are('public', 'auditoria_id_seq', 'service_role', array[]::text[],
                          'service_role no tiene privilegios sobre la secuencia del id');

-- Lectura por rol (CA-5) -------------------------------------------------------------------------
set local role authenticated;

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is((select count(*)::int from public.auditoria where entidad = 'prueba05'), 3,
          'un Administrador ve todos los registros de la bitácora');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select count(*)::int from public.auditoria), 0, 'un Usuario no recibe filas de la bitácora');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is((select count(*)::int from public.auditoria), 0, 'un Analista no recibe filas de la bitácora');

-- Cuenta no activa: token vigente que dice administrador, ninguna fila.
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is((select count(*)::int from public.auditoria), 0,
          'un Administrador suspendido con token vigente no recibe filas');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000005", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is((select count(*)::int from public.auditoria), 0,
          'un Administrador de baja con token vigente no recibe filas');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000009", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is((select count(*)::int from public.auditoria), 0, 'una sesión sin perfil no recibe filas');

set local request.jwt.claims to '';
select is((select count(*)::int from public.auditoria), 0, 'sin identidad en el token no se recibe ninguna fila');

reset role;

set local role anon;
select throws_ok($$select * from public.auditoria$$, '42501', null, 'anon no puede leer auditoria');
reset role;

-- Escritura directa bloqueada para todos los roles de la API (CA-3) -----------------------------------
set local role anon;
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x', 'x', 'app', repeat('e', 64), repeat('f', 64))$$,
  '42501', null, 'anon no puede insertar en auditoria');
select throws_ok($$update public.auditoria set accion = 'x'$$, '42501', null, 'anon no puede actualizar auditoria');
select throws_ok($$delete from public.auditoria$$, '42501', null, 'anon no puede borrar de auditoria');
select throws_ok($$truncate public.auditoria$$, '42501', null, 'anon no puede vaciar auditoria');
reset role;

set local role authenticated;

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x', 'x', 'app', repeat('e', 64), repeat('f', 64))$$,
  '42501', null, 'un Usuario no puede insertar en auditoria');
select throws_ok($$update public.auditoria set accion = 'x'$$, '42501', null, 'un Usuario no puede actualizar auditoria');
select throws_ok($$delete from public.auditoria$$, '42501', null, 'un Usuario no puede borrar de auditoria');
select throws_ok($$truncate public.auditoria$$, '42501', null, 'un Usuario no puede vaciar auditoria');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x', 'x', 'app', repeat('e', 64), repeat('f', 64))$$,
  '42501', null, 'un Analista no puede insertar en auditoria');
select throws_ok($$update public.auditoria set accion = 'x'$$, '42501', null, 'un Analista no puede actualizar auditoria');
select throws_ok($$delete from public.auditoria$$, '42501', null, 'un Analista no puede borrar de auditoria');
select throws_ok($$truncate public.auditoria$$, '42501', null, 'un Analista no puede vaciar auditoria');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x', 'x', 'app', repeat('e', 64), repeat('f', 64))$$,
  '42501', null, 'un Administrador no puede insertar en auditoria');
select throws_ok($$update public.auditoria set accion = 'x'$$, '42501', null, 'un Administrador no puede actualizar auditoria');
select throws_ok($$delete from public.auditoria$$, '42501', null, 'un Administrador no puede borrar de auditoria');
select throws_ok($$truncate public.auditoria$$, '42501', null, 'un Administrador no puede vaciar auditoria');

reset role;

-- La llave secreta (service_role) salta RLS, así que solo la frena el privilegio revocado.
set local role service_role;
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x', 'x', 'app', repeat('e', 64), repeat('f', 64))$$,
  '42501', null, 'service_role no puede insertar en auditoria');
select throws_ok($$update public.auditoria set accion = 'x'$$, '42501', null, 'service_role no puede actualizar auditoria');
select throws_ok($$delete from public.auditoria$$, '42501', null, 'service_role no puede borrar de auditoria');
select throws_ok($$truncate public.auditoria$$, '42501', null, 'service_role no puede vaciar auditoria');
reset role;

select is(
  (select string_agg(accion, ',' order by id) from public.auditoria where entidad = 'prueba05'),
  'prueba.uno,prueba.dos,prueba.tres',
  'los intentos de escritura no cambiaron ningún registro');

select * from finish();
rollback;

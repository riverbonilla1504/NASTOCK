-- HU-002 · Alta solo con invitación vigente: tablas, hook antes de crear usuario, trigger de alta
-- y sincronización del correo.
-- Criterios: CA-1 a CA-6 (backlog/E-02-identidad-y-acceso/HU-002-*.md). Reglas: docs/04 §5, §6 y §11,
-- docs/12 CB-01, CB-02, CB-05, CB-92. CA-7 (ingreso de prueba) lo cubre el E2E-02.
begin;
create extension if not exists pgtap with schema extensions;
select plan(39);

-- Configuración como en la nube: solo Google y un dominio ----------------------------------------
update public.parametros set valor = '["google"]'::jsonb where clave = 'auth.proveedores_permitidos';
update public.parametros set valor = '["ritech.test"]'::jsonb where clave = 'auth.dominios_permitidos';

-- Cuentas: 0003 administrador (sin pasar por el alta, para probar la lectura de invitaciones) y 0001 usuario.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador');

-- Invitaciones --------------------------------------------------------------------------------
insert into public.invitaciones (email, rol, cupo_inicial) values
  ('vigente@ritech.test', 'analista', 0),
  ('mayus@ritech.test', 'usuario', 100);
insert into public.invitaciones (email, rol, expira_en) values
  ('vencida@ritech.test', 'usuario', now() - interval '1 day');
insert into public.invitaciones (email, rol, estado, revocada_en) values
  ('revocada@ritech.test', 'usuario', 'revocada', now());
insert into public.invitaciones (email, rol, estado, aceptada_en) values
  ('aceptada@ritech.test', 'usuario', 'aceptada', now());
insert into public.invitaciones (email, rol) values ('otrodominio@otra.test', 'usuario');

-- Estructura (RLS, índice único, permisos) ------------------------------------------------------
select ok((select relrowsecurity from pg_class where oid = 'public.invitaciones'::regclass), 'invitaciones tiene RLS activo');
select ok((select relrowsecurity from pg_class where oid = 'public.parametros'::regclass), 'parametros tiene RLS activo');
select throws_ok(
  $$insert into public.invitaciones (email, rol) values ('vigente@ritech.test', 'usuario')$$,
  '23505', null, 'no puede haber dos invitaciones pendientes para el mismo correo');
select lives_ok(
  $$insert into public.invitaciones (email, rol, estado) values ('revocada@ritech.test', 'usuario', 'revocada')$$,
  'sí puede haber varias no pendientes para el mismo correo');
select fk_ok('public', 'perfiles', 'invitacion_id', 'public', 'invitaciones', 'id',
             'perfiles.invitacion_id referencia a invitaciones');
select table_privs_are('public', 'invitaciones', 'authenticated', array['SELECT'],
                       'authenticated solo tiene select sobre invitaciones');
select table_privs_are('public', 'invitaciones', 'anon', array[]::text[], 'anon no tiene privilegios sobre invitaciones');
select table_privs_are('public', 'parametros', 'authenticated', array['SELECT'],
                       'authenticated solo tiene select sobre parametros');
select is((select valor::text from public.parametros where clave = 'auth.dominios_permitidos'), '["ritech.test"]',
          'la clave auth.dominios_permitidos existe (aquí con el dominio de la prueba)');

-- Lectura por rol -------------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select count(*)::int from public.invitaciones), 0, 'un Usuario no lee invitaciones');
select cmp_ok((select count(*)::int from public.parametros), '>=', 2, 'un Usuario activo sí lee los parámetros');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select cmp_ok((select count(*)::int from public.invitaciones), '>=', 6, 'el Administrador lee las invitaciones');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000009", "role": "authenticated"}';
select is((select count(*)::int from public.parametros), 0, 'quien no tiene perfil no lee los parámetros');
reset role;

-- Hook antes de crear usuario (EC-009). No se puede asumir supabase_auth_admin desde la prueba (solo un
-- superusuario puede otorgar su rol): se comprueban sus permisos y el hook se ejecuta como postgres; el E2E-02
-- lo ejercita con el servicio de Auth real ------------------------
select ok(has_function_privilege('supabase_auth_admin', 'private.antes_de_crear_usuario(jsonb)', 'execute'),
          'supabase_auth_admin ejecuta el hook');
select ok(not has_function_privilege('authenticated', 'private.antes_de_crear_usuario(jsonb)', 'execute'),
          'authenticated no ejecuta el hook');
select ok(not has_function_privilege('anon', 'private.antes_de_crear_usuario(jsonb)', 'execute'),
          'anon no ejecuta el hook');
select ok(has_table_privilege('supabase_auth_admin', 'public.invitaciones', 'select')
          and has_table_privilege('supabase_auth_admin', 'public.parametros', 'select'),
          'supabase_auth_admin puede leer invitaciones y parametros');
select is((select count(*)::int from pg_policies
            where tablename in ('invitaciones', 'parametros') and roles = '{supabase_auth_admin}'), 2,
          'y tiene una política de lectura en cada una');


select is(private.antes_de_crear_usuario('{"user": {"email": "vigente@ritech.test", "app_metadata": {"provider": "google"}}}'),
          '{}'::jsonb, 'CA-1: invitación pendiente y vigente, dominio y proveedor permitidos: acepta');
select is(private.antes_de_crear_usuario('{"user": {"email": "MAYUS@Ritech.Test", "app_metadata": {"provider": "google"}}}'),
          '{}'::jsonb, 'el correo se compara en minúsculas');
select is(private.antes_de_crear_usuario('{"user": {"email": "sininvitar@ritech.test", "app_metadata": {"provider": "google"}}}'),
          '{"error": {"http_code": 403, "message": "Tu correo no tiene una invitación vigente. Pídele una al administrador."}}'::jsonb,
          'CA-2 (CB-01): sin invitación, rechaza con su mensaje');
select is(private.antes_de_crear_usuario('{"user": {"email": "vencida@ritech.test", "app_metadata": {"provider": "google"}}}'),
          '{"error": {"http_code": 403, "message": "Tu correo no tiene una invitación vigente. Pídele una al administrador."}}'::jsonb,
          'CA-3 (CB-02): invitación vencida, mismo rechazo');
select is(private.antes_de_crear_usuario('{"user": {"email": "revocada@ritech.test", "app_metadata": {"provider": "google"}}}')
            -> 'error' ->> 'message',
          'Tu correo no tiene una invitación vigente. Pídele una al administrador.', 'una invitación revocada no sirve');
select is(private.antes_de_crear_usuario('{"user": {"email": "aceptada@ritech.test", "app_metadata": {"provider": "google"}}}')
            -> 'error' ->> 'message',
          'Tu correo no tiene una invitación vigente. Pídele una al administrador.', 'una invitación ya aceptada no sirve');
select is(private.antes_de_crear_usuario('{"user": {"email": "otrodominio@otra.test", "app_metadata": {"provider": "google"}}}'),
          '{"error": {"http_code": 403, "message": "Solo se admiten cuentas corporativas de RiTech."}}'::jsonb,
          'CA-4: dominio no permitido, rechaza con su mensaje aunque haya invitación');
select is(private.antes_de_crear_usuario('{"user": {"email": "vigente@ritech.test", "app_metadata": {"provider": "email"}}}'),
          '{"error": {"http_code": 403, "message": "Solo puedes ingresar con tu cuenta de Google de RiTech."}}'::jsonb,
          'CA-5 (CB-92): proveedor de correo no permitido, rechaza con su mensaje');
select is(private.antes_de_crear_usuario('{"user": {"email": "vigente@ritech.test", "app_metadata": {}}}') -> 'error' ->> 'http_code',
          '403', 'sin proveedor informado, rechaza');


-- La invitación se vence con el reloj (private.ahora) -------------------------------------------
select pruebas.fijar_reloj(now() + interval '8 days');
select is(private.antes_de_crear_usuario('{"user": {"email": "vigente@ritech.test", "app_metadata": {"provider": "google"}}}')
            -> 'error' ->> 'message',
          'Tu correo no tiene una invitación vigente. Pídele una al administrador.',
          'CB-02: pasados 7 días la invitación pendiente deja de servir');
select pruebas.fijar_reloj(null);

-- Trigger de alta (CA-1) ------------------------------------------------------------------------
select throws_ok(
  $$insert into auth.users (id, email) values ('00000000-0000-4000-8000-0000000000a1', 'sininvitar@ritech.test')$$,
  'P0001', null, 'el trigger no crea un usuario sin invitación pendiente');

insert into auth.users (id, email, raw_user_meta_data)
values ('00000000-0000-4000-8000-0000000000a2', 'Vigente@Ritech.Test', '{"full_name": "Persona Vigente"}');

select is((select (rol, estado, email, nombre)::text from public.perfiles where id = '00000000-0000-4000-8000-0000000000a2'),
          '(analista,activo,vigente@ritech.test,"Persona Vigente")',
          'CA-1: se crea el perfil activo con el rol de la invitación');
select is((select estado::text from public.invitaciones where lower(email) = 'vigente@ritech.test' and estado <> 'pendiente'),
          'aceptada', 'CA-1: la invitación queda aceptada');
select is((select usuario_id from public.invitaciones where lower(email) = 'vigente@ritech.test'),
          '00000000-0000-4000-8000-0000000000a2'::uuid, 'la invitación apunta al usuario');
select isnt((select aceptada_en from public.invitaciones where lower(email) = 'vigente@ritech.test'), null,
            'la invitación registra cuándo se aceptó');
select is((select invitacion_id from public.perfiles where id = '00000000-0000-4000-8000-0000000000a2'),
          (select id from public.invitaciones where lower(email) = 'vigente@ritech.test'),
          'el perfil guarda la invitación que lo originó');
select is((select (accion, entidad, entidad_id, actor_id, origen, detalle)::text from public.auditoria
            where accion = 'cuenta.activada' and entidad_id = '00000000-0000-4000-8000-0000000000a2'),
          '(cuenta.activada,perfiles,00000000-0000-4000-8000-0000000000a2,00000000-0000-4000-8000-0000000000a2,auth,"{""rol"": ""analista""}")',
          'CA-1: se registra cuenta.activada');

-- Sincronización del correo (CA-6, CB-05) ------------------------------------------------------
update auth.users set email = 'nuevo@Ritech.Test' where id = '00000000-0000-4000-8000-0000000000a2';
select is((select email from public.perfiles where id = '00000000-0000-4000-8000-0000000000a2'), 'nuevo@ritech.test',
          'CA-6: perfiles.email se actualiza, en minúsculas');
select is((select (antes, despues, origen)::text from public.auditoria
            where accion = 'cuenta.correo_cambiado' and entidad_id = '00000000-0000-4000-8000-0000000000a2'),
          '("{""email"": ""vigente@ritech.test""}","{""email"": ""nuevo@ritech.test""}",auth)',
          'CA-6: el cambio queda en la bitácora con el correo anterior y el nuevo');
update auth.users set email = 'NUEVO@ritech.test' where id = '00000000-0000-4000-8000-0000000000a2';
select is((select count(*)::int from public.auditoria where accion = 'cuenta.correo_cambiado'), 1,
          'un cambio que no altera el correo (solo mayúsculas) no se vuelve a registrar');
update auth.users set raw_user_meta_data = '{"full_name": "Otro"}' where id = '00000000-0000-4000-8000-0000000000a2';
select is((select count(*)::int from public.auditoria where accion = 'cuenta.correo_cambiado'), 1,
          'otros cambios en auth.users no se registran como cambio de correo');

select * from finish();
rollback;

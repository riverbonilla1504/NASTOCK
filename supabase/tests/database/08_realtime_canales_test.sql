-- HU-083 · Canales privados de tiempo real: quién escucha cada canal, cuenta no activa,
-- publicación de clientes bloqueada y carga de los eventos sin montos.
-- Criterios: CA-1 a CA-5 (backlog/E-09-tiempo-real-y-notificaciones/HU-083-*.md). Reglas: docs/09 §3 y §4.
begin;
create extension if not exists pgtap with schema extensions;
select plan(46);

-- Cuentas de prueba: 0001 usuario · 0002 analista · 0003 administrador · 0004 suspendido (rol administrador) · 0005 de baja.
-- Suspender llega con HU-010 (R2): por eso la cuenta suspendida se crea ya así (CA-5).
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test'),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario');
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista de prueba', 'analista', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test', 'Suspendido de prueba', 'administrador', 'suspendido', now(), null),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test', 'De baja de prueba', 'usuario', 'baja', null, now());

-- Estructura -----------------------------------------------------------------------------------
select is((select count(*)::int from pg_policies where schemaname = 'realtime' and tablename = 'messages' and policyname = 'canales_permitidos'), 1,
          'existe la política canales_permitidos sobre realtime.messages');
select is((select cmd from pg_policies where schemaname = 'realtime' and tablename = 'messages' and policyname = 'canales_permitidos'), 'SELECT',
          'canales_permitidos es de lectura');
select is((select count(*)::int from pg_policies where schemaname = 'realtime' and tablename = 'messages' and cmd in ('INSERT', 'ALL')), 0,
          'realtime.messages no tiene política de INSERT');
select has_function('private', 'publicar_evento', array['text', 'text', 'jsonb'], 'existe private.publicar_evento');
select has_function('private', 'carga_evento', array['text', 'text', 'integer', 'text'], 'existe private.carga_evento');
select ok(not has_function_privilege('authenticated', 'private.publicar_evento(text, text, jsonb)', 'execute'),
          'authenticated no puede ejecutar publicar_evento');
select ok(not has_function_privilege('anon', 'private.publicar_evento(text, text, jsonb)', 'execute'),
          'anon no puede ejecutar publicar_evento');

-- Publicación: un mensaje por canal, hecho por la base de datos ---------------------------------
select lives_ok($$select private.publicar_evento('mercado', 'ev_mercado', '{"momento": "x"}')$$, 'se publica en mercado');
select lives_ok($$select private.publicar_evento('fondo', 'ev_fondo', '{}')$$, 'se publica en fondo');
select lives_ok($$select private.publicar_evento('usuario:00000000-0000-4000-8000-000000000001', 'ev_u1', '{}')$$, 'se publica en el canal del usuario 1');
select lives_ok($$select private.publicar_evento('usuario:00000000-0000-4000-8000-000000000002', 'ev_u2', '{}')$$, 'se publica en el canal del analista');
select lives_ok($$select private.publicar_evento('supervision', 'ev_supervision', '{}')$$, 'se publica en supervision');
select lives_ok($$select private.publicar_evento('admin', 'ev_admin', '{}')$$, 'se publica en admin');
select throws_ok($$select private.publicar_evento('otro', 'x', '{}')$$, '22023', null, 'un canal desconocido se rechaza');
select throws_ok($$select private.publicar_evento('usuario:no-es-uuid', 'x', '{}')$$, '22023', null, 'usuario:{algo que no es uuid} se rechaza');
select throws_ok($$select private.publicar_evento('mercado', '', '{}')$$, '22023', null, 'un evento sin nombre se rechaza');
select is((select count(*)::int from realtime.messages where private and event like 'ev\_%'), 6,
          'los seis mensajes quedaron como privados');

-- Carga de los eventos de entidad (CA-4) --------------------------------------------------------
select is(private.carga_evento('sugerencias', '5f1c0000-0000-4000-8000-000000000000', 4, 'aprobada'),
          '{"tabla": "sugerencias", "id": "5f1c0000-0000-4000-8000-000000000000", "version": 4, "estado": "aprobada"}'::jsonb,
          'la carga de un evento de entidad trae tabla, id, versión y estado');
select is((select array_agg(k order by k) from jsonb_object_keys(private.carga_evento('t', gen_random_uuid()::text, 1, 'e')) k),
          array['estado', 'id', 'tabla', 'version'], 'y ninguna otra clave: sin montos');
select is(private.carga_evento('parametros', 'mercado.minutos_tras_apertura', 3, null),
          '{"tabla": "parametros", "id": "mercado.minutos_tras_apertura", "version": 3, "estado": null}'::jsonb,
          'una entidad con clave de texto y sin estado conserva las cuatro claves');
select ok(not has_function_privilege('authenticated', 'private.carga_evento(text, text, integer, text)', 'execute'),
          'authenticated no puede ejecutar carga_evento');

-- Escucha por rol (CA-1, CA-2, CA-5) ------------------------------------------------------------
-- Abre el canal (realtime.topic) y dice si la política deja ver el mensaje de prueba.
create function pg_temp.ve(p_topico text, p_evento text) returns boolean
language plpgsql as $$
begin
  perform set_config('realtime.topic', p_topico, true);
  return exists (select 1 from realtime.messages where event = p_evento);
end $$;
grant execute on function pg_temp.ve(text, text) to authenticated, anon;

set local role authenticated;

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select ok(pg_temp.ve('mercado', 'ev_mercado'), 'Usuario: escucha mercado');
select ok(pg_temp.ve('fondo', 'ev_fondo'), 'Usuario: escucha fondo');
select ok(pg_temp.ve('usuario:00000000-0000-4000-8000-000000000001', 'ev_u1'), 'Usuario: escucha su canal');
select ok(not pg_temp.ve('usuario:00000000-0000-4000-8000-000000000002', 'ev_u2'), 'Usuario: no escucha el canal de otra persona');
select ok(not pg_temp.ve('supervision', 'ev_supervision'), 'Usuario: no escucha supervision');
select ok(not pg_temp.ve('admin', 'ev_admin'), 'Usuario: no escucha admin');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select ok(pg_temp.ve('mercado', 'ev_mercado') and pg_temp.ve('fondo', 'ev_fondo'), 'Analista: escucha mercado y fondo');
select ok(pg_temp.ve('usuario:00000000-0000-4000-8000-000000000002', 'ev_u2'), 'Analista: escucha su canal');
select ok(not pg_temp.ve('usuario:00000000-0000-4000-8000-000000000001', 'ev_u1'), 'Analista: no escucha el canal de otra persona');
select ok(pg_temp.ve('supervision', 'ev_supervision'), 'Analista: escucha supervision');
select ok(not pg_temp.ve('admin', 'ev_admin'), 'Analista: no escucha admin');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select ok(pg_temp.ve('mercado', 'ev_mercado') and pg_temp.ve('fondo', 'ev_fondo'), 'Administrador: escucha mercado y fondo');
select ok(pg_temp.ve('supervision', 'ev_supervision'), 'Administrador: escucha supervision');
select ok(pg_temp.ve('admin', 'ev_admin'), 'Administrador: escucha admin');
select ok(not pg_temp.ve('usuario:00000000-0000-4000-8000-000000000001', 'ev_u1'), 'Administrador: no escucha el canal de otra persona');

-- Cuenta no activa: token vigente, ningún canal (CA-5) -------------------------------------------
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select ok(not pg_temp.ve('mercado', 'ev_mercado'), 'Suspendido: no escucha mercado');
select ok(not pg_temp.ve('fondo', 'ev_fondo'), 'Suspendido: no escucha fondo');
select ok(not pg_temp.ve('supervision', 'ev_supervision') and not pg_temp.ve('admin', 'ev_admin'),
          'Suspendido: no escucha supervision ni admin, aunque su rol sea administrador');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000005", "role": "authenticated"}';
select ok(not pg_temp.ve('mercado', 'ev_mercado'), 'De baja: no escucha mercado');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000009", "role": "authenticated"}';
select ok(not pg_temp.ve('mercado', 'ev_mercado'), 'Sesión sin perfil: no escucha mercado');

-- Publicación de clientes bloqueada (CA-3) ----------------------------------------------------------
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok(
  $$insert into realtime.messages (topic, extension, payload, event, private) values ('admin', 'broadcast', '{}', 'x', true)$$,
  '42501', null, 'un Administrador no puede insertar mensajes en admin');
select throws_ok(
  $$insert into realtime.messages (topic, extension, payload, event, private) values ('mercado', 'broadcast', '{}', 'x', true)$$,
  '42501', null, 'un cliente con sesión no puede publicar en mercado');
select throws_ok($$select private.publicar_evento('mercado', 'x', '{}')$$, '42501', null,
                 'un cliente con sesión no puede usar private.publicar_evento');
reset role;

set local role anon;
select ok(not pg_temp.ve('mercado', 'ev_mercado'), 'anon no escucha mercado');
select throws_ok(
  $$insert into realtime.messages (topic, extension, payload, event, private) values ('mercado', 'broadcast', '{}', 'x', true)$$,
  '42501', null, 'anon no puede publicar');
reset role;

select * from finish();
rollback;

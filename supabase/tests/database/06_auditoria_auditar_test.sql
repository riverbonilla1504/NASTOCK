-- HU-107 · private.auditar(): el registro, el encadenado del hash, la concurrencia y que no guarda secretos.
-- Criterios: CA-1, CA-2 y CA-4 (backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-107-*.md).
-- Reglas: docs/06 §5.6 y §8.2, docs/11 §4.1 y §4.3.
begin;
create extension if not exists pgtap with schema extensions;
-- dblink solo se usa para abrir una segunda conexión en la prueba de concurrencia; se crea dentro de
-- la transacción de la prueba y se deshace con ella, igual que pgtap.
create extension if not exists dblink with schema extensions;
select plan(47);

-- Cuentas de prueba ---------------------------------------------------------------------------
-- 0001 usuario · 0002 analista · 0003 administrador · 0007 con acciones pero sin perfil.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test');
set local session_replication_role = origin;

insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista de prueba', 'analista'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador');

-- La hora sale de private.ahora(): se fija para que el momento sea conocido.
select pruebas.fijar_reloj('2026-03-02 15:30:45.123456+00');

-- Los ids de los registros que crea la prueba, en el orden en que se crean.
create temp table r (n int primary key, id bigint not null);

select is((select count(*)::int from public.auditoria), 0, 'la bitácora arranca vacía');

-- CA-1: el registro con todos sus campos ---------------------------------------------------------
insert into r values (1, private.auditar(
  '00000000-0000-4000-8000-000000000003', 'parametro.cambiado', 'parametros', 'ia.umbral',
  '{"motivo": "ajuste", "b": 1}'::jsonb, '{"valor": 1}'::jsonb, '{"valor": 2}'::jsonb));
insert into r values (2, private.auditar(null, 'integracion.caida', 'salud_integraciones', 'alpaca_broker'));
insert into r values (3, private.auditar(
  '00000000-0000-4000-8000-000000000001', 'cuenta.activada', 'perfiles', '00000000-0000-4000-8000-000000000001',
  '{"rol": "usuario"}'::jsonb, null, null, 'auth'));
insert into r values (4, private.auditar(
  null, 'conciliacion.descuadre', 'conciliaciones', null, '{"diferencia": "0.01"}'::jsonb, p_origen => 'cron'));
insert into r values (5, private.auditar(
  '00000000-0000-4000-8000-000000000007', 'cupo.asignado', 'subcuentas', '5'));

select is((select momento from public.auditoria where id = (select id from r where n = 1)),
          '2026-03-02 15:30:45.123456+00'::timestamptz,
          'el momento es el de private.ahora()');
select is((select actor_id::text || '|' || actor_rol::text from public.auditoria where id = (select id from r where n = 1)),
          '00000000-0000-4000-8000-000000000003|administrador',
          'guarda el actor y su rol');
select is((select accion || '|' || entidad || '|' || entidad_id from public.auditoria where id = (select id from r where n = 1)),
          'parametro.cambiado|parametros|ia.umbral',
          'guarda la acción, la entidad y el id');
select is((select antes from public.auditoria where id = (select id from r where n = 1)), '{"valor": 1}'::jsonb,
          'guarda el valor anterior');
select is((select despues from public.auditoria where id = (select id from r where n = 1)), '{"valor": 2}'::jsonb,
          'guarda el valor nuevo');
select is((select detalle from public.auditoria where id = (select id from r where n = 1)),
          '{"motivo": "ajuste", "b": 1}'::jsonb, 'guarda el detalle');
select is((select origen from public.auditoria where id = (select id from r where n = 1)), 'app',
          'con actor y sin origen explícito, el origen es app');
select ok(
  (select actor_id is null and actor_rol is null and antes is null and despues is null and detalle is null
     from public.auditoria where id = (select id from r where n = 2)),
  'una acción del sistema queda sin actor, sin rol y sin valores');
select is((select origen from public.auditoria where id = (select id from r where n = 2)), 'sistema',
          'sin actor y sin origen explícito, el origen es sistema');
select is((select actor_rol::text || '|' || origen from public.auditoria where id = (select id from r where n = 3)),
          'usuario|auth', 'el origen explícito auth se respeta y el rol es el del Usuario');
select is((select coalesce(entidad_id, '(nulo)') || '|' || origen from public.auditoria where id = (select id from r where n = 4)),
          '(nulo)|cron', 'el origen explícito cron se respeta y el id puede ser nulo');
select is((select coalesce(actor_rol::text, '(nulo)') || '|' || origen from public.auditoria where id = (select id from r where n = 5)),
          '(nulo)|app', 'un actor sin perfil queda sin rol');
select throws_ok(
  $$select private.auditar(null, 'x.y', 'tabla', null, null, null, null, 'otro')$$,
  '23514', null, 'un origen fuera de app, sistema, cron y auth se rechaza');
select throws_ok($$select private.auditar(null, '  ', 'tabla', null)$$, 'P0001', 'auditar: la acción es obligatoria',
                 'la acción no puede estar vacía');
select throws_ok($$select private.auditar(null, null, 'tabla', null)$$, 'P0001', 'auditar: la acción es obligatoria',
                 'la acción no puede ser nula');
select throws_ok($$select private.auditar(null, 'x.y', '', null)$$, 'P0001', 'auditar: la entidad es obligatoria',
                 'la entidad no puede estar vacía');
-- La llamada de docs/04 §6 (cinco argumentos, con el id como texto) sigue funcionando.
select lives_ok(
  $$insert into r values (6, private.auditar(null, 'ajuste.registrado', 'movimientos', '1', '{"a": 1}'::jsonb))$$,
  'la llamada de cinco argumentos de docs/04 §6 funciona');

-- CA-2: el encadenado --------------------------------------------------------------------------
select is((select count(*)::int from public.auditoria), 6, 'hay seis registros');
select is((select hash_anterior from public.auditoria where id = (select id from r where n = 1)), repeat('0', 64),
          'el primer registro lleva 64 ceros como hash anterior');
select is(
  (select count(*)::int
     from (select a.hash_anterior, lag(a.hash) over (order by a.id) as previo from public.auditoria a) x
    where x.previo is not null and x.hash_anterior <> x.previo),
  0, 'el hash anterior de cada registro es el hash del registro previo');
select is(
  (select hash from public.auditoria where id = (select id from r where n = 1)),
  encode(sha256(convert_to(
    repeat('0', 64) || chr(31) || '2026-03-02T15:30:45.123456Z' || chr(31) || '00000000-0000-4000-8000-000000000003'
    || chr(31) || 'parametro.cambiado' || chr(31) || 'parametros' || chr(31) || 'ia.umbral'
    || chr(31) || '{"b": 1, "motivo": "ajuste"}', 'UTF8')), 'hex'),
  'el hash es sha256(hash_anterior ‖ momento ‖ actor ‖ acción ‖ entidad ‖ id ‖ detalle), escrito a mano');
select is(
  (select hash from public.auditoria where id = (select id from r where n = 2)),
  encode(sha256(convert_to(
    (select hash from public.auditoria where id = (select id from r where n = 1))
    || chr(31) || '2026-03-02T15:30:45.123456Z' || chr(31) || '' || chr(31) || 'integracion.caida'
    || chr(31) || 'salud_integraciones' || chr(31) || 'alpaca_broker' || chr(31) || '', 'UTF8')), 'hex'),
  'con actor, id y detalle nulos, esos campos entran vacíos y el hash anterior es el del primer registro');
select is(
  (select count(*)::int from public.auditoria a
    where a.hash <> private.hash_auditoria(a.hash_anterior, a.momento, a.actor_id, a.accion, a.entidad, a.entidad_id, a.detalle)),
  0, 'la cadena completa se recalcula de punta a punta con private.hash_auditoria');
set local timezone to 'Asia/Tokyo';
select is(
  (select private.hash_auditoria(a.hash_anterior, a.momento, a.actor_id, a.accion, a.entidad, a.entidad_id, a.detalle)
     from public.auditoria a where a.id = (select id from r where n = 1)),
  (select hash from public.auditoria where id = (select id from r where n = 1)),
  'el hash no depende de la zona horaria de la sesión');
reset timezone;
select isnt(
  private.hash_auditoria(repeat('a', 64), '2026-03-02 15:30:45+00', null, 'x.y', 'tabla', '1', '{"k": 1}'),
  private.hash_auditoria(repeat('a', 64), '2026-03-02 15:30:45+00', null, 'x.y', 'tabla', '1', '{"k": 2}'),
  'cambiar el detalle cambia el hash');
select isnt(
  private.hash_auditoria(repeat('a', 64), '2026-03-02 15:30:45+00', null, 'ab', 'c', null, null),
  private.hash_auditoria(repeat('a', 64), '2026-03-02 15:30:45+00', null, 'a', 'bc', null, null),
  'mover un carácter de un campo al vecino cambia el hash');

-- CA-2: concurrencia -----------------------------------------------------------------------------
select ok(
  exists (
    select 1 from pg_locks
     where locktype = 'relation' and relation = 'public.auditoria'::regclass
       and mode = 'ShareRowExclusiveLock' and granted and pid = pg_backend_pid()),
  'auditar toma el bloqueo de la tabla de la bitácora');
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x.y', 'tabla', 'app',
            (select hash_anterior from public.auditoria order by id limit 1), repeat('f', 64))$$,
  '23505', null, 'un segundo registro con el mismo hash anterior se rechaza');

-- Una segunda conexión que llama a auditar mientras esta transacción tiene el bloqueo espera: no puede
-- leer el último hash hasta que esta termine, así que nunca usaría el mismo hash anterior. La consulta
-- se cancela antes de que confirme nada, y además corre dentro de un begin/rollback: aunque algo falle y la
-- consulta llegara a ejecutarse, no deja ningún registro confirmado en la bitácora.
-- La conexión va por TCP al servidor (como la de `supabase test db`): con un socket Unix no hay dirección.
select is(
  extensions.dblink_connect(
    'segunda',
    format('host=%s port=%s dbname=%s user=postgres password=postgres',
           host(inet_server_addr()), current_setting('port'), current_database())),
  'OK', 'se abre una segunda conexión a la misma base');
create temp table segunda (pid int not null);
insert into segunda select pid from extensions.dblink('segunda', 'select pg_backend_pid()') as t(pid int);
select is(
  extensions.dblink_send_query(
    'segunda',
    $q$begin; select private.auditar(null, 'prueba.concurrente', 'prueba06', null); rollback;$q$),
  1, 'la segunda conexión llama a auditar');
do $$
begin
  for i in 1..100 loop
    exit when exists (
      select 1 from pg_stat_activity
       where pid = (select pid from segunda) and wait_event_type = 'Lock');
    perform pg_sleep(0.1);
  end loop;
end;
$$;
select is((select pg_blocking_pids(pid) from segunda), array[pg_backend_pid()],
          'la segunda conexión espera a la que ya tiene el bloqueo');
select is(extensions.dblink_is_busy('segunda'), 1, 'y sigue sin poder escribir');
select is(extensions.dblink_cancel_query('segunda'), 'OK', 'se cancela la consulta de la segunda conexión');
-- Resultados que quedan en la conexión: el estado de BEGIN y luego el error de la cancelación (sin filas).
select lives_ok(
  $t$do $d$
    declare
      n int;
    begin
      loop
        select count(*) into n from extensions.dblink_get_result('segunda', false) as t(x text);
        exit when n = 0;
      end loop;
    end;
  $d$$t$,
  'se recogen los resultados de la consulta cancelada');
select is(extensions.dblink_disconnect('segunda'), 'OK', 'se cierra la segunda conexión');
select is((select count(*)::int from public.auditoria where entidad = 'prueba06'), 0,
          'la segunda conexión no agregó nada a la bitácora');

-- CA-4: sin llaves, tokens ni respuestas de Google ------------------------------------------------
-- La sesión trae un token, una cabecera con llaves y una respuesta de Google; auditar solo guarda lo que
-- recibe como argumentos.
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated", "access_token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ4In0.firma", "provider_token": "ya29.a0AfH6SMBxxxxxxxxxxxxxxxxxxxx", "refresh_token": "1//0gxxxxxxxxxxxx", "id_token": "eyJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJnIn0.otra", "user_metadata": {"full_name": "Persona de Google", "picture": "https://lh3.googleusercontent.com/a/x"}}';
set local request.headers to '{"authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiJ9.firma", "apikey": "sb_secret_xxxxxxxxxxxxxxxxxxxx"}';
insert into r values (7, private.auditar(
  '00000000-0000-4000-8000-000000000003', 'lista_blanca.cambiada', 'lista_blanca', 'AAPL',
  '{"activo": true}'::jsonb, '{"activo": false}'::jsonb, '{"activo": true}'::jsonb));
select is(
  (select (actor_id, actor_rol, accion, entidad, entidad_id, antes, despues, detalle, origen)::text
     from public.auditoria where id = (select id from r where n = 7)),
  '(00000000-0000-4000-8000-000000000003,administrador,lista_blanca.cambiada,lista_blanca,AAPL,"{""activo"": false}","{""activo"": true}","{""activo"": true}",app)',
  'con la sesión cargada de tokens, el registro solo trae lo que se le pasó');
select is(
  (select count(*)::int from public.auditoria a
    where a::text ~* 'eyJ|ya29\.|sb_secret_|sb_publishable_|access_token|refresh_token|id_token|provider_token|authorization|apikey|googleusercontent'),
  0, 'ningún registro contiene llaves, tokens ni respuestas de Google');
set local request.jwt.claims to '';
set local request.headers to '';

-- Se revierte junto con quien la llama (docs/11 §4.2, EC-012) ------------------------------------------
savepoint antes_de_revertir;
select private.auditar(null, 'ajuste.registrado', 'prueba06r', null);
rollback to savepoint antes_de_revertir;
select is((select count(*)::int from public.auditoria where entidad = 'prueba06r'), 0,
          'si la transacción de quien la llama se revierte, el registro también');
insert into r values (8, private.auditar(null, 'ajuste.registrado', 'prueba06r', null));
select is(
  (select hash_anterior from public.auditoria where id = (select id from r where n = 8)),
  (select hash from public.auditoria where id = (select id from r where n = 7)),
  'tras revertir, el siguiente registro cuelga del último que sí se guardó');

-- Permisos: ningún rol de la API la ejecuta ----------------------------------------------------
select is(
  (select count(*)::int from unnest(array['anon', 'authenticated', 'service_role']) rol
    where has_function_privilege(rol, 'private.auditar(uuid, text, text, text, jsonb, jsonb, jsonb, text)', 'execute')),
  0, 'ni anon, ni authenticated, ni service_role ejecutan private.auditar');
select is(
  (select count(*)::int from unnest(array['anon', 'authenticated', 'service_role']) rol
    where has_function_privilege(rol, 'private.hash_auditoria(text, timestamptz, uuid, text, text, text, jsonb)', 'execute')),
  0, 'ni anon, ni authenticated, ni service_role ejecutan private.hash_auditoria');

set local role anon;
select throws_ok($$select private.auditar(null, 'x.y', 'tabla', null)$$, '42501', null, 'anon no puede llamar a auditar');
reset role;
set local role authenticated;
select throws_ok($$select private.auditar(null, 'x.y', 'tabla', null)$$, '42501', null, 'authenticated no puede llamar a auditar');
reset role;
set local role service_role;
select throws_ok($$select private.auditar(null, 'x.y', 'tabla', null)$$, '42501', null, 'service_role no puede llamar a auditar');
reset role;

-- La cadena completa sigue íntegra tras todo lo anterior -----------------------------------------------
select is(
  (select count(*)::int
     from (select a.hash_anterior, a.hash,
                  lag(a.hash) over (order by a.id) as previo,
                  private.hash_auditoria(a.hash_anterior, a.momento, a.actor_id, a.accion, a.entidad, a.entidad_id, a.detalle) as recalculado
             from public.auditoria a) x
    where x.hash <> x.recalculado or (x.previo is not null and x.hash_anterior <> x.previo)),
  0, 'la cadena queda íntegra de punta a punta');

select * from finish();
rollback;

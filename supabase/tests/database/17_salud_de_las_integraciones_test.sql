-- HU-035 · Salud de las integraciones: transiciones, auditoría, evento y lectura por rol.
-- Criterios: CA-1 a CA-4 (backlog/E-05-motor-de-politicas-y-configuracion/HU-035-*.md). Reglas: docs/08 §6,
-- docs/06 §5.6, docs/03 §4.3, docs/12 CB-64. La alerta al caer es de HU-085 (aún sin tabla alertas).
begin;
create extension if not exists pgtap with schema extensions;
select plan(30);

set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario', 'usuario');
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista', 'analista', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador', 'administrador', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test', 'Suspendido', 'administrador', 'suspendido', now(), null);

create function pg_temp.estado(p text) returns text language sql as
  $$ select (estado, fallos_seguidos)::text from public.salud_integraciones where integracion = p $$;
create function pg_temp.eventos(p text) returns int language sql as
  $$ select count(*)::int from realtime.messages where topic = 'supervision' and event = 'salud' and private and payload->>'id' = p $$;
create function pg_temp.auditorias(p_accion text, p text) returns int language sql as
  $$ select count(*)::int from public.auditoria where accion = p_accion and entidad_id = p $$;

-- Estructura y datos iniciales
select enum_has_labels('public', 'estado_integracion', array['ok', 'degradado', 'caido'], 'estado_integracion tiene sus tres valores');
select is((select array_agg(integracion order by integracion) from public.salud_integraciones),
          array['alpaca_datos', 'alpaca_noticias', 'alpaca_trading', 'deepseek', 'fcm', 'jev'], 'están las seis integraciones');
select is((select count(*)::int from public.salud_integraciones where estado = 'ok' and fallos_seguidos = 0), 6, 'todas nacen en ok');
select throws_ok($$insert into public.salud_integraciones (integracion) values ('latido')$$, '23514', null, 'no admite otra integración');
select ok(not has_function_privilege('authenticated', 'private.registrar_salud(text, boolean, text)', 'execute'), 'la API no ejecuta registrar_salud');

-- CA-1 · Transiciones
select is(private.registrar_salud('alpaca_datos', false, 'timeout'), 'degradado', 'CA-1 · un fallo: degradado');
select is(pg_temp.estado('alpaca_datos'), '(degradado,1)', 'con 1 fallo seguido');
select is(private.registrar_salud('alpaca_datos', false, 'timeout'), 'degradado', 'dos fallos: sigue degradado');
select is(pg_temp.eventos('alpaca_datos'), 1, 'CA-3 · un solo evento salud por cambio de estado (ok → degradado)');
select is(private.registrar_salud('alpaca_datos', false, 'timeout'), 'caido', 'el tercer fallo seguido: caido');
select is(pg_temp.estado('alpaca_datos'), '(caido,3)', 'con 3 fallos seguidos');
select is(pg_temp.eventos('alpaca_datos'), 2, 'CA-3 · evento salud al pasar a caido');
select is(private.registrar_salud('alpaca_datos', false, 'timeout'), 'caido', 'más fallos: sigue caido');
select is(pg_temp.eventos('alpaca_datos'), 2, 'sin cambio de estado no hay evento');
select is(pg_temp.auditorias('integracion.caida', 'alpaca_datos'), 1, 'CA-2 · se registra integracion.caida una sola vez');
select is(private.registrar_salud('alpaca_datos', true), 'ok', 'CA-1 · un éxito devuelve a ok');
select is(pg_temp.estado('alpaca_datos'), '(ok,0)', 'con 0 fallos seguidos');
select is(pg_temp.auditorias('integracion.recuperada', 'alpaca_datos'), 1, 'CA-2 · se registra integracion.recuperada');
select is(pg_temp.eventos('alpaca_datos'), 3, 'y se publica salud');
select isnt((select ultimo_exito_en from public.salud_integraciones where integracion = 'alpaca_datos'), null, 'guarda el último éxito');
select is((select ultimo_error from public.salud_integraciones where integracion = 'alpaca_datos'), 'timeout', 'y conserva el último error');

-- Degradado que se recupera no audita; el error se recorta
do $$ begin perform private.registrar_salud('jev', false, repeat('x', 1000)); end $$;
select is((select length(ultimo_error) from public.salud_integraciones where integracion = 'jev'), 300, 'el error se recorta a 300 caracteres');
do $$ begin perform private.registrar_salud('jev', true); end $$; -- (un select desnudo imprimiría «ok» y lo leería TAP como una prueba)
select is(pg_temp.auditorias('integracion.recuperada', 'jev'), 0, 'degradado → ok no audita recuperada (solo desde caido)');
select throws_ok($$select private.registrar_salud('latido', true)$$, 'P0001', 'NO_EXISTE', 'una integración desconocida: NO_EXISTE');
select throws_ok($$select private.registrar_salud('jev', null)$$, '22023', null, 'un resultado nulo se rechaza');

-- CA-4 · Lectura por rol
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select count(*)::int from public.salud_integraciones), 0, 'CA-4 · un Usuario no recibe filas');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is((select count(*)::int from public.salud_integraciones), 6, 'un Analista ve las seis');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is((select count(*)::int from public.salud_integraciones), 6, 'un Administrador ve las seis');
select throws_ok($$update public.salud_integraciones set estado = 'ok'$$, '42501', null, 'la API no escribe');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated"}';
select is((select count(*)::int from public.salud_integraciones), 0, 'una cuenta suspendida no ve nada');
reset role;

select * from finish();
rollback;

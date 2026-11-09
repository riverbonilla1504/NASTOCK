-- HU-034 · Interruptores del fondo: nacen apagados, fondo sin capital, encender, apagar, permisos, auditoría y evento.
-- Criterios: CA-1 a CA-5 (backlog/E-05-motor-de-politicas-y-configuracion/HU-034-*.md). Reglas: docs/03 PM-56 y PM-57,
-- docs/02 RN-11 y RR-14, docs/12 CB-80, docs/11 §4.1.
begin;
create extension if not exists pgtap with schema extensions;
select plan(30);

-- 0001 usuario · 0002 analista · 0003 administrador · 0004 administrador suspendido.
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

create function pg_temp.fondo() returns text language sql as
  $$ select (ia_activa, trading_activo)::text from public.fondos $$;
create function pg_temp.auditorias(p_accion text) returns int language sql as
  $$ select count(*)::int from public.auditoria where accion = p_accion $$;
create function pg_temp.eventos() returns int language sql as
  $$ select count(*)::int from realtime.messages where topic = 'admin' and event = 'interruptor' and private $$;
grant execute on function pg_temp.fondo(), pg_temp.auditorias(text), pg_temp.eventos() to authenticated;

select has_function('public', 'reanudar', array['text'], 'existe public.reanudar');
select has_function('public', 'activar_freno', array['text', 'text'], 'existe public.activar_freno');
select ok(not has_function_privilege('anon', 'public.reanudar(text)', 'execute'), 'anon no ejecuta reanudar');
select ok(not has_function_privilege('anon', 'public.activar_freno(text, text)', 'execute'), 'anon no ejecuta activar_freno');

-- CA-1 · Nacen apagados
select is(pg_temp.fondo(), '(f,f)', 'CA-1 · ia_activa y trading_activo nacen apagados');

set local role authenticated;

-- CA-5 · Permisos
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select throws_ok($$select public.reanudar('ia_activa')$$, 'P0001', 'NO_AUTORIZADO', 'CA-5 · un Usuario no reanuda');
select throws_ok($$select public.activar_freno('ia_activa', 'x')$$, 'P0001', 'NO_AUTORIZADO', 'ni frena');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select throws_ok($$select public.reanudar('ia_activa')$$, 'P0001', 'NO_AUTORIZADO', 'CA-5 · un Analista no reanuda');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated"}';
select throws_ok($$select public.reanudar('ia_activa')$$, 'P0001', 'SESION_INVALIDA', 'un administrador suspendido: SESION_INVALIDA');
set local request.jwt.claims to '';
select throws_ok($$select public.reanudar('ia_activa')$$, 'P0001', 'SESION_INVALIDA', 'sin sesión: SESION_INVALIDA');

-- CA-2 / CB-80 · Fondo sin capital
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.reanudar('ia_activa')$$, 'P0001', 'FONDO_SIN_CAPITAL', 'CA-2 · sin aporte confirmado no se enciende ia_activa');
select throws_ok($$select public.reanudar('trading_activo')$$, 'P0001', 'FONDO_SIN_CAPITAL', 'ni trading_activo');
reset role;
insert into public.movimientos_capital (tipo, monto, estado, registrado_por)
  values ('aporte', 1000, 'registrado', '00000000-0000-4000-8000-000000000003');
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.reanudar('ia_activa')$$, 'P0001', 'FONDO_SIN_CAPITAL', 'un aporte solo registrado no cuenta');
reset role;
update public.movimientos_capital set estado = 'confirmado', confirmado_en = now();
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';

-- CA-3 · Encender
select throws_ok($$select public.reanudar('otro')$$, '22023', null, 'un interruptor desconocido se rechaza');
select lives_ok($$select public.reanudar('ia_activa')$$, 'CA-3 · el Administrador enciende ia_activa con un aporte confirmado');
select is(pg_temp.fondo(), '(t,f)', 'queda encendida y trading sigue apagado');
select is(pg_temp.auditorias('interruptor.encendido'), 1, 'se registra interruptor.encendido');
select is(pg_temp.eventos(), 1, 'se publica interruptor en el canal admin');
select throws_ok($$select public.reanudar('ia_activa')$$, 'P0001', 'ESTADO_INVALIDO', 'encender lo ya encendido: ESTADO_INVALIDO');
select lives_ok($$select public.reanudar('trading_activo')$$, 'enciende trading_activo');
select is(pg_temp.fondo(), '(t,t)', 'ambos encendidos');

-- CA-4 · Apagar con motivo
select throws_ok($$select public.activar_freno('trading_activo', '  ')$$, '22023', null, 'apagar exige un motivo');
select lives_ok($$select public.activar_freno('trading_activo', 'Revisión del broker')$$, 'CA-4 · el Administrador apaga con un motivo');
select is(pg_temp.fondo(), '(t,f)', 'queda apagado');
select is((select (motivo_pausa, pausado_por is not null, pausado_en is not null)::text from public.fondos),
          '("Revisión del broker",t,t)', 'con motivo, autor y hora');
select is(pg_temp.auditorias('interruptor.apagado'), 1, 'se registra interruptor.apagado');
select throws_ok($$select public.activar_freno('trading_activo', 'otra vez')$$, 'P0001', 'ESTADO_INVALIDO', 'apagar lo ya apagado: ESTADO_INVALIDO');

-- El Analista puede frenar (PM-56) pero no reanudar
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select lives_ok($$select public.activar_freno('ia_activa', 'Algo raro en las sugerencias')$$, 'PM-56 · un Analista puede frenar');

-- Reanudar todo borra el motivo de la pausa
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select public.reanudar('ia_activa');
select public.reanudar('trading_activo');
select is((select (motivo_pausa is null, pausado_por is null)::text from public.fondos), '(t,t)', 'con todo encendido, el motivo de la pausa se limpia');

-- Escritura directa bloqueada
select throws_ok($$update public.fondos set ia_activa = false$$, '42501', null, 'la API no escribe fondos directamente');

reset role;
select * from finish();
rollback;

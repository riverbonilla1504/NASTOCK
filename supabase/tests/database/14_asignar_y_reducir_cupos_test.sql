-- HU-018 · Asignar y reducir cupos: RPC asignar_cupo y reducir_cupo, límites, permisos, auditoría y eventos.
-- Criterios: CA-1 a CA-6 (backlog/E-03-fondo-y-libro-contable/HU-018-*.md). Reglas: docs/02 RN-16, RN-17,
-- RN-19; docs/03 PM-42; docs/12 CB-14 y CB-16. El E2E-04 lo ejercita de punta a punta.
begin;
create extension if not exists pgtap with schema extensions;
select plan(31);

-- 0001 usuario (cupo) · 0002 analista · 0003 administrador · 0004 administrador suspendido · 0006 usuario sin cupo abierto.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test'),
  ('00000000-0000-4000-8000-000000000006', 'sincupo@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario'),
  ('00000000-0000-4000-8000-000000000006', 'sincupo@prueba.test', 'Sin cupo', 'usuario');
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista', 'analista', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador', 'administrador', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test', 'Suspendido', 'administrador', 'suspendido', now(), null);
select private.crear_cupo('00000000-0000-4000-8000-000000000001', 0);

-- Bolsa común con 2.500 (el 25 % de un aporte de 10.000).
select private.registrar_movimiento('aporte', jsonb_build_array(
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'externa'), 'concepto', 'efectivo', 'monto', -2500),
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'usuarios_comun'), 'concepto', 'efectivo', 'monto', 2500)),
  null, 'Fondos de prueba');

create function pg_temp.comun() returns numeric language sql as $$ select efectivo from public.subcuentas where tipo = 'usuarios_comun' $$;
create function pg_temp.cupo() returns numeric language sql as
  $$ select efectivo from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001' $$;
create function pg_temp.eventos(p_topico text, p_evento text) returns int language sql as
  $$ select count(*)::int from realtime.messages where topic = p_topico and event = p_evento and private $$;
grant execute on function pg_temp.comun(), pg_temp.cupo(), pg_temp.eventos(text, text) to authenticated;

select has_function('public', 'asignar_cupo', array['uuid', 'numeric'], 'existe public.asignar_cupo');
select has_function('public', 'reducir_cupo', array['uuid', 'numeric'], 'existe public.reducir_cupo');
select ok(not has_function_privilege('anon', 'public.asignar_cupo(uuid, numeric)', 'execute'), 'anon no ejecuta asignar_cupo');
select ok(has_function_privilege('authenticated', 'public.reducir_cupo(uuid, numeric)', 'execute'), 'authenticated ejecuta reducir_cupo (la función decide por el rol)');

set local role authenticated;

-- CA-5 · Permisos ----------------------------------------------------------------------------------------------
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select throws_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000001', 10)$$, 'P0001', 'NO_AUTORIZADO', 'CA-5 · un Usuario no asigna cupos');
select throws_ok($$select public.reducir_cupo('00000000-0000-4000-8000-000000000001', 10)$$, 'P0001', 'NO_AUTORIZADO', 'ni los reduce');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select throws_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000001', 10)$$, 'P0001', 'NO_AUTORIZADO', 'CA-5 · un Analista no asigna');
select throws_ok($$select public.reducir_cupo('00000000-0000-4000-8000-000000000001', 10)$$, 'P0001', 'NO_AUTORIZADO', 'ni reduce');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated"}';
select throws_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000001', 10)$$, 'P0001', 'SESION_INVALIDA', 'un administrador suspendido con token vigente: SESION_INVALIDA');
set local request.jwt.claims to '';
select throws_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000001', 10)$$, 'P0001', 'SESION_INVALIDA', 'sin sesión: SESION_INVALIDA');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';

-- CA-1 · Asignar -----------------------------------------------------------------------------------------------------
select lives_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000001', 400)$$, 'CA-1 · el Administrador asigna 400');
select is(pg_temp.comun(), 2100.00::numeric, 'usuarios_comun −400');
select is(pg_temp.cupo(), 400.00::numeric, 'cupo +400');
select is((select count(*)::int from public.auditoria where accion = 'cupo.asignado' and actor_id = '00000000-0000-4000-8000-000000000003'),
          1, 'se audita cupo.asignado con el Administrador como actor');
select is((select count(*)::int from public.movimientos where tipo = 'asignacion_cupo' and creado_por = '00000000-0000-4000-8000-000000000003'),
          1, 'el movimiento guarda quién lo hizo');

-- Eventos: avisan sin montos (docs/09 §4)
select is(pg_temp.eventos('usuario:00000000-0000-4000-8000-000000000001', 'cupo'), 1, 'se publica el evento cupo en el canal del Usuario');
select ok(pg_temp.eventos('fondo', 'resumen_cambio') >= 1, 'y resumen_cambio en el canal fondo');
-- Solo las cuatro claves de docs/09 §4 (no se busca un número en el texto: los uuid pueden contener «400»).
select is((select count(*)::int from realtime.messages m
            where m.event in ('cupo', 'resumen_cambio')
              and exists (select 1 from jsonb_object_keys(m.payload) k where k not in ('tabla', 'id', 'version', 'estado'))),
          0, 'los eventos no llevan montos');

-- CA-2 / CB-14 · Más que la bolsa común -----------------------------------------------------------------------------------
select throws_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000001', 2100.01)$$, 'P0001', 'FONDOS_INSUFICIENTES',
                 'CA-2 · asignar más que el disponible de usuarios_comun: FONDOS_INSUFICIENTES');
reset role;
update public.subcuentas set retenido = 100 where tipo = 'usuarios_comun';
set local role authenticated;
select throws_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000001', 2000.01)$$, 'P0001', 'FONDOS_INSUFICIENTES',
                 'el disponible descuenta lo retenido');
reset role;
update public.subcuentas set retenido = 0 where tipo = 'usuarios_comun';
set local role authenticated;

-- CA-4 · Máximo por cupo ------------------------------------------------------------------------------------------------------
reset role;
update public.parametros set valor = '500'::jsonb where clave = 'cupos.maximo_usd';
set local role authenticated;
select throws_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000001', 100.01)$$, 'P0001', 'CUPO_SUPERA_MAXIMO',
                 'CA-4 · una asignación que deja el cupo sobre cupos.maximo_usd: CUPO_SUPERA_MAXIMO');
select lives_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000001', 100)$$, 'llegar exactamente al máximo sí se puede');
reset role;
update public.parametros set valor = 'null'::jsonb where clave = 'cupos.maximo_usd';
set local role authenticated;
select lives_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000001', 100)$$, 'sin límite (null) no hay tope');

-- CA-6 / CA-3 / CB-16 · Reducir ------------------------------------------------------------------------------------------------
select lives_ok($$select public.reducir_cupo('00000000-0000-4000-8000-000000000001', 200)$$, 'CA-6 · reducir por un monto que no supera el disponible');
select is(pg_temp.cupo(), 400.00::numeric, 'el cupo baja de 600 a 400');
select is(pg_temp.comun(), 2100.00::numeric, 'y el dinero vuelve a usuarios_comun');
select is((select count(*)::int from public.auditoria where accion = 'cupo.reducido'), 1, 'se audita cupo.reducido');
-- El cupo tiene 400 de efectivo; se invierten 380 → disponible 20.
reset role;
select private.registrar_movimiento('compra', jsonb_build_array(
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001'), 'concepto', 'efectivo', 'monto', -380),
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001'), 'concepto', 'invertido', 'monto', 380)),
  null, 'Compra de prueba');
set local role authenticated;
select throws_ok($$select public.reducir_cupo('00000000-0000-4000-8000-000000000001', 20.01)$$, 'P0001', 'FONDOS_INSUFICIENTES',
                 'CA-3 / CB-16 · reducir por encima del disponible: FONDOS_INSUFICIENTES');
select lives_ok($$select public.reducir_cupo('00000000-0000-4000-8000-000000000001', 20)$$, 'hasta el disponible sí');

-- Validaciones ---------------------------------------------------------------------------------------------------------------------
select throws_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000001', 0)$$, '22023', null, 'un monto de 0 se rechaza');
select throws_ok($$select public.asignar_cupo('00000000-0000-4000-8000-000000000006', 10)$$, 'P0001', 'NO_EXISTE', 'quien no tiene cupo: NO_EXISTE');

reset role;
select * from finish();
rollback;

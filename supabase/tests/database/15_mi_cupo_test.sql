-- HU-019 · mi_cupo(): cifras del cupo, aislamiento entre Usuarios, permisos y fondo sin capital.
-- Criterios: CA-1, CA-3, CA-4 y CA-5 (backlog/E-03-fondo-y-libro-contable/HU-019-*.md). CA-2 (el evento `cupo`)
-- lo prueba HU-018 en el servidor y el widget en la app. Reglas: docs/02 §2 y §13, RN-20, docs/12 CB-80.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

-- 0001 y 0006 usuarios con cupo · 0002 analista · 0003 administrador · 0007 usuario sin cupo abierto.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'uno@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test'),
  ('00000000-0000-4000-8000-000000000006', 'dos@prueba.test'),
  ('00000000-0000-4000-8000-000000000007', 'sincupo@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'uno@prueba.test', 'Uno', 'usuario'),
  ('00000000-0000-4000-8000-000000000006', 'dos@prueba.test', 'Dos', 'usuario'),
  ('00000000-0000-4000-8000-000000000007', 'sincupo@prueba.test', 'Sin cupo', 'usuario');
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista', 'analista', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador', 'administrador', 'activo', null, null);
select private.crear_cupo('00000000-0000-4000-8000-000000000001', 0);
select private.crear_cupo('00000000-0000-4000-8000-000000000006', 0);

create function pg_temp.sc(p_tipo text) returns uuid language sql as
  $$ select id from public.subcuentas where tipo = p_tipo::public.tipo_subcuenta $$;
create function pg_temp.cupo_de(p_usuario uuid) returns uuid language sql as
  $$ select id from public.subcuentas where usuario_id = p_usuario $$;
create function pg_temp.mover(p_de uuid, p_a uuid, p_monto numeric, p_tipo text) returns void language sql as
  $$ select private.registrar_movimiento(p_tipo::public.tipo_movimiento, jsonb_build_array(
       jsonb_build_object('subcuenta_id', p_de, 'concepto', 'efectivo', 'monto', -p_monto),
       jsonb_build_object('subcuenta_id', p_a, 'concepto', 'efectivo', 'monto', p_monto)), null, 'Prueba') $$;

set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';

-- CB-80 · Fondo sin capital
select is((select fondo_con_capital from public.mi_cupo()), false, 'CB-80 · sin aportes, fondo_con_capital es falso');
select is((select efectivo from public.mi_cupo()), 0.00::numeric, 'y el cupo está en 0');

reset role;
-- Aporte de 10.000 y 400 asignados al cupo uno (CA-1), 150 al cupo dos.
select pg_temp.mover(pg_temp.sc('externa'), pg_temp.sc('usuarios_comun'), 2500, 'aporte');
select pg_temp.mover(pg_temp.sc('usuarios_comun'), pg_temp.cupo_de('00000000-0000-4000-8000-000000000001'), 400, 'asignacion_cupo');
select pg_temp.mover(pg_temp.sc('usuarios_comun'), pg_temp.cupo_de('00000000-0000-4000-8000-000000000006'), 150, 'asignacion_cupo');
set local role authenticated;

-- CA-1 · Las cifras
select is((select (efectivo, retenido, disponible, invertido, patrimonio)::text from public.mi_cupo()),
          '(400.00,0.00,400.00,0.00,400.00)', 'CA-1 · efectivo 400, retenido 0, disponible 400 y patrimonio 400');
select is((select fondo_con_capital from public.mi_cupo()), true, 'con un aporte, el fondo ya tiene capital');
select is((select resultado_realizado from public.mi_cupo()), 0.00::numeric, 'CA-5 · resultado realizado 0 sin ventas');
select is((select resultado_no_realizado from public.mi_cupo()), 0.00::numeric, 'resultado no realizado 0 sin posiciones');
select is((select rendimiento from public.mi_cupo()), null, 'rendimiento nulo hasta que existan las fotos diarias (HU-021)');
select is((select count(*)::int from public.mi_cupo()), 1, 'devuelve una sola fila');

-- Retenido, invertido y una venta con ganancia (docs/06 §4.2): costo 110,20, recibe 123,20.
reset role;
update public.subcuentas set retenido = 50 where id = pg_temp.cupo_de('00000000-0000-4000-8000-000000000001');
select private.registrar_movimiento('compra', jsonb_build_array(
  jsonb_build_object('subcuenta_id', pg_temp.cupo_de('00000000-0000-4000-8000-000000000001'), 'concepto', 'efectivo', 'monto', -110.20),
  jsonb_build_object('subcuenta_id', pg_temp.cupo_de('00000000-0000-4000-8000-000000000001'), 'concepto', 'invertido', 'monto', 110.20)),
  null, 'Compra');
select private.registrar_movimiento('venta', jsonb_build_array(
  jsonb_build_object('subcuenta_id', pg_temp.cupo_de('00000000-0000-4000-8000-000000000001'), 'concepto', 'efectivo', 'monto', 123.20),
  jsonb_build_object('subcuenta_id', pg_temp.cupo_de('00000000-0000-4000-8000-000000000001'), 'concepto', 'invertido', 'monto', -110.20),
  jsonb_build_object('subcuenta_id', pg_temp.sc('resultados'), 'concepto', 'efectivo', 'monto', -13.00)),
  null, 'Venta con ganancia');
set local role authenticated;
select is((select (efectivo, retenido, disponible, patrimonio, resultado_realizado)::text from public.mi_cupo()),
          '(413.00,50.00,363.00,413.00,13.00)', 'el realizado sale del libro (+13,00) y el disponible descuenta lo retenido');

-- CA-3 · Aislamiento
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000006", "role": "authenticated"}';
select is((select efectivo from public.mi_cupo()), 150.00::numeric, 'CA-3 · el otro Usuario recibe solo su cupo (150)');
select is((select resultado_realizado from public.mi_cupo()), 0.00::numeric, 'y la venta de otro no le suma');
select is((select count(*)::int from public.subcuentas), 1, 'y por la API tampoco lee la subcuenta de nadie más');

-- Permisos y sin cupo
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select throws_ok($$select * from public.mi_cupo()$$, 'P0001', 'NO_AUTORIZADO', 'un Analista no tiene cupo: NO_AUTORIZADO');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000007", "role": "authenticated"}';
select is((select count(*)::int from public.mi_cupo()), 0, 'un Usuario sin cupo abierto no recibe filas');
set local request.jwt.claims to '';
select throws_ok($$select * from public.mi_cupo()$$, 'P0001', 'SESION_INVALIDA', 'sin sesión: SESION_INVALIDA');
reset role;
set local role anon;
select throws_ok($$select * from public.mi_cupo()$$, '42501', null, 'anon no ejecuta mi_cupo');
reset role;

select * from finish();
rollback;

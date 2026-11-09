-- HU-023 · Reparto de la ganancia realizada: cupo, pérdida, centavos, porcentajes vigentes, Arriesgadas y llenados
-- en partes. Criterios: HU-023 CA-1 a CA-5 (backlog/E-03) y CB-19. Sin sugerencias (D-65).
begin;
create extension if not exists pgtap with schema extensions;
select plan(34);

-- 0001 y 0002: usuarios con cupo.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'uno@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'dos@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'uno@prueba.test', 'Uno', 'usuario'),
  ('00000000-0000-4000-8000-000000000002', 'dos@prueba.test', 'Dos', 'usuario');
select private.crear_cupo('00000000-0000-4000-8000-000000000001', 0);
select private.crear_cupo('00000000-0000-4000-8000-000000000002', 0);

create function pg_temp.sub(p_tipo text) returns uuid language sql as $$ select id from public.subcuentas where tipo = p_tipo::public.tipo_subcuenta $$;
create function pg_temp.cupo(p text default '1') returns uuid language sql as
  $$ select id from public.subcuentas where usuario_id = ('00000000-0000-4000-8000-00000000000' || p)::uuid $$;
grant execute on function pg_temp.cupo(text) to authenticated;

-- Aporte de 10.000 (5.000 / 2.500 / 2.500) y un cupo de 3.000 para cada persona.
select private.registrar_movimiento('aporte', jsonb_build_array(
  jsonb_build_object('subcuenta_id', pg_temp.sub('externa'), 'concepto', 'efectivo', 'monto', -10000),
  jsonb_build_object('subcuenta_id', pg_temp.sub('reserva'), 'concepto', 'efectivo', 'monto', 5000),
  jsonb_build_object('subcuenta_id', pg_temp.sub('arriesgadas'), 'concepto', 'efectivo', 'monto', 2500),
  jsonb_build_object('subcuenta_id', pg_temp.sub('usuarios_comun'), 'concepto', 'efectivo', 'monto', 2500)),
  null, 'Aporte de prueba');
select private.registrar_movimiento('asignacion_cupo', jsonb_build_array(
  jsonb_build_object('subcuenta_id', pg_temp.sub('usuarios_comun'), 'concepto', 'efectivo', 'monto', -2000),
  jsonb_build_object('subcuenta_id', pg_temp.cupo('1'), 'concepto', 'efectivo', 'monto', 1000),
  jsonb_build_object('subcuenta_id', pg_temp.cupo('2'), 'concepto', 'efectivo', 'monto', 1000)),
  null, 'Cupos de prueba');
select pruebas.fijar_reloj('2031-03-10 16:00:30+00');

create function pg_temp.simbolo() returns text language sql as
  $$ select simbolo from public.lista_blanca where bolsillo = 'usuarios' and activo order by simbolo limit 1 $$;
-- Una orden ya aceptada por el broker. `p_ret` simula la retención que dejó la aprobación.
create function pg_temp.orden(p_sub uuid, p_lado text, p_cant numeric, p_limite numeric, p_ret numeric default 0,
                              p_enviada timestamptz default null) returns uuid language plpgsql as $$
declare v_id uuid;
begin
  insert into public.ordenes (origen, subcuenta_id, simbolo, lado, clase, tipo, tif, cantidad, precio_limite, retencion, parametros)
  values ('manual', p_sub, pg_temp.simbolo(), p_lado::public.lado, 'simple', 'limite', 'day', p_cant, p_limite, p_ret, '{}')
  returning id into v_id;
  update public.ordenes set estado = 'aceptada', broker_order_id = 'b-' || v_id, enviada_en = coalesce(p_enviada, private.ahora())
   where id = v_id;
  if p_ret > 0 then update public.subcuentas set retenido = retenido + p_ret where id = p_sub; end if;
  return v_id;
end $$;
create function pg_temp.ef(p uuid) returns numeric language sql as $$ select efectivo from public.subcuentas where id = p $$;
create function pg_temp.inv(p uuid) returns numeric language sql as $$ select invertido from public.subcuentas where id = p $$;
create function pg_temp.ret(p uuid) returns numeric language sql as $$ select retenido from public.subcuentas where id = p $$;
create function pg_temp.est(p uuid) returns text language sql as $$ select estado::text from public.ordenes where id = p $$;
create function pg_temp.pos(p uuid) returns text language sql as
  $$ select (cantidad, costo_promedio, costo_total, estado, resultado_realizado)::text from public.posiciones where subcuenta_id = p and simbolo = pg_temp.simbolo() order by (estado = 'cerrada'), abierta_en desc, id limit 1 $$;
create function pg_temp.movs(p_tipo text) returns int language sql as $$ select count(*)::int from public.movimientos where tipo = p_tipo::public.tipo_movimiento $$;

-- A · ejemplo de docs/02 §7.3: Ana compra 1 a 110,20 y vende a 123,20 (CA-1)
create temp table a0 as select pg_temp.orden(pg_temp.cupo('1'), 'compra', 1, 111.10) as id;
select private.aplicar_llenado((select id from a0), 1, 110.20, 'filled');
create temp table a_antes as select pg_temp.ef(pg_temp.cupo('1')) as cupo, pg_temp.ef(pg_temp.sub('reserva')) as reserva,
       pg_temp.ef(pg_temp.sub('arriesgadas')) as arr, pg_temp.ef(pg_temp.sub('resultados')) as resultados;
create temp table a1 as select pg_temp.orden(pg_temp.cupo('1'), 'venta', 1, 123.20) as id;
select private.aplicar_llenado((select id from a1), 1, 123.20, 'filled');
select is(pg_temp.ef(pg_temp.cupo('1')) - (select cupo from a_antes), 113.45, 'CA-1 · el cupo recibe 123,20 y paga 9,75 (se queda con 3,25 de la ganancia)');
select is(pg_temp.ef(pg_temp.sub('reserva')) - (select reserva from a_antes), 6.50, 'la Reserva recibe 6,50');
select is(pg_temp.ef(pg_temp.sub('arriesgadas')) - (select arr from a_antes), 3.25, 'Arriesgadas recibe 3,25');
select is(pg_temp.ef(pg_temp.sub('resultados')) - (select resultados from a_antes), -13.00, 'resultados registra −13,00');
select is(pg_temp.inv(pg_temp.cupo('1')), 0.00, 'RN-27 · el costo de lo vendido vuelve completo');
select is((select count(*)::int from public.movimientos where tipo = 'reparto_ganancia' and referencia_id = (select id from a1)), 1, 'un movimiento reparto_ganancia');
select is((select parametros->'reparto'->>'pct_reserva' from public.movimientos where tipo = 'reparto_ganancia' and referencia_id = (select id from a1)), '50', 'que guarda los porcentajes usados');
select is((select count(*)::int from private.verificar_libro()), 0, 'el libro cuadra (suma cero)');
select private.aplicar_llenado((select id from a1), 1, 123.20, 'filled');
select is((select count(*)::int from public.movimientos where tipo = 'reparto_ganancia' and referencia_id = (select id from a1)), 1, 'repetir el llenado no repite el reparto');
select is(pg_temp.ef(pg_temp.sub('reserva')) - (select reserva from a_antes), 6.50, 'ni mueve la Reserva otra vez');

-- B · pérdida: la absorbe el cupo y no hay reparto (CA-3, RN-28)
create temp table b0 as select pg_temp.orden(pg_temp.cupo('2'), 'compra', 1, 111.10) as id;
select private.aplicar_llenado((select id from b0), 1, 110.20, 'filled');
create temp table b_antes as select pg_temp.ef(pg_temp.cupo('2')) as cupo, pg_temp.ef(pg_temp.sub('reserva')) as reserva,
       pg_temp.ef(pg_temp.sub('arriesgadas')) as arr, pg_temp.ef(pg_temp.sub('resultados')) as resultados;
create temp table b1 as select pg_temp.orden(pg_temp.cupo('2'), 'venta', 1, 103.40) as id;
select private.aplicar_llenado((select id from b1), 1, 103.40, 'filled');
select is(pg_temp.ef(pg_temp.cupo('2')) - (select cupo from b_antes), 103.40, 'CA-3 · el cupo recibe lo vendido, sin descuento');
select is(pg_temp.ef(pg_temp.sub('resultados')) - (select resultados from b_antes), 6.80, 'resultados absorbe la pérdida completa: 6,80');
select is(pg_temp.ef(pg_temp.sub('reserva')) - (select reserva from b_antes), 0.00, 'la Reserva no recibe nada');
select is(pg_temp.ef(pg_temp.sub('arriesgadas')) - (select arr from b_antes), 0.00, 'ni Arriesgadas');
select is((select count(*)::int from public.movimientos where tipo = 'reparto_ganancia' and referencia_id = (select id from b1)), 0, 'no hay movimiento de reparto');

-- C · CB-18: ganancia de 0,03 → Arriesgadas 0,00 · cupo 0,00 · Reserva 0,03
create temp table c0 as select pg_temp.orden(pg_temp.cupo('2'), 'compra', 1, 101) as id;
select private.aplicar_llenado((select id from c0), 1, 100.00, 'filled');
create temp table c_antes as select pg_temp.ef(pg_temp.cupo('2')) as cupo, pg_temp.ef(pg_temp.sub('reserva')) as reserva, pg_temp.ef(pg_temp.sub('arriesgadas')) as arr;
create temp table c1 as select pg_temp.orden(pg_temp.cupo('2'), 'venta', 1, 100.03) as id;
select private.aplicar_llenado((select id from c1), 1, 100.03, 'filled');
select is(pg_temp.ef(pg_temp.sub('arriesgadas')) - (select arr from c_antes), 0.00, 'CB-18 · Arriesgadas recibe 0,00');
select is(pg_temp.ef(pg_temp.sub('reserva')) - (select reserva from c_antes), 0.03, 'la Reserva recibe los 0,03');
select is(pg_temp.ef(pg_temp.cupo('2')) - (select cupo from c_antes), 100.00, 'y el cupo solo recibe el costo (0,00 de ganancia)');
select is((select count(*)::int from private.verificar_libro()), 0, 'el libro cuadra');

-- D · CB-17: con 60/20/20 al llenarse, el reparto usa esos porcentajes y los guarda
update public.parametros set valor = '60'::jsonb where clave = 'reparto.pct_reserva';
update public.parametros set valor = '20'::jsonb where clave in ('reparto.pct_arriesgadas', 'reparto.pct_usuarios');
create temp table d0 as select pg_temp.orden(pg_temp.cupo('2'), 'compra', 1, 101) as id;
select private.aplicar_llenado((select id from d0), 1, 100.00, 'filled');
create temp table d_antes as select pg_temp.ef(pg_temp.cupo('2')) as cupo, pg_temp.ef(pg_temp.sub('reserva')) as reserva, pg_temp.ef(pg_temp.sub('arriesgadas')) as arr;
create temp table d1 as select pg_temp.orden(pg_temp.cupo('2'), 'venta', 1, 110) as id;
select private.aplicar_llenado((select id from d1), 1, 110, 'filled');
select is(pg_temp.ef(pg_temp.sub('reserva')) - (select reserva from d_antes), 6.00, 'CB-17 · con 60/20/20 la Reserva recibe 6,00 de 10,00');
select is(pg_temp.ef(pg_temp.sub('arriesgadas')) - (select arr from d_antes), 2.00, 'Arriesgadas 2,00');
select is(pg_temp.ef(pg_temp.cupo('2')) - (select cupo from d_antes), 102.00, 'y el cupo recibe 110,00 y paga 8,00 (se queda con 2,00 de la ganancia)');
select is((select parametros->'reparto'->>'pct_reserva' from public.movimientos where tipo = 'reparto_ganancia' and referencia_id = (select id from d1)), '60', 'el movimiento guarda 60');
update public.parametros set valor = '50'::jsonb where clave = 'reparto.pct_reserva';
update public.parametros set valor = '25'::jsonb where clave in ('reparto.pct_arriesgadas', 'reparto.pct_usuarios');

-- E · CA-2: ganancia en Arriesgadas → el 25 % de Usuarios va a usuarios_comun
create temp table e0 as select pg_temp.orden(pg_temp.sub('arriesgadas'), 'compra', 1, 101) as id;
select private.aplicar_llenado((select id from e0), 1, 100.00, 'filled');
create temp table e_antes as select pg_temp.ef(pg_temp.sub('arriesgadas')) as arr, pg_temp.ef(pg_temp.sub('reserva')) as reserva, pg_temp.ef(pg_temp.sub('usuarios_comun')) as comun;
create temp table e1 as select pg_temp.orden(pg_temp.sub('arriesgadas'), 'venta', 1, 120) as id;
select private.aplicar_llenado((select id from e1), 1, 120, 'filled');
select is(pg_temp.ef(pg_temp.sub('usuarios_comun')) - (select comun from e_antes), 5.00, 'CA-2 · el 25 % de Usuarios va a usuarios_comun');
select is(pg_temp.ef(pg_temp.sub('reserva')) - (select reserva from e_antes), 10.00, 'la Reserva recibe el 50 %');
select is(pg_temp.ef(pg_temp.sub('arriesgadas')) - (select arr from e_antes), 105.00, 'Arriesgadas recibe lo vendido y se queda con su 25 %');
select is((select count(*)::int from private.verificar_libro()), 0, 'el libro cuadra');

-- F · CB-19: un cupo pierde 100 y luego gana 100: termina con menos que al inicio
create temp table f_antes as select pg_temp.ef(pg_temp.cupo('1')) as cupo;
create temp table f0 as select pg_temp.orden(pg_temp.cupo('1'), 'compra', 1, 201) as id;
select private.aplicar_llenado((select id from f0), 1, 200, 'filled');
create temp table f1 as select pg_temp.orden(pg_temp.cupo('1'), 'venta', 1, 100) as id;
select private.aplicar_llenado((select id from f1), 1, 100, 'filled');
create temp table f2 as select pg_temp.orden(pg_temp.cupo('1'), 'compra', 1, 101) as id;
select private.aplicar_llenado((select id from f2), 1, 100, 'filled');
create temp table f3 as select pg_temp.orden(pg_temp.cupo('1'), 'venta', 1, 200) as id;
select private.aplicar_llenado((select id from f3), 1, 200, 'filled');
select is(pg_temp.ef(pg_temp.cupo('1')) - (select cupo from f_antes), -75.00, 'CB-19 · −100 y luego +100 (con reparto) dejan al cupo en −75');

-- G · una venta que se llena en dos partes reparte la ganancia de cada parte
create temp table g0 as select pg_temp.orden(pg_temp.cupo('2'), 'compra', 4, 101) as id;
select private.aplicar_llenado((select id from g0), 4, 100, 'filled');
create temp table g_antes as select pg_temp.ef(pg_temp.cupo('2')) as cupo, pg_temp.ef(pg_temp.sub('reserva')) as reserva, pg_temp.ef(pg_temp.sub('arriesgadas')) as arr;
create temp table g1 as select pg_temp.orden(pg_temp.cupo('2'), 'venta', 4, 110) as id;
select private.aplicar_llenado((select id from g1), 2, 110, 'partially_filled');
select is(pg_temp.ef(pg_temp.sub('reserva')) - (select reserva from g_antes), 10.00, 'el primer llenado (2 acciones, ganancia 20,00) manda 10,00 a la Reserva');
select private.aplicar_llenado((select id from g1), 4, 110, 'filled');
select is(pg_temp.ef(pg_temp.sub('reserva')) - (select reserva from g_antes), 20.00, 'el segundo suma otros 10,00');
select is(pg_temp.ef(pg_temp.sub('arriesgadas')) - (select arr from g_antes), 10.00, 'Arriesgadas 5,00 + 5,00');
select is(pg_temp.ef(pg_temp.cupo('2')) - (select cupo from g_antes), 410.00, 'el cupo recibe 440,00 y paga 30,00 (20,00 a la Reserva y 10,00 a Arriesgadas)');
select is((select count(*)::int from public.movimientos where tipo = 'reparto_ganancia' and referencia_id = (select id from g1)), 2, 'dos movimientos de reparto, uno por llenado');
select is((select count(*)::int from private.verificar_libro()), 0, 'el libro cuadra al final');

select * from finish();
rollback;

-- HU-074 · aplicar_llenado: diferencias, idempotencia, costo promedio, parciales y ventas.
-- Criterios: HU-074 CA-1 a CA-3, CA-5 y CA-6 (backlog/E-08). CA-4 de HU-074 (cancelar
-- por tiempo) se prueba aquí en su parte SQL y en `deno test` de sincronizar-ordenes. Sin sugerencias (D-65).
begin;
create extension if not exists pgtap with schema extensions;
select plan(65);

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

-- Correspondencia de estados (docs/08 §2.1)
select is(private.estado_desde_broker('new'), 'aceptada'::public.estado_orden, 'new → aceptada');
select is(private.estado_desde_broker('held'), 'aceptada'::public.estado_orden, 'held → aceptada');
select is(private.estado_desde_broker('partially_filled'), 'parcialmente_llenada'::public.estado_orden, 'partially_filled → parcialmente_llenada');
select is(private.estado_desde_broker('filled'), 'llenada'::public.estado_orden, 'filled → llenada');
select is(private.estado_desde_broker('done_for_day'), 'cancelada'::public.estado_orden, 'done_for_day → cancelada');
select is(private.estado_desde_broker('expired'), 'vencida'::public.estado_orden, 'expired → vencida');
select is(private.estado_desde_broker('suspended'), 'rechazada'::public.estado_orden, 'suspended → rechazada');
select is(private.estado_desde_broker('pending_cancel'), null, 'pending_cancel conserva el estado');
select throws_ok($$select private.estado_desde_broker('inventado')$$, '22023', null, 'un estado desconocido falla');
select ok(not has_function_privilege('authenticated', 'private.aplicar_llenado(uuid, numeric, numeric, text, numeric)', 'execute'), 'la API no ejecuta aplicar_llenado');

-- CA-1 · una compra llenada: libro, posición y retención
create temp table c1 as select pg_temp.orden(pg_temp.cupo('1'), 'compra', 1, 111.10, 111.10) as id;
select is(pg_temp.ret(pg_temp.cupo('1')), 111.10, 'la aprobación retuvo 111,10');
select is((private.aplicar_llenado((select id from c1), 1, 110.20, 'filled')).estado::text, 'llenada', 'CA-1 · la orden queda llenada');
select is(pg_temp.ef(pg_temp.cupo('1')), 889.80, 'efectivo −110,20');
select is(pg_temp.inv(pg_temp.cupo('1')), 110.20, 'invertido +110,20');
select is(pg_temp.ret(pg_temp.cupo('1')), 0.00, 'y se libera la retención');
select is(pg_temp.pos(pg_temp.cupo('1')), '(1.000000000,110.200000,110.20,abierta,0.00)', 'se crea la posición con costo promedio 110,20');
select is((select retencion from public.ordenes where id = (select id from c1)), 0.00, 'la orden ya no retiene nada');
select is((select cantidad_llenada || '/' || monto_llenado || '/' || precio_promedio_llenado from public.ordenes where id = (select id from c1)), '1.000000000/110.20/110.2000', 'la orden guarda lo llenado');
select is((select array_agg(estado_nuevo::text order by id) from public.ordenes_eventos where orden_id = (select id from c1) and estado_nuevo = 'llenada'), array['llenada'], 'queda el evento de llenada');
select is((select count(*)::int from private.verificar_libro()), 0, 'el libro cuadra');

-- CA-2 · el mismo llenado dos veces no cambia nada
select lives_ok($$select private.aplicar_llenado((select id from c1), 1, 110.20, 'filled')$$, 'CA-2 · repetir el llenado no falla');
select is(pg_temp.ef(pg_temp.cupo('1')), 889.80, 'y no vuelve a mover el efectivo');
select is(pg_temp.pos(pg_temp.cupo('1')), '(1.000000000,110.200000,110.20,abierta,0.00)', 'ni la posición');
select is(pg_temp.movs('compra'), 1, 'ni crea otro movimiento');
select throws_ok($$select private.aplicar_llenado((select id from c1), 2, 110.20, 'filled')$$, null, 'ESTADO_INVALIDO', 'una orden terminada no admite otro llenado');

-- CA-3 · costo promedio ponderado: 6 a 50,00 y luego 4 a 60,00 → 10 a 54,00
create temp table c2 as select pg_temp.orden(pg_temp.cupo('2'), 'compra', 6, 50, 303) as id;
select private.aplicar_llenado((select id from c2), 6, 50, 'filled');
create temp table c3 as select pg_temp.orden(pg_temp.cupo('2'), 'compra', 4, 60, 242) as id;
select private.aplicar_llenado((select id from c3), 4, 60, 'filled');
select is(pg_temp.pos(pg_temp.cupo('2')), '(10.000000000,54.000000,540.00,abierta,0.00)', 'CA-3 · 10 acciones a costo promedio 54,00');
select is(pg_temp.ret(pg_temp.cupo('2')), 0.00, 'las dos compras liberaron su retención (el sobrante también)');
select is(pg_temp.inv(pg_temp.cupo('2')), 540.00, 'el invertido del cupo es el costo de la posición');
create temp table v1 as select pg_temp.orden(pg_temp.cupo('2'), 'venta', 3, 55) as id;
select private.aplicar_llenado((select id from v1), 3, 55, 'filled');
select is(pg_temp.pos(pg_temp.cupo('2')), '(7.000000000,54.000000,378.00,abierta,3.00)', 'RN-25 · una venta no cambia el costo promedio de lo que queda');

-- CA-5 · llenado parcial y luego cancelación (CB-34)
create temp table p1 as select pg_temp.orden(pg_temp.cupo('1'), 'compra', 4, 101, 404) as id;
select is((private.aplicar_llenado((select id from p1), 2, 100, 'partially_filled')).estado::text, 'parcialmente_llenada', 'CA-5 · el llenado parcial deja la orden parcial');
select is(pg_temp.ret(pg_temp.cupo('1')), 202.00, 'libera la mitad de la retención');
select is(pg_temp.ef(pg_temp.cupo('1')), 689.80, 'y descuenta el costo de lo llenado');
select is((private.aplicar_llenado((select id from p1), 2, 100, 'partially_filled')).cantidad_llenada, 2.000000000, 'repetirlo no cambia nada');
select is(pg_temp.ef(pg_temp.cupo('1')), 689.80, 'efectivo igual');
select is((private.aplicar_llenado((select id from p1), 2, 100, 'canceled')).estado::text, 'cancelada', 'luego se cancela el resto');
select is(pg_temp.ret(pg_temp.cupo('1')), 0.00, 'libera el resto de la retención');
select is(pg_temp.pos(pg_temp.cupo('1')), '(3.000000000,103.400000,310.20,abierta,0.00)', 'la posición refleja lo llenado: 1 a 110,20 + 2 a 100,00 (costo promedio 103,40)');
select is((select cantidad_llenada from public.ordenes where id = (select id from p1)), 2.000000000, 'la orden conserva lo llenado');

-- Sin llenar y vencida (CB-38) o cancelada por tiempo (CB-35): libera todo
create temp table x1 as select pg_temp.orden(pg_temp.cupo('1'), 'compra', 1, 101, 101) as id;
select is((private.aplicar_llenado((select id from x1), 0, null, 'expired')).estado::text, 'vencida', 'CB-38 · una orden day que vence sin llenarse queda vencida');
select is(pg_temp.ret(pg_temp.cupo('1')), 0.00, 'y libera su retención');
select is((select count(*)::int from public.posiciones where subcuenta_id = pg_temp.cupo('1') and simbolo = pg_temp.simbolo()), 1, 'sin crear posición nueva');

-- Errores
create temp table e1 as select pg_temp.orden(pg_temp.cupo('1'), 'compra', 2, 100, 200) as id;
select throws_ok($$select private.aplicar_llenado((select id from e1), 3, 100, 'filled')$$, '22023', null, 'no se puede llenar más de lo que pide la orden');
select private.aplicar_llenado((select id from e1), 1, 100, 'partially_filled');
select throws_ok($$select private.aplicar_llenado((select id from e1), 0, null, 'new')$$, '22023', null, 'lo llenado no puede bajar');
select throws_ok($$select private.aplicar_llenado((select id from e1), 1, 0, 'partially_filled')$$, '22023', null, 'un llenado de más de cero necesita precio');
select throws_ok($$select private.aplicar_llenado(gen_random_uuid(), 1, 100, 'filled')$$, null, 'NO_EXISTE', 'una orden inexistente falla');
select private.aplicar_llenado((select id from e1), 1, 100, 'canceled');
create temp table e2 as select pg_temp.orden(pg_temp.cupo('1'), 'venta', 50, 100) as id;
select throws_ok($$select private.aplicar_llenado((select id from e2), 50, 100, 'filled')$$, null, 'POSICION_INSUFICIENTE', 'no se vende lo que no se tiene');
select is(pg_temp.est((select id from e2)), 'aceptada', 'y la orden queda como estaba');

-- Venta con ganancia (RN-27, docs/02 §7.1). La posición del cupo 1 tiene 4 acciones con costo 410,20.
-- El reparto 50/25/25 de la ganancia lo agrega HU-023: aquí la ganancia queda entera en el cupo.
create temp table g_antes as select pg_temp.ef(pg_temp.cupo('1')) as cupo, pg_temp.ef(pg_temp.sub('resultados')) as resultados;
create temp table s0 as select pg_temp.orden(pg_temp.cupo('1'), 'venta', 4, 123.20) as id;
select private.aplicar_llenado((select id from s0), 4, 123.20, 'filled');
select is(pg_temp.pos(pg_temp.cupo('1')), '(0.000000000,102.550000,0.00,cerrada,82.60)', 'la posición se cierra y acumula el resultado (4 × 123,20 − 410,20)');
select is(pg_temp.ef(pg_temp.cupo('1')) - (select cupo from g_antes), 492.80, 'el cupo recibe lo vendido');
select is(pg_temp.inv(pg_temp.cupo('1')), 0.00, 'RN-27 · el costo de lo vendido sale de invertido completo');
select is(pg_temp.ef(pg_temp.sub('resultados')) - (select resultados from g_antes), -82.60, 'resultados registra la ganancia');
select is((select count(*)::int from public.movimientos where tipo = 'venta' and referencia_id = (select id from s0)), 1, 'un movimiento de venta');
select private.aplicar_llenado((select id from s0), 4, 123.20, 'filled');
select is((select count(*)::int from public.movimientos where tipo = 'venta' and referencia_id = (select id from s0)), 1, 'repetir el llenado de la venta no crea otro');
select is((select count(*)::int from private.verificar_libro()), 0, 'el libro sigue cuadrando');

-- Venta con pérdida: la absorbe la subcuenta (el cupo 2 tiene 7 acciones a 54,00 más una nueva a 110,20)
create temp table n1 as select pg_temp.orden(pg_temp.cupo('2'), 'compra', 1, 111, 111) as id;
select private.aplicar_llenado((select id from n1), 1, 110.20, 'filled');
select is(pg_temp.pos(pg_temp.cupo('2')), '(8.000000000,61.025000,488.20,abierta,3.00)', 'el cupo 2 ahora tiene 8 acciones');
create temp table l_antes as select pg_temp.ef(pg_temp.cupo('2')) as cupo, pg_temp.ef(pg_temp.sub('resultados')) as resultados;
create temp table s1 as select pg_temp.orden(pg_temp.cupo('2'), 'venta', 8, 40) as id;
select private.aplicar_llenado((select id from s1), 8, 40, 'filled');
select is(pg_temp.ef(pg_temp.cupo('2')) - (select cupo from l_antes), 320.00, 'el cupo recibe lo vendido (8 × 40,00)');
select is(pg_temp.ef(pg_temp.sub('resultados')) - (select resultados from l_antes), 168.20, 'resultados absorbe la pérdida completa (488,20 − 320,00)');
select is(pg_temp.pos(pg_temp.cupo('2')), '(0.000000000,61.025000,0.00,cerrada,-165.20)', 'la posición cerrada acumula 3,00 − 168,20');
select is((select count(*)::int from private.verificar_libro()), 0, 'el libro cuadra al final');

-- Cancelación por tiempo (CB-35, CB-39): solo compras vivas con más de 5 minutos
create temp table t1 as select pg_temp.orden(pg_temp.cupo('1'), 'compra', 1, 100, 0, '2031-03-10 15:54:00+00') as id;
create temp table t2 as select pg_temp.orden(pg_temp.cupo('1'), 'compra', 1, 100, 0, '2031-03-10 15:59:00+00') as id;
create temp table t3 as select pg_temp.orden(pg_temp.cupo('1'), 'venta', 1, 100, 0, '2031-03-10 15:54:00+00') as id;
select is((select array_agg(orden_id) from private.ordenes_por_cancelar_por_tiempo() where orden_id in (select id from t1 union all select id from t2 union all select id from t3)),
          array[(select id from t1)], 'CB-35 · solo la compra con más de 5 minutos');
select ok(private.hay_ordenes_vivas(), 'hay órdenes que sincronizar');
select ok((select count(*) from private.ordenes_para_sincronizar() where orden_id in (select id from t1 union all select id from t2)) = 2, 'y la sincronización las lista');

-- Posiciones valoradas y RLS
create temp table vv as select pg_temp.orden(pg_temp.cupo('2'), 'compra', 2, 100, 0) as id;
select private.aplicar_llenado((select id from vv), 2, 90, 'filled');
insert into public.cotizaciones (simbolo, precio, fuente, momento) values (pg_temp.simbolo(), 100, 'simulado', '2031-03-10 16:00+00')
  on conflict (simbolo) do update set precio = 100;
select is((select valor_mercado || '/' || no_realizado from public.posiciones_valoradas where subcuenta_id = pg_temp.cupo('2') and estado = 'abierta' and simbolo = pg_temp.simbolo()), '200.00/20.00',
          'posiciones_valoradas: valor de mercado y ganancia no realizada al vuelo');
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select ok((select count(*) from public.posiciones) > 0 and (select count(*) from public.posiciones where subcuenta_id <> pg_temp.cupo('1')) = 0, 'el Usuario ve solo sus posiciones');
select ok(not has_table_privilege('authenticated', 'public.posiciones', 'insert'), 'y no escribe en ellas');
set local request.jwt.claims to '';
reset role;

select * from finish();
rollback;

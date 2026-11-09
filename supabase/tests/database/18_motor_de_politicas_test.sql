-- HU-037 · Motor de políticas: private.validar_operacion, una prueba que viola y otra que cumple por regla.
-- Criterios: CA-1 a CA-5 (backlog/E-05-motor-de-politicas-y-configuracion/HU-037-*.md). Reglas: docs/02 §9 y §10.
-- El reloj y los precios se controlan con p_momento y la tabla cotizaciones. CA-6 (REGLA_RR_xx en la app) lo
-- cubre test/core/errores. RR-10, RR-15, RR-16, RR-19 y RR-20 son de HU-038.
begin;
create extension if not exists pgtap with schema extensions;
select plan(45);

-- 0001 usuario con cupo activo · 0002 usuario suspendido con cupo.
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

-- Dinero: un aporte de 4.000 a usuarios_comun y 1.000 al cupo de la persona activa.
select private.registrar_movimiento('aporte', jsonb_build_array(
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'externa'), 'concepto', 'efectivo', 'monto', -4000),
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'usuarios_comun'), 'concepto', 'efectivo', 'monto', 4000)),
  null, 'Fondos de prueba');
select private.registrar_movimiento('asignacion_cupo', jsonb_build_array(
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'usuarios_comun'), 'concepto', 'efectivo', 'monto', -1000),
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001'), 'concepto', 'efectivo', 'monto', 1000)),
  null, 'Cupo de prueba');
update public.perfiles set estado = 'suspendido', suspendido_en = now() where id = '00000000-0000-4000-8000-000000000002';

-- Un día de mercado: 14:30 a 21:00 UTC; las compras entre 14:35 y 20:45.
insert into public.calendario_mercado (fecha, apertura, cierre, sesion)
values ('2031-03-10', '2031-03-10 14:30+00', '2031-03-10 21:00+00', 'regular');
-- Un símbolo de la lista blanca de Usuarios, con cotización fresca a las 16:00.
create function pg_temp.simbolo() returns text language sql as
  $$ select simbolo from public.lista_blanca where bolsillo = 'usuarios' and activo order by simbolo limit 1 $$;
insert into public.cotizaciones (simbolo, precio, fuente, momento)
values (pg_temp.simbolo(), 100, 'simulado', '2031-03-10 16:00+00');
update public.fondos set ia_activa = true, trading_activo = true;

create function pg_temp.cupo() returns uuid language sql as
  $$ select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001' $$;
-- Llama al motor con una compra válida por defecto: 400 con stop 8 %, a las 16:00:30.
create function pg_temp.v(
  p_sub uuid default null, p_simbolo text default null, p_lado text default 'compra', p_monto numeric default 400,
  p_cantidad numeric default 4, p_stop numeric default 8, p_confianza numeric default null,
  p_momento timestamptz default '2031-03-10 16:00:30+00'
) returns text[] language sql as
  $$ select private.validar_operacion(coalesce(p_sub, pg_temp.cupo()), coalesce(p_simbolo, pg_temp.simbolo()),
                                      p_lado, p_monto, p_cantidad, p_stop, p_confianza, p_momento) $$;

select ok(not has_function_privilege('authenticated', 'private.validar_operacion(uuid, text, text, numeric, numeric, numeric, numeric, timestamptz)', 'execute'),
          'la API no ejecuta el motor');

-- CA-5 · Una operación que cumple todo
select is(pg_temp.v(), '{}'::text[], 'CA-5 · una compra que cumple todo devuelve la lista vacía');
select is(pg_temp.v(p_lado => 'venta', p_stop => null, p_monto => 100), '{}'::text[], 'una venta que cumple todo también');
select is(pg_temp.v(p_confianza => 0.80), '{}'::text[], 'una sugerencia de la IA con confianza suficiente');

-- CA-1 · RR-01 lista blanca
select is(pg_temp.v(p_simbolo => 'ZZZZ'), array['RR-01', 'RR-11'], 'CA-1 · RR-01: un símbolo fuera de la lista blanca (y sin cotización: RR-11)');
select is(pg_temp.v(p_lado => 'venta', p_simbolo => 'ZZZZ', p_stop => null, p_monto => 100), array['RR-11'], 'RR-01 solo aplica a compras');

-- CA-2 · RR-03, RR-04, RR-05, RR-08
select ok('RR-03' = any(pg_temp.v(p_monto => 1000.01)), 'CA-2 · RR-03: más que el disponible');
update public.subcuentas set retenido = 700 where id = pg_temp.cupo();
select ok('RR-03' = any(pg_temp.v(p_monto => 400)), 'RR-03: el disponible descuenta lo retenido (300)');
update public.subcuentas set retenido = 0 where id = pg_temp.cupo();
select ok('RR-04' = any(pg_temp.v(p_monto => 500.01)), 'RR-04: más del 50 % del patrimonio en una operación');
select ok(not 'RR-04' = any(pg_temp.v(p_monto => 500)), 'RR-04: exactamente el 50 % cumple');
update public.parametros set valor = '30'::jsonb where clave = 'riesgo.cupo.max_pct_simbolo';
select ok('RR-05' = any(pg_temp.v(p_monto => 300.01)), 'RR-05: concentración sobre el máximo por símbolo (30 %)');
select ok(not 'RR-05' = any(pg_temp.v(p_monto => 300)), 'RR-05: justo en el máximo cumple');
update public.parametros set valor = '100'::jsonb where clave = 'riesgo.cupo.max_pct_simbolo';
select ok('RR-08' = any(pg_temp.v(p_stop => null)), 'CA-2 · RR-08: sin stop-loss');
select ok('RR-08' = any(pg_temp.v(p_stop => 1.9)), 'RR-08: stop bajo el mínimo del cupo (2 %)');
select ok('RR-08' = any(pg_temp.v(p_stop => 15.1)), 'RR-08: stop sobre el máximo del cupo (15 %)');
select ok(not 'RR-08' = any(pg_temp.v(p_stop => 2)) and not 'RR-08' = any(pg_temp.v(p_stop => 15)), 'RR-08: los extremos del rango cumplen');

-- CA-3 · RR-02, RR-06, RR-17
select ok('RR-02' = any(pg_temp.v(p_sub => (select id from public.subcuentas where tipo = 'reserva'))), 'CA-3 · RR-02: la Reserva no opera');
select ok('RR-02' = any(pg_temp.v(p_sub => (select id from public.subcuentas where tipo = 'usuarios_comun'))), 'RR-02: usuarios_comun no opera');
select ok('RR-06' = any(pg_temp.v(p_monto => 9.99)), 'CA-3 · RR-06: bajo la orden mínima (10)');
select ok(not 'RR-06' = any(pg_temp.v(p_monto => 10)), 'RR-06: la orden mínima cumple');
select ok('RR-06' = any(pg_temp.v(p_lado => 'venta', p_monto => 9.99, p_stop => null)), 'RR-06 también aplica a ventas');
select ok('RR-17' = any(pg_temp.v(p_sub => (select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000002'))),
          'CA-3 · RR-17: el destinatario suspendido');
select ok(not 'RR-17' = any(pg_temp.v()), 'RR-17: un destinatario activo cumple');

-- CA-4 · RR-07, RR-11, RR-14, RR-21
select ok('RR-07' = any(pg_temp.v(p_momento => '2031-03-10 14:00+00')), 'CA-4 · RR-07: antes de la apertura');
select ok('RR-07' = any(pg_temp.v(p_momento => '2031-03-10 21:30+00')), 'RR-07: después del cierre');
select ok('RR-07' = any(pg_temp.v(p_momento => '2031-03-10 14:34+00')), 'RR-07: una compra en los primeros 5 minutos');
select ok('RR-07' = any(pg_temp.v(p_momento => '2031-03-10 20:46+00')), 'RR-07: una compra en los últimos 15 minutos');
select ok(not 'RR-07' = any(pg_temp.v(p_lado => 'venta', p_stop => null, p_momento => '2031-03-10 20:50+00')), 'RR-07: una venta sí puede en los últimos 15 minutos');
select ok('RR-07' = any(pg_temp.v(p_momento => '2031-03-11 16:00+00')), 'RR-07: un día sin calendario (feriado o fin de semana)');
select ok('RR-11' = any(pg_temp.v(p_momento => '2031-03-10 16:01:01+00')), 'CA-4 · RR-11: cotización de hace más de 60 s');
select ok(not 'RR-11' = any(pg_temp.v(p_momento => '2031-03-10 16:01:00+00')), 'RR-11: justo 60 s cumple');
update public.fondos set trading_activo = false;
select ok('RR-14' = any(pg_temp.v()), 'CA-4 · RR-14: trading_activo apagado');
update public.fondos set trading_activo = true, ia_activa = false;
select ok(not 'RR-14' = any(pg_temp.v()) and 'RR-14' = any(pg_temp.v(p_confianza => 0.8)), 'RR-14: ia_activa apagado solo frena las sugerencias de la IA');
update public.fondos set ia_activa = true;
do $$ begin perform private.registrar_salud('alpaca_trading', false); perform private.registrar_salud('alpaca_trading', false); end $$;
select ok(not 'RR-21' = any(pg_temp.v()), 'RR-21: degradado todavía permite operar');
do $$ begin perform private.registrar_salud('alpaca_trading', false); end $$;
select ok('RR-21' = any(pg_temp.v()), 'CA-4 · RR-21: broker caído');
do $$ begin perform private.registrar_salud('alpaca_trading', true); perform private.registrar_salud('alpaca_datos', false); perform private.registrar_salud('alpaca_datos', false); perform private.registrar_salud('alpaca_datos', false); end $$;
select ok('RR-21' = any(pg_temp.v()), 'RR-21: datos de mercado caídos');
do $$ begin perform private.registrar_salud('alpaca_datos', true); end $$;

-- RR-09 · confianza
select ok('RR-09' = any(pg_temp.v(p_confianza => 0.64)), 'RR-09: confianza bajo el mínimo (0,65)');
select ok(not 'RR-09' = any(pg_temp.v(p_confianza => 0.65)), 'RR-09: justo el mínimo cumple');
select ok(not 'RR-09' = any(pg_temp.v()), 'RR-09 no aplica a una orden manual (sin confianza)');

-- RR-18 y RR-22
select ok('RR-18' = any(pg_temp.v(p_lado => 'corta')), 'RR-18: un lado que no es compra ni venta (cortos)');
select ok('RR-18' = any(pg_temp.v(p_simbolo => 'AAPL250117C00150000')), 'RR-18: un contrato de opciones no es un símbolo operable');
insert into public.conciliaciones (resultado) values ('descuadre_critico');
select ok('RR-22' = any(pg_temp.v()), 'RR-22: descuadre crítico sin revisar frena las compras');
update public.conciliaciones set revisada_en = now();
select ok(not 'RR-22' = any(pg_temp.v()), 'RR-22: revisado, vuelve a cumplir');

-- Varias reglas a la vez y errores del propio motor
select is(pg_temp.v(p_monto => 5000, p_stop => null), array['RR-03', 'RR-04', 'RR-05', 'RR-08'], 'varias reglas violadas a la vez, en orden');
select throws_ok($$select private.validar_operacion(gen_random_uuid(), 'QQQ', 'compra', 100, 1, 8, null, null)$$, 'P0001', 'NO_EXISTE', 'una subcuenta que no existe');

select * from finish();
rollback;

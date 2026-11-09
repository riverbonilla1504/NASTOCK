-- HU-075 · RPC crear_orden_manual.
-- Criterios: CA-2 a CA-6 (backlog/E-08-ejecucion-y-broker/HU-075-*.md). CA-1 (precarga de stop y objetivo) es de
-- la app: aquí se prueba que la RPC usa los parámetros por defecto cuando no recibe stop ni objetivo.
-- Reglas: docs/06 §8.1 y §9, docs/08 §7.5, docs/10 §5, RN-23, RN-24, RR-01, RR-03, RR-08, RR-11, RR-14, RR-15.
begin;
create extension if not exists pgtap with schema extensions;
select plan(48);

-- 0001 y 0002 usuarios con cupo · 0003 analista · 0004 administrador.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'uno@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'dos@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'admin@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'uno@prueba.test', 'Uno', 'usuario'),
  ('00000000-0000-4000-8000-000000000002', 'dos@prueba.test', 'Dos', 'usuario');
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000003', 'analista@prueba.test', 'Analista', 'analista', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000004', 'admin@prueba.test', 'Admin', 'administrador', 'activo', null, null);
select private.crear_cupo('00000000-0000-4000-8000-000000000001', 0);
select private.crear_cupo('00000000-0000-4000-8000-000000000002', 0);

select private.registrar_movimiento('aporte', jsonb_build_array(
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'externa'), 'concepto', 'efectivo', 'monto', -4000),
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'usuarios_comun'), 'concepto', 'efectivo', 'monto', 4000)),
  null, 'Fondos de prueba');
select private.registrar_movimiento('asignacion_cupo', jsonb_build_array(
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'usuarios_comun'), 'concepto', 'efectivo', 'monto', -2000),
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001'), 'concepto', 'efectivo', 'monto', 1000),
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000002'), 'concepto', 'efectivo', 'monto', 1000)),
  null, 'Cupos de prueba');

-- Una sesión de mercado: martes 10 de marzo de 2031, 14:30 a 21:00 UTC, y la del día siguiente.
insert into public.calendario_mercado (fecha, apertura, cierre, sesion) values
  ('2031-03-10', '2031-03-10 14:30+00', '2031-03-10 21:00+00', 'regular'),
  ('2031-03-11', '2031-03-11 14:30+00', '2031-03-11 21:00+00', 'regular');
create function pg_temp.simbolo() returns text language sql as
  $$ select simbolo from public.lista_blanca where bolsillo = 'usuarios' and activo order by simbolo limit 1 $$;
insert into public.cotizaciones (simbolo, precio, fuente, momento)
values (pg_temp.simbolo(), 100, 'simulado', '2031-03-10 16:00+00');
-- Un símbolo fuera de la lista blanca, con cotización fresca.
insert into public.cotizaciones (simbolo, precio, fuente, momento) values ('ZZZZ', 50, 'simulado', '2031-03-10 16:00+00');
update public.fondos set ia_activa = true, trading_activo = true;
select pruebas.fijar_reloj('2031-03-10 16:00:30+00');

create function pg_temp.cupo(p text default '1') returns uuid language sql as
  $$ select id from public.subcuentas where usuario_id = ('00000000-0000-4000-8000-00000000000' || p)::uuid $$;
create function pg_temp.retenido(p text default '1') returns numeric language sql as
  $$ select retenido from public.subcuentas where id = pg_temp.cupo(p) $$;
create function pg_temp.mensajes() returns int language sql security definer as $$ select count(*)::int from pgmq.q_ordenes_por_enviar $$;
create function pg_temp.ordenes() returns int language sql as $$ select count(*)::int from public.ordenes $$;
create function pg_temp.detalle_cierre() returns text language plpgsql as $$
declare v_detalle text;
begin
  perform public.crear_orden_manual('00000000-0000-4000-8000-0000000000d2', pg_temp.simbolo(), 'compra', 1);
  return 'sin error';
exception when others then
  get stacked diagnostics v_detalle = pg_exception_detail;
  return v_detalle;
end $$;
create function pg_temp.como(p text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', '00000000-0000-4000-8000-00000000000' || p, 'role', 'authenticated')::text, true);
end $$;
grant execute on function pg_temp.simbolo(), pg_temp.cupo(text), pg_temp.retenido(text), pg_temp.mensajes(),
  pg_temp.ordenes(), pg_temp.como(text), pg_temp.detalle_cierre() to authenticated;

-- Permisos
select ok(has_function_privilege('authenticated', 'public.crear_orden_manual(uuid, text, text, numeric, numeric, numeric)', 'execute'),
          'un usuario con sesión puede ejecutar crear_orden_manual');
select ok(not has_function_privilege('anon', 'public.crear_orden_manual(uuid, text, text, numeric, numeric, numeric)', 'execute'),
          'sin sesión no se ejecuta');

set local role authenticated;

-- CA-6 · solo el Usuario
select pg_temp.como('3');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000a1', pg_temp.simbolo(), 'compra', 1)$$,
                 'P0001', 'NO_AUTORIZADO', 'CA-6 · un analista recibe NO_AUTORIZADO');
select pg_temp.como('4');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000a1', pg_temp.simbolo(), 'compra', 1)$$,
                 'P0001', 'NO_AUTORIZADO', 'CA-6 · un administrador recibe NO_AUTORIZADO');
select pg_temp.como('9');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000a1', pg_temp.simbolo(), 'compra', 1)$$,
                 'P0001', 'SESION_INVALIDA', 'sin perfil activo, SESION_INVALIDA');

-- Forma de los datos
select pg_temp.como('1');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000a1', pg_temp.simbolo(), 'compra', 1.5)$$,
                 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'D-63 · una cantidad fraccional se rechaza');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000a1', pg_temp.simbolo(), 'compra', 0)$$,
                 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'una cantidad de cero se rechaza');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000a1', pg_temp.simbolo(), 'compra', null)$$,
                 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'sin cantidad se rechaza');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000a1', pg_temp.simbolo(), 'prestamo', 1)$$,
                 '22023', 'El lado debe ser compra o venta', 'un lado desconocido se rechaza');
select is(pg_temp.ordenes(), 0, 'ninguna de las llamadas inválidas creó una orden');

-- CA-2 · compra válida con los valores por defecto (stop 8 %, objetivo 15 %)
create temp table o as
  select (public.crear_orden_manual('00000000-0000-4000-8000-0000000000b1', pg_temp.simbolo(), 'compra', 4)).*;
grant select on o to authenticated;
select is((select estado::text from o), 'creada', 'CA-2 · la orden nace creada');
select is((select origen::text from o), 'manual', 'con origen manual');
select is((select opinion_id from o), null, 'D-60 · sin opinion_id');
select is((select clase::text || '/' || tipo::text || '/' || tif from o), 'bracket/limite/gtc', 'compra: bracket límite gtc (docs/10 §5)');
select is((select cantidad from o), 4::numeric, 'cantidad de 4 acciones');
select is((select precio_limite from o), 101.0000::numeric, 'límite = referencia 100 × (1 + banda 1 %) = 101,00');
select is((select bracket_stop_precio from o), 92.0000::numeric, 'stop por defecto 8 % sobre la referencia = 92,00');
select is((select bracket_objetivo_precio from o), 115.0000::numeric, 'objetivo por defecto 15 % sobre la referencia = 115,00');
select is((select retencion from o), 404.00::numeric, 'la orden retiene su monto (4 × 101,00)');
select is(pg_temp.retenido(), 404.00::numeric, 'CA-2 · el cupo retiene los fondos (RN-23)');
select is((select creada_por from o), '00000000-0000-4000-8000-000000000001'::uuid, 'guarda quién la creó');
select is((select (parametros ->> 'precio_referencia')::numeric from o), 100::numeric, 'guarda el precio de referencia para revalidar al enviar (RR-12)');
select is(pg_temp.mensajes(), 1, 'CA-2 · la orden entra a la cola ordenes_por_enviar');

reset role;
select is((select count(*)::int from public.auditoria where accion = 'orden.manual_creada'
            and entidad_id = '00000000-0000-4000-8000-0000000000b1'
            and actor_id = '00000000-0000-4000-8000-000000000001'), 1, 'CA-2 · registra orden.manual_creada');
set local role authenticated;
select pg_temp.como('1');

-- El motor de envío acepta lo que se creó (misma revalidación)
reset role;
select is((private.tomar_orden_para_envio('00000000-0000-4000-8000-0000000000b1'))->>'resultado', 'enviar',
          'el ejecutor revalida y toma la orden sin problema');
set local role authenticated;
select pg_temp.como('1');

-- CA-3 · idempotencia
select is((public.crear_orden_manual('00000000-0000-4000-8000-0000000000b1', pg_temp.simbolo(), 'compra', 4)).id,
          '00000000-0000-4000-8000-0000000000b1'::uuid, 'CA-3 · el mismo id devuelve la misma orden');
select is(pg_temp.ordenes(), 1, 'CA-3 · no la duplica');
select is(pg_temp.retenido(), 404.00::numeric, 'CA-3 · no retiene otra vez');
select is(pg_temp.mensajes(), 1, 'CA-3 · no la encola otra vez');
select pg_temp.como('2');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000b1', pg_temp.simbolo(), 'compra', 1)$$,
                 'P0001', 'NO_AUTORIZADO', 'el id de otro cupo no se devuelve ni se revela');
select pg_temp.como('1');

-- CA-5 · reglas de riesgo
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000e1', pg_temp.simbolo(), 'compra', 1, 1, 15)$$,
                 'P0001', 'REGLA_RR_08', 'CA-5 · un stop de 1 % (mínimo 2 %) viola RR-08');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000e2', pg_temp.simbolo(), 'compra', 1, 20, 15)$$,
                 'P0001', 'REGLA_RR_08', 'un stop de 20 % (máximo 15 %) viola RR-08');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000e3', 'ZZZZ', 'compra', 1)$$,
                 'P0001', 'REGLA_RR_01', 'un símbolo fuera de la lista blanca del bolsillo Usuarios viola RR-01');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000e4', pg_temp.simbolo(), 'compra', 5)$$,
                 'P0001', 'REGLA_RR_04', 'una compra de más del 50 % del cupo viola RR-04');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000e5', pg_temp.simbolo(), 'compra', 1, 8, 0)$$,
                 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'un objetivo de 0 % se rechaza');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000e6', pg_temp.simbolo(), 'compra', 20)$$,
                 'P0001', 'FONDOS_INSUFICIENTES', 'más de lo disponible: FONDOS_INSUFICIENTES (RR-03)');
select is(pg_temp.ordenes(), 1, 'las rechazadas no crearon orden');
select is(pg_temp.retenido(), 404.00::numeric, 'ni retuvieron fondos');

-- Ventas (sin cortos)
reset role;
insert into public.posiciones (subcuenta_id, simbolo, cantidad, costo_promedio, costo_total)
values (pg_temp.cupo(), pg_temp.simbolo(), 4, 100, 400);
set local role authenticated;
select pg_temp.como('1');
create temp table v as
  select (public.crear_orden_manual('00000000-0000-4000-8000-0000000000c1', pg_temp.simbolo(), 'venta', 3)).*;
grant select on v to authenticated;
select is((select clase::text || '/' || tipo::text || '/' || tif from v), 'simple/limite/day', 'venta: simple límite day (docs/10 §5)');
select is((select precio_limite from v), 99.0000::numeric, 'límite de venta = referencia × (1 − banda) = 99,00');
select is((select retencion from v), 0::numeric, 'una venta no retiene efectivo');
select is(pg_temp.retenido(), 404.00::numeric, 'y no cambia lo retenido');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000c2', pg_temp.simbolo(), 'venta', 2)$$,
                 'P0001', 'REGLA_RR_15', 'no se vende más de lo que queda libre (4 − 3 en una venta viva): sin cortos');

-- Interruptor y datos
reset role;
update public.fondos set trading_activo = false;
set local role authenticated;
select pg_temp.como('1');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000d1', pg_temp.simbolo(), 'compra', 1)$$,
                 'P0001', 'TRADING_PAUSADO', 'con el trading pausado: TRADING_PAUSADO');
reset role;
update public.fondos set trading_activo = true;
select pruebas.fijar_reloj('2031-03-10 16:10:00+00');
set local role authenticated;
select pg_temp.como('1');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000d1', pg_temp.simbolo(), 'compra', 1)$$,
                 'P0001', 'DATO_DESACTUALIZADO', 'con la cotización de hace 10 minutos: DATO_DESACTUALIZADO');

-- CA-4 · mercado cerrado, con la hora de apertura
reset role;
select pruebas.fijar_reloj('2031-03-10 22:00:00+00');
set local role authenticated;
select pg_temp.como('1');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000d2', pg_temp.simbolo(), 'compra', 1)$$,
                 'P0001', 'MERCADO_CERRADO', 'CA-4 · con el mercado cerrado: MERCADO_CERRADO');
select is(pg_temp.detalle_cierre(), '2031-03-11T14:30:00Z', 'CA-4 · el detalle trae la hora de la próxima apertura (UTC)');
reset role;
select pruebas.fijar_reloj('2031-03-10 14:32:00+00');
set local role authenticated;
select pg_temp.como('1');
select throws_ok($$select public.crear_orden_manual('00000000-0000-4000-8000-0000000000d3', pg_temp.simbolo(), 'compra', 1)$$,
                 'P0001', 'FUERA_DE_VENTANA', 'a los 2 minutos de abrir no se compra: FUERA_DE_VENTANA');

select * from finish();
rollback;

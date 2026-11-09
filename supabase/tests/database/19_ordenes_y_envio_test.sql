-- HU-073 · Órdenes, cola de envío, revalidación y cierre del envío.
-- Criterios: CA-1, CA-3 a CA-6 (backlog/E-08-ejecucion-y-broker/HU-073-*.md). Reglas: docs/08 §2, docs/05 §8,
-- docs/10 §10, docs/12 CB-33, CB-36 y CB-68. CA-2 (tipo de orden) y CA-7 (secreto interno) los cubren
-- `deno test` de ejecutor-ordenes. Las órdenes las crea HU-075; aquí se insertan directo.
begin;
create extension if not exists pgtap with schema extensions;
select plan(55);

-- 0001 usuario con cupo · 0002 otro usuario con cupo · 0003 analista.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'uno@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'dos@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'analista@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'uno@prueba.test', 'Uno', 'usuario'),
  ('00000000-0000-4000-8000-000000000002', 'dos@prueba.test', 'Dos', 'usuario');
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000003', 'analista@prueba.test', 'Analista', 'analista', 'activo', null, null);
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

insert into public.calendario_mercado (fecha, apertura, cierre, sesion)
values ('2031-03-10', '2031-03-10 14:30+00', '2031-03-10 21:00+00', 'regular');
create function pg_temp.simbolo() returns text language sql as
  $$ select simbolo from public.lista_blanca where bolsillo = 'usuarios' and activo order by simbolo limit 1 $$;
insert into public.cotizaciones (simbolo, precio, fuente, momento)
values (pg_temp.simbolo(), 100, 'simulado', '2031-03-10 16:00+00');
update public.fondos set ia_activa = true, trading_activo = true;
select pruebas.fijar_reloj('2031-03-10 16:00:30+00');

create function pg_temp.cupo(p text default '1') returns uuid language sql as
  $$ select id from public.subcuentas where usuario_id = ('00000000-0000-4000-8000-00000000000' || p)::uuid $$;
-- Una compra de 4 acciones a 100 con stop 92 y objetivo 110, que retiene 400 del cupo (RN-23).
create function pg_temp.compra(p_cupo text default '1', p_ref numeric default 100) returns uuid language plpgsql as $$
declare v_id uuid;
begin
  update public.subcuentas set retenido = retenido + 400 where id = pg_temp.cupo(p_cupo);
  insert into public.ordenes (origen, subcuenta_id, creada_por, simbolo, lado, clase, tipo, tif, cantidad, precio_limite,
                              bracket_stop_precio, bracket_objetivo_precio, retencion, parametros)
  values ('manual', pg_temp.cupo(p_cupo), ('00000000-0000-4000-8000-00000000000' || p_cupo)::uuid, pg_temp.simbolo(),
          'compra', 'bracket', 'limite', 'gtc', 4, 100, 92, 110, 400,
          jsonb_build_object('precio_referencia', p_ref))
  returning id into v_id;
  return v_id;
end $$;
grant execute on function pg_temp.cupo(text) to authenticated;
create function pg_temp.estado(p uuid) returns text language sql as $$ select estado::text from public.ordenes where id = p $$;
create function pg_temp.retenido(p text default '1') returns numeric language sql as $$ select retenido from public.subcuentas where id = pg_temp.cupo(p) $$;
create function pg_temp.mensajes() returns int language sql as $$ select count(*)::int from pgmq.q_ordenes_por_enviar $$;

-- Estructura y permisos
select has_table('public', 'ordenes', 'existe ordenes');
select has_table('public', 'ordenes_eventos', 'existe ordenes_eventos');
select ok((select relrowsecurity from pg_class where oid = 'public.ordenes'::regclass), 'ordenes tiene RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.ordenes_eventos'::regclass), 'ordenes_eventos tiene RLS');
select ok(not has_table_privilege('authenticated', 'public.ordenes', 'insert')
          and not has_table_privilege('authenticated', 'public.ordenes', 'update')
          and not has_table_privilege('authenticated', 'public.ordenes', 'delete'), 'la app no escribe en ordenes');
select ok(not has_function_privilege('authenticated', 'private.tomar_orden_para_envio(uuid)', 'execute')
          and not has_function_privilege('authenticated', 'private.registrar_respuesta_envio(uuid, text, public.estado_orden, text, jsonb)', 'execute')
          and not has_function_privilege('authenticated', 'private.registrar_error_envio(uuid, public.estado_orden, text, jsonb)', 'execute'),
          'la API no ejecuta las funciones del envío');
select throws_ok($$insert into public.ordenes (origen, subcuenta_id, simbolo, lado, clase, tipo, tif, cantidad, monto_nocional, parametros)
                   values ('manual', pg_temp.cupo(), 'AAPL', 'compra', 'simple', 'limite', 'day', 1, 100, '{}')$$,
                  '23514', null, 'una orden lleva cantidad o monto, no ambos');
select throws_ok($$insert into public.ordenes (origen, subcuenta_id, simbolo, lado, clase, tipo, tif, cantidad, precio_limite, parametros)
                   values ('manual', pg_temp.cupo(), 'AAPL', 'compra', 'bracket', 'limite', 'gtc', 1, 100, '{}')$$,
                  '23514', null, 'un bracket lleva stop y objetivo');

-- La orden entra a la cola y publica su evento
select is(pg_temp.mensajes(), 0, 'la cola empieza vacía');
select is(private.hay_ordenes_por_enviar(), false, 'sin mensajes, el barrido no despierta al ejecutor');
create temp table o as select pg_temp.compra() as id;
select is(pg_temp.estado((select id from o)), 'creada', 'la orden nace creada');
select is(pg_temp.mensajes(), 1, 'la orden nueva entra a ordenes_por_enviar');
select is(private.hay_ordenes_por_enviar(), true, 'con un mensaje, el barrido despierta al ejecutor');
select is((select count(*)::int from realtime.messages where event = 'orden' and private and topic = 'supervision'
           and payload->>'id' = (select id::text from o)), 1, 'el evento orden llega a supervision, con id y estado y sin montos');
select is((select count(*)::int from realtime.messages where event = 'orden' and topic = 'usuario:00000000-0000-4000-8000-000000000001'), 1,
          'y al canal de su dueño');
select is((select count(*)::int from realtime.messages where event = 'orden' and payload::text ~ '(monto|cantidad|precio)'), 0, 'el evento no lleva montos');

-- CA-1 · tomar_orden_para_envio revalida y marca enviada
select is((private.tomar_orden_para_envio((select id from o)))->>'resultado', 'enviar', 'CA-1 · la orden válida se toma para enviar');
select is(pg_temp.estado((select id from o)), 'enviada', 'queda enviada');
select is((select intentos_envio from public.ordenes where id = (select id from o)), 1, 'cuenta el intento');
select is(pg_temp.retenido(), 400::numeric, 'la retención sigue en pie: el motor no la cuenta dos veces');
select is((private.tomar_orden_para_envio((select id from o)))->>'resultado', 'consultar',
          'una segunda toma no reenvía: pide consultar al broker por client_order_id (CB-33)');
select is((private.tomar_orden_para_envio((select id from o)))->'orden'->>'id', (select id::text from o), 'y devuelve la orden con su id');

-- Respuesta del broker
select is(pg_temp.estado((private.registrar_respuesta_envio((select id from o), 'broker-1', 'aceptada', 'new', '{"estado":"accepted"}')).id), 'aceptada', 'el broker la aceptó');
select is((select broker_order_id from public.ordenes where id = (select id from o)), 'broker-1', 'guarda el id del broker');
select throws_ok($$select private.registrar_respuesta_envio((select id from o), 'broker-2')$$, null, 'ESTADO_INVALIDO',
                 'no se acepta dos veces');
select is((private.tomar_orden_para_envio((select id from o)))->>'resultado', 'ya_resuelta', 'una aceptada ya no se envía');
select is((select array_agg(estado_nuevo::text order by id) from public.ordenes_eventos where orden_id = (select id from o)),
          array['enviada', 'aceptada'], 'la historia registra enviada y aceptada');
select is((select detalle::text from public.ordenes_eventos where orden_id = (select id from o) and estado_nuevo = 'aceptada'), '{"estado": "accepted"}',
          'y la respuesta del broker, sin llaves');

-- CA-4 · Revalidación que falla: mercado cerrado, banda, interruptor
select pruebas.fijar_reloj('2031-03-10 22:00:00+00');
create temp table cerrada as select pg_temp.compra() as id;
select ok((private.tomar_orden_para_envio((select id from cerrada)))->'reglas' ? 'RR-07', 'CA-4 · mercado cerrado: RR-07 (y la cotización ya no es fresca)');
select is(pg_temp.estado((select id from cerrada)), 'error_envio', 'la orden queda en error_envio');
select ok((select motivo_rechazo like '%RR-07%' from public.ordenes where id = (select id from cerrada)), 'con el motivo');
select is(pg_temp.retenido(), 400::numeric, 'y se libera su retención (solo queda la de la orden aceptada)');
select pruebas.fijar_reloj('2031-03-10 16:00:30+00');

create temp table banda as select pg_temp.compra('1', 98) as id;
select is((private.tomar_orden_para_envio((select id from banda)))->'reglas', '["RR-12"]'::jsonb, 'la banda de precio (RR-12): 98 → 100 se salió del 1 %');
select is(pg_temp.estado((select id from banda)), 'error_envio', 'banda: error_envio');

create temp table sin_ref as select pg_temp.compra('1', null) as id;
select is((private.tomar_orden_para_envio((select id from sin_ref)))->'reglas', '["RR-12"]'::jsonb, 'sin precio de referencia no hay banda que comprobar: RR-12');

update public.fondos set trading_activo = false;
create temp table apagada as select pg_temp.compra() as id;
select is((private.tomar_orden_para_envio((select id from apagada)))->'reglas', '["RR-14"]'::jsonb, 'con el interruptor apagado: RR-14');
update public.fondos set trading_activo = true;
select is(pg_temp.retenido(), 400::numeric, 'cada orden fallida libera lo suyo');

-- CB-33 · sin respuesta → desconocida → se resuelve
create temp table dudosa as select pg_temp.compra('2') as id;
select is((private.tomar_orden_para_envio((select id from dudosa)))->>'resultado', 'enviar', 'la segunda persona envía su orden');
select is(pg_temp.estado((private.registrar_error_envio((select id from dudosa), 'desconocida', 'SIN_RESPUESTA')).id), 'desconocida', 'CB-33 · sin respuesta: desconocida');
select is(pg_temp.retenido('2'), 400::numeric, 'desconocida no libera la retención: la orden puede existir');
select is(pg_temp.estado((private.registrar_respuesta_envio((select id from dudosa), 'broker-3')).id), 'aceptada', 'si el broker la tiene, sigue como aceptada');

create temp table perdida as select pg_temp.compra('2') as id;
select private.tomar_orden_para_envio((select id from perdida));
select private.registrar_error_envio((select id from perdida), 'desconocida', 'SIN_RESPUESTA');
select is(pg_temp.estado((private.registrar_error_envio((select id from perdida), 'error_envio', 'NO_EXISTE_EN_BROKER')).id), 'error_envio',
          'si el broker no la tiene: error_envio');
select is(pg_temp.retenido('2'), 400::numeric, 'y libera su retención');

-- CB-36 · rechazo por fondos
create temp table rechazada as select pg_temp.compra('2') as id;
select private.tomar_orden_para_envio((select id from rechazada));
select is(pg_temp.estado((private.registrar_error_envio((select id from rechazada), 'rechazada', 'FONDOS_INSUFICIENTES', '{"codigo":403}')).id), 'rechazada',
          'CA-5 · CB-36: el rechazo por fondos deja la orden rechazada');
select is((select count(*)::int from public.auditoria where accion = 'orden.rechazada_por_fondos' and entidad_id = (select id::text from rechazada)), 1,
          'y audita el posible descuadre');
select throws_ok($$select private.registrar_error_envio((select id from rechazada), 'error_envio', 'X')$$, null, 'ESTADO_INVALIDO', 'una orden terminada no cambia');
select throws_ok($$select private.registrar_error_envio((select id from rechazada), 'llenada', 'X')$$, '22023', null, 'solo acepta los estados de error');

-- CB-68 · la cola agota sus lecturas
create temp table agotada as select pg_temp.compra('2') as id;
select is((select count(*)::int from private.leer_ordenes_por_enviar(100) where orden_id = (select id from agotada)), 1, 'CB-68 · la cola entrega el mensaje');
do $$
declare v_msg bigint; i int;
begin
  for i in 1..5 loop
    select msg_id into v_msg from pgmq.q_ordenes_por_enviar where message->>'orden_id' = (select id::text from agotada);
    perform pgmq.set_vt('ordenes_por_enviar', v_msg, 0);
    perform * from private.leer_ordenes_por_enviar(100);
  end loop;
end $$;
select is(pg_temp.estado((select id from agotada)), 'error_envio', 'al quinto intento la orden queda en error_envio');
select is((select motivo_rechazo from public.ordenes where id = (select id from agotada)), 'COLA_AGOTADA', 'con el motivo COLA_AGOTADA');
select is((select count(*)::int from pgmq.q_ordenes_por_enviar where message->>'orden_id' = (select id::text from agotada)), 0, 'y el mensaje sale de la cola');

-- Confirmar un mensaje
create temp table nueva as select pg_temp.compra('1', 100) as id;
select ok(private.confirmar_orden_por_enviar((select msg_id from pgmq.q_ordenes_por_enviar where message->>'orden_id' = (select id::text from nueva))), 'confirmar un mensaje lo archiva');

-- RLS: el dueño ve lo suyo, el otro no, el analista todo
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select ok((select count(*) from public.ordenes) > 0 and (select count(*) from public.ordenes where subcuenta_id <> pg_temp.cupo()) = 0, 'el Usuario ve solo sus órdenes');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select ok((select count(*) from public.ordenes where subcuenta_id = pg_temp.cupo('2')) > 0, 'el Analista ve las de todos');
select ok((select count(*) from public.ordenes_eventos) > 0, 'y sus eventos');
set local request.jwt.claims to '';
reset role;

select * from finish();
rollback;

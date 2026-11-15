-- HU-076 · dueño, retención, carrera con llenado, parcial e idempotencia.
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();
set local session_replication_role=replica;
insert into auth.users(id,email) values
 ('07600000-0000-4000-8000-000000000001','cancelaruno@prueba.test'),
 ('07600000-0000-4000-8000-000000000002','cancelardos@prueba.test');
set local session_replication_role=origin;
insert into public.perfiles(id,email,nombre,rol) values
 ('07600000-0000-4000-8000-000000000001','cancelaruno@prueba.test','Uno','usuario'),
 ('07600000-0000-4000-8000-000000000002','cancelardos@prueba.test','Dos','usuario');
select private.crear_cupo('07600000-0000-4000-8000-000000000001',0);
select private.crear_cupo('07600000-0000-4000-8000-000000000002',0);
create function pg_temp.cupo() returns uuid language sql as $$select id from public.subcuentas where usuario_id='07600000-0000-4000-8000-000000000001' and estado='abierta'$$;
select private.registrar_movimiento('aporte',jsonb_build_array(
 jsonb_build_object('subcuenta_id',(select id from public.subcuentas where tipo='externa'),'concepto','efectivo','monto',-1000),
 jsonb_build_object('subcuenta_id',pg_temp.cupo(),'concepto','efectivo','monto',1000)),null,'Fondos para probar cancelaciones');
insert into public.ordenes(id,origen,subcuenta_id,simbolo,lado,clase,tipo,tif,cantidad,precio_limite,retencion,parametros)
 select ('07600000-0000-4000-8000-00000000001'||i)::uuid,'manual',pg_temp.cupo(),'AAPL','compra','simple','limite','day',2,50,100,'{}'
 from generate_series(1,3) i;
update public.ordenes set estado='aceptada',broker_order_id='broker-'||id,enviada_en=private.ahora()
 where id::text like '07600000-%';
update public.subcuentas set retenido=300 where id=pg_temp.cupo();

set local role authenticated;
set local request.jwt.claims='{"sub":"07600000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.cancelar_orden('07600000-0000-4000-8000-000000000011')$$,'P0001','NO_AUTORIZADO','CA-5: no cancela orden ajena');
select is((select count(*)::int from public.ordenes where id::text like '07600000-%'),0,'no lee órdenes ajenas');
set local request.jwt.claims='{"sub":"07600000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.cancelar_orden('07600000-0000-4000-8000-000000000011')$$,'CA-2: solicita cancelación propia');
select lives_ok($$select public.cancelar_orden('07600000-0000-4000-8000-000000000011')$$,'reintento de solicitud idempotente');
reset role;
select is((select retenido from public.subcuentas where id=pg_temp.cupo()),300::numeric,'solicitar no libera retención');
select ok(exists(select 1 from private.ordenes_por_cancelar() where orden_id='07600000-0000-4000-8000-000000000011'),'sincronizador recibe solicitud');
select private.aplicar_llenado('07600000-0000-4000-8000-000000000011',0,null,'canceled',0);
select is((select estado::text from public.ordenes where id='07600000-0000-4000-8000-000000000011'),'cancelada','confirmación del broker cancela');
select is((select retenido from public.subcuentas where id=pg_temp.cupo()),200::numeric,'libera solo al confirmar');
select is((select count(*)::int from public.auditoria where accion='orden.cancelada' and entidad_id='07600000-0000-4000-8000-000000000011'),1,'auditoría confirmada una vez');
select public.cancelar_orden('07600000-0000-4000-8000-000000000011');
select is((select count(*)::int from public.auditoria where accion='orden.cancelada' and entidad_id='07600000-0000-4000-8000-000000000011'),1,'reintento confirmado no duplica auditoría');

select public.cancelar_orden('07600000-0000-4000-8000-000000000012');
select private.aplicar_llenado('07600000-0000-4000-8000-000000000012',1,50,'canceled',0);
select is((select cantidad_llenada from public.ordenes where id='07600000-0000-4000-8000-000000000012'),1::numeric,'CA-4: conserva llenado parcial');
select is((select cantidad from public.posiciones where subcuenta_id=pg_temp.cupo() and simbolo='AAPL' and estado='abierta'),1::numeric,'conserva posición');
select is((select retenido from public.subcuentas where id=pg_temp.cupo()),100::numeric,'libera solo resto cancelado');
select public.cancelar_orden('07600000-0000-4000-8000-000000000013');
select private.aplicar_llenado('07600000-0000-4000-8000-000000000013',2,50,'filled',0);
select is((select estado::text from public.ordenes where id='07600000-0000-4000-8000-000000000013'),'llenada','CA-3: llenado gana la carrera');
select throws_ok($$select public.cancelar_orden('07600000-0000-4000-8000-000000000013')$$,'P0001','ESTADO_INVALIDO','no cancela una llenada');
select is((select count(*)::int from public.auditoria where accion='orden.cancelada' and entidad_id='07600000-0000-4000-8000-000000000013'),0,'no registra cancelación falsa');
select is((select retenido from public.subcuentas where id=pg_temp.cupo()),0::numeric,'sin retención residual');
select * from finish();
rollback;

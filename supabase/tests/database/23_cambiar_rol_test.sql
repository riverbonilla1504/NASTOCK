-- HU-011 · FR-032/033; CA-1 a CA-5. Cada rechazo conserva perfil y libro.
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();
set local session_replication_role = replica;
insert into auth.users(id, email) values
 ('01100000-0000-4000-8000-000000000001', 'roladmin@prueba.test'),
 ('01100000-0000-4000-8000-000000000002', 'rolanalista@prueba.test'),
 ('01100000-0000-4000-8000-000000000003', 'rolusuario@prueba.test'),
 ('01100000-0000-4000-8000-000000000004', 'rolootroadmin@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles(id,email,nombre,rol) values
 ('01100000-0000-4000-8000-000000000001','roladmin@prueba.test','Admin','administrador'),
 ('01100000-0000-4000-8000-000000000002','rolanalista@prueba.test','Analista','analista'),
 ('01100000-0000-4000-8000-000000000003','rolusuario@prueba.test','Usuario','usuario'),
 ('01100000-0000-4000-8000-000000000004','rolootroadmin@prueba.test','Otro admin','administrador');
select private.crear_cupo('01100000-0000-4000-8000-000000000003',0);

select ok(not has_function_privilege('anon','public.cambiar_rol(uuid,public.rol_app)','execute'), 'anon no puede ejecutar');
set local role authenticated;
set local request.jwt.claims = '';
select throws_ok($$select public.cambiar_rol('01100000-0000-4000-8000-000000000002','usuario')$$,'P0001','SESION_INVALIDA','sin sesión');
set local request.jwt.claims = '{"sub":"01100000-0000-4000-8000-000000000003","role":"authenticated","app_rol":"administrador"}';
select throws_ok($$select public.cambiar_rol('01100000-0000-4000-8000-000000000002','usuario')$$,'P0001','NO_AUTORIZADO','CA-5: Usuario incluso con claim administrador');
set local request.jwt.claims = '{"sub":"01100000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.cambiar_rol('01100000-0000-4000-8000-000000000003','analista')$$,'P0001','NO_AUTORIZADO','CA-5: Analista');
set local request.jwt.claims = '{"sub":"01100000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.cambiar_rol('01100000-0000-4000-8000-000000000001','analista')$$,'P0001','AUTO_ACCION','CA-4: acción propia');
select throws_ok($$select public.cambiar_rol('01100000-0000-4000-8000-000000000099','analista')$$,'P0001','NO_EXISTE','destino inexistente');
select lives_ok($$select public.cambiar_rol('01100000-0000-4000-8000-000000000002','usuario')$$,'CA-1: Analista pasa a Usuario');
reset role;
select is((select rol::text from public.perfiles where id='01100000-0000-4000-8000-000000000002'),'usuario','rol actualizado');
select is((select efectivo from public.subcuentas where usuario_id='01100000-0000-4000-8000-000000000002' and estado='abierta'),0::numeric,'cupo en cero');
select is((select count(*)::int from public.auditoria where accion='cuenta.rol_cambiado' and entidad_id='01100000-0000-4000-8000-000000000002'),1,'auditoría de cambio');
select is((select count(*)::int from realtime.messages where topic='usuario:01100000-0000-4000-8000-000000000002' and event='perfil_actualizado' and private),1,'evento privado del destino');

select private.registrar_movimiento('aporte', jsonb_build_array(
 jsonb_build_object('subcuenta_id',(select id from public.subcuentas where tipo='externa'),'concepto','efectivo','monto',-100),
 jsonb_build_object('subcuenta_id',(select id from public.subcuentas where usuario_id='01100000-0000-4000-8000-000000000003' and estado='abierta'),'concepto','efectivo','monto',100)),null,'Efectivo para probar cierre');
create temp table antes_comun as select efectivo from public.subcuentas where tipo='usuarios_comun';
set local role authenticated;
select lives_ok($$select public.cambiar_rol('01100000-0000-4000-8000-000000000003','analista')$$,'CA-2: Usuario sale con efectivo');
reset role;
select is((select estado::text from public.subcuentas where usuario_id='01100000-0000-4000-8000-000000000003'),'cerrada','cupo cerrado');
select is((select efectivo from public.subcuentas where usuario_id='01100000-0000-4000-8000-000000000003'),0::numeric,'cupo sin efectivo');
select is((select efectivo from public.subcuentas where tipo='usuarios_comun'),(select efectivo+100 from antes_comun),'efectivo vuelve a común');
select is((select count(*)::int from public.movimientos where tipo='cierre_cupo'),1,'movimiento cierre_cupo');

-- Volver a Usuario crea un cupo nuevo, sin revivir el cerrado.
select public.cambiar_rol('01100000-0000-4000-8000-000000000003','usuario');
insert into public.posiciones(subcuenta_id,simbolo,cantidad,costo_promedio,costo_total)
 select id,'AAPL',1,10,10 from public.subcuentas where usuario_id='01100000-0000-4000-8000-000000000003' and estado='abierta';
set local role authenticated;
select throws_ok($$select public.cambiar_rol('01100000-0000-4000-8000-000000000003','analista')$$,'P0001','CUPO_CON_POSICIONES','CA-3: posición abierta');
reset role;
update public.posiciones set estado='cerrada',cantidad=0,costo_total=0 where subcuenta_id in
 (select id from public.subcuentas where usuario_id='01100000-0000-4000-8000-000000000003');
insert into public.ordenes(id,origen,subcuenta_id,simbolo,lado,clase,tipo,tif,cantidad,parametros)
 select '01100000-0000-4000-8000-000000000099','manual',id,'AAPL','compra','simple','limite','day',1,'{}'
 from public.subcuentas where usuario_id='01100000-0000-4000-8000-000000000003' and estado='abierta';
set local role authenticated;
select throws_ok($$select public.cambiar_rol('01100000-0000-4000-8000-000000000003','analista')$$,'P0001','CUPO_CON_POSICIONES','CA-3: orden viva aunque no haya posiciones');
reset role;
select is((select rol::text from public.perfiles where id='01100000-0000-4000-8000-000000000003'),'usuario','rechazo conserva rol');
select is((select estado::text from public.subcuentas where usuario_id='01100000-0000-4000-8000-000000000003' and estado='abierta'),'abierta','rechazo conserva cupo');

-- Quitar los demás administradores activos de esta transacción deja uno solo.
update public.perfiles set estado='suspendido' where rol='administrador' and id<>'01100000-0000-4000-8000-000000000001';
set local role authenticated;
select throws_ok($$select public.cambiar_rol('01100000-0000-4000-8000-000000000001','analista')$$,'P0001','ULTIMO_ADMIN','CA-4: último administrador prevalece');
reset role;
select * from finish();
rollback;

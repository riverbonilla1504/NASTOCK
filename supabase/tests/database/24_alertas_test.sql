-- HU-085 · Todos los CA: audiencia por perfil, clave activa única, rearme y calendario.
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();
set local session_replication_role = replica;
insert into auth.users(id,email) values
 ('08500000-0000-4000-8000-000000000001','alertausuario@prueba.test'),
 ('08500000-0000-4000-8000-000000000002','alertaanalista@prueba.test'),
 ('08500000-0000-4000-8000-000000000003','alertaadmin@prueba.test'),
 ('08500000-0000-4000-8000-000000000004','alertaotro@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles(id,email,nombre,rol) values
 ('08500000-0000-4000-8000-000000000001','alertausuario@prueba.test','Usuario','usuario'),
 ('08500000-0000-4000-8000-000000000002','alertaanalista@prueba.test','Analista','analista'),
 ('08500000-0000-4000-8000-000000000003','alertaadmin@prueba.test','Admin','administrador'),
 ('08500000-0000-4000-8000-000000000004','alertaotro@prueba.test','Otro','usuario');

select private.crear_alerta('prueba085','todos','Para todos','Cuerpo','085-todos');
select private.crear_alerta('prueba085','analistas','Supervisión','Cuerpo','085-analistas');
select private.crear_alerta('prueba085','administradores','Administración','Cuerpo','085-admin');
select private.crear_alerta('prueba085','usuario','Personal','Cuerpo','085-personal','08500000-0000-4000-8000-000000000001');
select private.crear_alerta('prueba085','usuario','Personal admin','Cuerpo','085-personal-admin','08500000-0000-4000-8000-000000000003');
create temp table original as select id from public.alertas where clave_dedup='085-todos';
select is(private.crear_alerta('prueba085','todos','Repetida','Cuerpo','085-todos'),(select id from original),'CA-2: misma clave devuelve id existente');
select is((select count(*)::int from public.alertas where clave_dedup='085-todos'),1,'sin fila duplicada');
select is((select count(*)::int from realtime.messages where event='alerta' and payload->>'id'=(select id::text from original)),1,'sin aviso duplicado');
select private.resolver_alerta('085-todos');
select ok((select not activa and resuelta_en is not null and version=2 from public.alertas where id=(select id from original)),'resolución coherente y versionada');
select isnt(private.crear_alerta('prueba085','todos','Otra vez','Cuerpo','085-todos'),(select id from original),'CA-3: rearme crea id nuevo');

set local role authenticated;
set local request.jwt.claims='{"sub":"08500000-0000-4000-8000-000000000001","role":"authenticated","app_rol":"administrador"}';
select is((select count(*)::int from public.alertas where tipo='prueba085' and activa),2,'CA-1/4: Usuario solo todos y propia, sin confiar en claims');
select is((select count(*)::int from public.alertas where audiencia in ('analistas','administradores')),0,'sin alertas de supervisores');
select throws_ok($$insert into public.alertas(tipo,severidad,audiencia,titulo,cuerpo,clave_dedup) values ('prueba085','info','todos','No','No','085-no')$$,'42501',null,'sin escritura directa');
select ok(not has_function_privilege('authenticated','private.resolver_alerta(text)','execute'),'no resuelve alertas por API');
set local request.jwt.claims='{"sub":"08500000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select count(*)::int from public.alertas where tipo='prueba085' and activa),2,'Analista ve todos y analistas');
set local request.jwt.claims='{"sub":"08500000-0000-4000-8000-000000000003","role":"authenticated"}';
select is((select count(*)::int from public.alertas where tipo='prueba085' and activa),4,'Admin ve sus audiencias y su personal');
select is((select count(*)::int from public.alertas where clave_dedup='085-personal'),0,'Admin no ve personal ajena (CA-1)');
set local request.jwt.claims='{"sub":"08500000-0000-4000-8000-000000000004","role":"authenticated"}';
select is((select count(*)::int from public.alertas where tipo='prueba085' and activa),1,'otro Usuario solo ve todos');
reset role;
update public.perfiles set estado='suspendido' where id='08500000-0000-4000-8000-000000000001';
set local role authenticated;
set local request.jwt.claims='{"sub":"08500000-0000-4000-8000-000000000001","role":"authenticated","app_estado":"activo"}';
select is((select count(*)::int from public.alertas),0,'cuenta suspendida no recibe alertas');
reset role;

update public.lista_blanca set activo=true,negociable=true where simbolo='AAPL';
select * from private.sincronizar_activos('[{"simbolo":"AAPL","negociable":false,"fraccionable":true}]');
select is((select count(*)::int from public.alertas where clave_dedup='activo_no_negociable:AAPL' and activa and audiencia='administradores'),1,'CA-5: una alerta al desactivar símbolo, aunque esté en varios bolsillos');
select * from private.sincronizar_activos('[{"simbolo":"AAPL","negociable":false,"fraccionable":true}]');
select is((select count(*)::int from public.alertas where clave_dedup='activo_no_negociable:AAPL'),1,'sin repetir al sincronizar');
select * from private.sincronizar_activos('[{"simbolo":"AAPL","negociable":true,"fraccionable":true}]');
select ok(not exists(select 1 from public.alertas where clave_dedup='activo_no_negociable:AAPL' and activa),'resuelve cuando vuelve a negociable');
select ok(not exists(select 1 from public.lista_blanca where simbolo='AAPL' and activo),'no reactiva la lista blanca automáticamente');
select * from finish();
rollback;

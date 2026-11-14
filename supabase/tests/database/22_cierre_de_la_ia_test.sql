-- D-72 · Cierre de la IA del MVP: interruptor ia_activa en el ciclo y lanzar_ciclo().
-- Criterios: HU-046 CA-3 (con la IA apagada el ciclo se omite: el agente lo lee de
-- private.estado_del_agente) y CA-5 (solo el Administrador lanza un ciclo, PM-58).
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

-- Cuentas: 0001 usuario · 0002 analista · 0003 administrador.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista de prueba', 'analista'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador');

create function pg_temp.auditorias(p_accion text) returns int language sql as
  $$ select count(*)::int from public.auditoria where accion = p_accion $$;

-- Estructura y permisos --------------------------------------------------------------------------
select function_privs_are('public', 'lanzar_ciclo', array[]::text[], 'anon', array[]::text[],
  'anon no lanza ciclos');
select function_privs_are('public', 'lanzar_ciclo', array[]::text[], 'authenticated', array['EXECUTE'],
  'authenticated puede llamar lanzar_ciclo (la función decide por el rol)');
select is((select prosecdef from pg_proc where oid = 'public.lanzar_ciclo()'::regprocedure), true,
  'lanzar_ciclo es security definer');
select is((select proconfig from pg_proc where oid = 'public.lanzar_ciclo()'::regprocedure), array['search_path=""'],
  'lanzar_ciclo fija search_path vacío');
select function_privs_are('private', 'despertar_funcion', array['text', 'jsonb'], 'authenticated', array[]::text[],
  'authenticated no despierta funciones con cuerpo');

-- HU-046 CA-3: el agente lee el interruptor ------------------------------------------------------
update public.fondos set ia_activa = false;
select is((select ia_activa from private.estado_del_agente()), false,
  'con ia_activa apagado, estado_del_agente lo informa (el ciclo queda omitido)');
update public.fondos set ia_activa = true;
select is((select ia_activa from private.estado_del_agente()), true,
  'con ia_activa encendido, estado_del_agente lo informa');
select ok((select mercado_en_ventana is not null and ahora is not null from private.estado_del_agente()),
  'estado_del_agente sigue dando la hora y la ventana del mercado');

-- HU-046 CA-5 (PM-58): solo el Administrador lanza un ciclo --------------------------------------
create temp table antes as select count(*)::int as n from net.http_request_queue;
grant select on antes to authenticated;

set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select throws_ok($$select public.lanzar_ciclo()$$, 'P0001', 'NO_AUTORIZADO', 'CA-5 · un Usuario no lanza ciclos');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select throws_ok($$select public.lanzar_ciclo()$$, 'P0001', 'NO_AUTORIZADO', 'CA-5 · un Analista no lanza ciclos');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select lives_ok($$select public.lanzar_ciclo()$$, 'CA-5 · el Administrador lanza un ciclo');
reset role;
set local request.jwt.claims to '';

select is((select count(*)::int from net.http_request_queue) - (select n from antes), 1,
  'lanzar_ciclo despierta al agente una vez');
select is(pg_temp.auditorias('ciclo.lanzado'), 1, 'el lanzamiento queda en la bitácora');

select * from finish();
rollback;

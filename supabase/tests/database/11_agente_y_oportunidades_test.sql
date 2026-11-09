-- HU-044 a HU-048 · Corte de demo de IA (D-70): tablas del agente, ciclos y la RPC oportunidades().
-- Criterios: HU-046 CA-2 y CB-62 (un ciclo a la vez), HU-048 CA-1 y CA-2 (el Usuario solo ve Usuarios),
-- docs/03 §4.3 (las tablas del agente no son legibles para el Usuario), docs/06 §5.3 y §7.
begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

-- Cuentas: 0001 usuario · 0002 analista · 0003 administrador · 0004 suspendido (rol analista).
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario');
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista de prueba', 'analista', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test', 'Suspendido de prueba', 'analista', 'suspendido', now(), null);

-- Estructura y permisos ---------------------------------------------------------------------------
select ok((select relrowsecurity from pg_class where oid = 'public.ciclos_agente'::regclass), 'ciclos_agente tiene RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.evaluaciones_candidatos'::regclass), 'evaluaciones_candidatos tiene RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.configuraciones_decision'::regclass), 'configuraciones_decision tiene RLS');
select table_privs_are('public', 'evaluaciones_candidatos', 'authenticated', array['SELECT'], 'authenticated solo lee las evaluaciones');
select table_privs_are('public', 'evaluaciones_candidatos', 'anon', array[]::text[], 'anon no toca las evaluaciones');
select table_privs_are('public', 'ciclos_agente', 'service_role', array[]::text[], 'service_role no escribe los ciclos');
select is((select count(*)::int from public.configuraciones_decision where estado = 'activa'), 1, 'hay exactamente una configuración activa');
select is((select (pesos -> 'arriesgadas' ->> 'wQ')::numeric + (pesos -> 'arriesgadas' ->> 'wC')::numeric + (pesos -> 'arriesgadas' ->> 'wS')::numeric
                  + (pesos -> 'arriesgadas' ->> 'wT')::numeric + (pesos -> 'arriesgadas' ->> 'wV')::numeric
                  + (pesos -> 'arriesgadas' ->> 'wE')::numeric + (pesos -> 'arriesgadas' ->> 'wR')::numeric
            from public.configuraciones_decision where estado = 'activa'),
          1.00, 'los pesos de Arriesgadas suman 1');
select ok(exists (select 1 from cron.job where jobname = 'ciclo_agente'), 'el trabajo ciclo_agente está programado');

-- Un ciclo a la vez (HU-046 CA-2, CB-62) -----------------------------------------------------------
create temp table ciclo as select private.registrar_ciclo('programado') as id;
select isnt((select id from ciclo), null, 'registrar_ciclo abre un ciclo');
select is(private.registrar_ciclo('programado'), null, 'con un ciclo en curso no abre otro');
update public.ciclos_agente set iniciado_en = now() - interval '6 minutes' where id = (select id from ciclo);
create temp table ciclo2 as select private.registrar_ciclo('programado') as id;
select isnt((select id from ciclo2), null, 'un ciclo en curso de más de 5 minutos no bloquea');
select is((select estado::text from public.ciclos_agente where id = (select id from ciclo)), 'fallido', 'y el viejo queda fallido');

-- Evaluaciones y cierre ---------------------------------------------------------------------------
select is(private.registrar_evaluaciones((select id from ciclo2), 1, '[
  {"bolsillo":"arriesgadas","simbolo":"NVDA","calidad_datos":"ok","resultado":"elegida","puntaje_compuesto":0.78,"confianza":0.81,"explicacion":{"que":"x"}},
  {"bolsillo":"usuarios","simbolo":"QQQ","calidad_datos":"ok","resultado":"no_elegible:espera","puntaje_compuesto":0.55,"confianza":0.7,"explicacion":{"que":"y"}}
]'::jsonb), 2, 'registrar_evaluaciones guarda las filas');
select private.cerrar_ciclo((select id from ciclo2), 'completado', 1, 'jev-1.13.0', 2, 0, 100, 50, null, null);
select is((select estado::text from public.ciclos_agente where id = (select id from ciclo2)), 'completado', 'cerrar_ciclo deja el ciclo completado');
select throws_ok($$select private.cerrar_ciclo(gen_random_uuid(), 'completado', 1, null, 0, 0, 0, 0, null, null)$$, 'P0002',
                 'cerrar_ciclo: el ciclo no existe o ya está cerrado', 'no se cierra un ciclo que no existe');

-- oportunidades() por rol (HU-048 CA-1 y CA-2) ----------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select count(*)::int from public.oportunidades()), 1, 'el Usuario recibe solo el bolsillo de Usuarios');
select is((select count(*)::int from public.oportunidades('arriesgadas')), 0, 'el Usuario que pide Arriesgadas no recibe candidatas');
select is((select count(*)::int from public.evaluaciones_candidatos), 0, 'el Usuario no lee la tabla de evaluaciones');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is((select count(*)::int from public.oportunidades()), 2, 'el Analista recibe todos los bolsillos');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is((select simbolo from public.oportunidades('arriesgadas')), 'NVDA', 'el Administrador filtra por bolsillo');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated", "app_rol": "analista", "app_estado": "activo"}';
select is((select count(*)::int from public.oportunidades()), 0, 'una cuenta suspendida no recibe nada, aunque el token diga analista');

set local request.jwt.claims to '';
reset role;

select * from finish();
rollback;

-- HU-109 · Aislamiento por función: cada RPC que llama la app rechaza al rol equivocado, a la
-- cuenta no activa y, donde hay un dueño, al dueño equivocado.
-- Criterios: CA-2 (backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-109-*.md).
-- Reglas: docs/03 §4.4 (rol y dueño antes de escribir), docs/06 §9 (códigos), docs/11 §9, docs/14 §6.
--
-- La tabla temporal `rpcs` lista cada función de public que puede ejecutar authenticated, con una
-- llamada válida y los roles que la pueden usar. Con cada rol que no está en la lista, la llamada
-- debe fallar con NO_AUTORIZADO; con una cuenta suspendida o sin perfil, con NO_AUTORIZADO o
-- SESION_INVALIDA (algunas miran la sesión antes que el rol). Las lecturas abiertas a todos
-- (oportunidades, resumen_fondo) no lanzan error: a la cuenta no activa no le devuelven filas.
--
-- Cada historia que crea una RPC agrega su fila a `rpcs` (docs/14 §6): si falta, el registro falla.
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- Personas (las mismas de 29_aislamiento_lectura_por_tabla) ---------------------------------------
create temp table personas (persona text primary key, id uuid, rol text);
insert into personas values
  ('usuario_a',     '10900000-0000-4000-8000-000000000001', 'usuario'),
  ('usuario_b',     '10900000-0000-4000-8000-000000000002', 'usuario'),
  ('analista',      '10900000-0000-4000-8000-000000000003', 'analista'),
  ('administrador', '10900000-0000-4000-8000-000000000004', 'administrador'),
  ('suspendido',    '10900000-0000-4000-8000-000000000005', 'usuario'),
  ('sin_perfil',    '10900000-0000-4000-8000-000000000009', null);

set local session_replication_role = replica;
insert into auth.users (id, email)
  select id, 'aislamiento-' || persona || '@prueba.test' from personas;
set local session_replication_role = origin;

insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en)
  select id, 'aislamiento-' || persona || '@prueba.test', 'Aislamiento ' || persona, rol::public.rol_app,
         case when persona = 'suspendido' then 'suspendido' else 'activo' end::public.estado_cuenta,
         case when persona = 'suspendido' then now() end
    from personas where rol is not null;

-- Cupos con saldo y una orden aceptada en el cupo de A (para el dueño equivocado).
create temp table fx (clave text primary key, id uuid);
insert into fx
  select 'cupo_' || p.persona, private.crear_cupo(p.id, 0)
    from personas p where p.persona in ('usuario_a', 'usuario_b', 'suspendido');
select private.registrar_movimiento('aporte', jsonb_build_array(
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'externa'), 'concepto', 'efectivo', 'monto', -2000),
  jsonb_build_object('subcuenta_id', (select id from fx where clave = 'cupo_usuario_a'), 'concepto', 'efectivo', 'monto', 1000),
  jsonb_build_object('subcuenta_id', (select id from fx where clave = 'cupo_usuario_b'), 'concepto', 'efectivo', 'monto', 1000)),
  null, 'HU-109 · saldo de los cupos');
insert into fx values ('orden_usuario_a', '10900000-0000-4000-8000-000000000101');
insert into public.ordenes (id, origen, subcuenta_id, simbolo, lado, clase, tipo, tif, cantidad, precio_limite, retencion, parametros, estado, broker_order_id, enviada_en)
  values ((select id from fx where clave = 'orden_usuario_a'), 'manual', (select id from fx where clave = 'cupo_usuario_a'),
          'AAPL', 'compra', 'simple', 'limite', 'day', 2, 50, 100, '{}', 'aceptada', 'broker-hu109', private.ahora());
update public.subcuentas set retenido = 100 where id = (select id from fx where clave = 'cupo_usuario_a');

-- Un ciclo completado, el más reciente, con una oportunidad en cada bolsillo.
with ciclo as (
  insert into public.ciclos_agente (disparador, estado, iniciado_en, terminado_en)
  values ('manual', 'completado', '2999-01-01 00:00Z', '2999-01-01 00:01Z') returning id)
insert into public.evaluaciones_candidatos (ciclo_id, configuracion_version, bolsillo, simbolo, tipo, calidad_datos, resultado)
  select ciclo.id, 1, b::public.bolsillo, 'AAPL', 'entrada', 'ok', 'elegida'
    from ciclo cross join unnest(array['reserva', 'arriesgadas', 'usuarios']) b;

-- Matriz de funciones --------------------------------------------------------------------------
-- :A y :B son los Usuarios; :ORDEN_A, la orden de A. Las llamadas son válidas para quien sí puede.
create temp table rpcs (funcion text primary key, llamada text, permitidos text[], lectura boolean default false);
insert into rpcs (funcion, llamada, permitidos) values
  ('activar_freno',        $$select public.activar_freno('ia_activa', 'HU-109')$$,                             array['analista', 'administrador']),
  ('actualizar_parametro', $$select public.actualizar_parametro('reparto.pct_reserva', '50'::jsonb, 'HU-109')$$, array['administrador']),
  ('anular_aporte',        $$select public.anular_aporte(gen_random_uuid(), 'HU-109')$$,                       array['administrador']),
  ('asignar_cupo',         $$select public.asignar_cupo(:B, 10)$$,                                             array['administrador']),
  ('cambiar_rol',          $$select public.cambiar_rol(:B, 'analista')$$,                                      array['administrador']),
  ('cancelar_orden',       $$select public.cancelar_orden(:ORDEN_A)$$,                                         array['usuario']),
  ('crear_orden_manual',   $$select public.crear_orden_manual(gen_random_uuid(), 'AAPL', 'compra', 1, null, null)$$, array['usuario']),
  ('estado_mercado',       $$select public.estado_mercado()$$,                                                 array['usuario', 'analista', 'administrador']),
  ('invitar_usuario',      $$select public.invitar_usuario('hu109-invitada@prueba.test', 'usuario', 0)$$,      array['administrador']),
  ('lanzar_ciclo',         $$select public.lanzar_ciclo()$$,                                                   array['administrador']),
  ('mi_cupo',              $$select public.mi_cupo()$$,                                                        array['usuario']),
  ('reanudar',             $$select public.reanudar('ia_activa')$$,                                            array['administrador']),
  ('reducir_cupo',         $$select public.reducir_cupo(:A, 10)$$,                                             array['administrador']),
  ('registrar_aporte',     $$select public.registrar_aporte(100, 'HU-109', null)$$,                            array['administrador']),
  ('revocar_invitacion',   $$select public.revocar_invitacion(gen_random_uuid())$$,                            array['administrador']);
insert into rpcs (funcion, llamada, permitidos, lectura) values
  ('oportunidades',        $$select count(*) from public.oportunidades()$$,                                    array['usuario', 'analista', 'administrador'], true),
  ('resumen_fondo',        $$select count(*) from public.resumen_fondo()$$,                                    array['usuario', 'analista', 'administrador'], true);

update rpcs set llamada = replace(replace(replace(llamada,
  ':ORDEN_A', quote_literal((select id from fx where clave = 'orden_usuario_a')) || '::uuid'),
  ':A', quote_literal('10900000-0000-4000-8000-000000000001') || '::uuid'),
  ':B', quote_literal('10900000-0000-4000-8000-000000000002') || '::uuid');

-- Ejecuta una llamada y devuelve el mensaje con que falla ('sin error' si no falla). El
-- subbloque deshace lo que la llamada alcanzó a escribir.
create function pg_temp.error_de(p_sql text) returns text
language plpgsql as $$
begin
  execute p_sql;
  return 'sin error';
exception when others then
  return sqlerrm;
end $$;
-- Ejecuta una lectura que devuelve un conteo.
create function pg_temp.filas_de(p_sql text) returns bigint
language plpgsql as $$
declare v_n bigint;
begin
  execute p_sql into v_n;
  return v_n;
end $$;
grant select on rpcs, personas, fx to authenticated;
grant execute on function pg_temp.error_de(text), pg_temp.filas_de(text) to authenticated;

-- Registro: cada función de public que ejecuta authenticated tiene su caso (14 §6) ----------------
select is(
  array(select p.proname::text from pg_proc p
         where p.pronamespace = 'public'::regnamespace
           and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')
           and has_function_privilege('authenticated', p.oid, 'EXECUTE')
         order by 1),
  array(select funcion from rpcs order by 1),
  'cada función de public que puede llamar authenticated tiene su caso (una nueva sin caso hace fallar la suite)');
select ok(not has_function_privilege('authenticated', 'public.ping()', 'EXECUTE'), 'ping() no es para authenticated, solo para anon');

-- Rol equivocado: NO_AUTORIZADO (CA-2) ---------------------------------------------------------------
set local role authenticated;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is(pg_temp.error_de(llamada), 'NO_AUTORIZADO', format('%s rechaza a un Usuario', funcion))
  from rpcs where not lectura and not 'usuario' = any(permitidos) order by funcion;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is(pg_temp.error_de(llamada), 'NO_AUTORIZADO', format('%s rechaza a un Analista', funcion))
  from rpcs where not lectura and not 'analista' = any(permitidos) order by funcion;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000004", "role": "authenticated"}';
select is(pg_temp.error_de(llamada), 'NO_AUTORIZADO', format('%s rechaza a un Administrador', funcion))
  from rpcs where not lectura and not 'administrador' = any(permitidos) order by funcion;

-- Cuenta no activa: rechazada aunque su token diga administrador y activo (03 §4.1) --------------
set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000005", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select ok(r in ('NO_AUTORIZADO', 'SESION_INVALIDA'), format('%s rechaza a una cuenta suspendida (%s)', funcion, r))
  from (select funcion, pg_temp.error_de(llamada) r from rpcs where not lectura order by funcion) x;
select is(pg_temp.filas_de(llamada), 0::bigint, format('%s no le devuelve filas a una cuenta suspendida', funcion))
  from rpcs where lectura order by funcion;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000009", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select ok(r in ('NO_AUTORIZADO', 'SESION_INVALIDA'), format('%s rechaza a una sesión sin perfil (%s)', funcion, r))
  from (select funcion, pg_temp.error_de(llamada) r from rpcs where not lectura order by funcion) x;
select is(pg_temp.filas_de(llamada), 0::bigint, format('%s no le devuelve filas a una sesión sin perfil', funcion))
  from rpcs where lectura order by funcion;

-- Dueño equivocado (CA-2) ------------------------------------------------------------------------------
-- cancelar_orden recibe la orden: la de otro Usuario se rechaza.
set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is(pg_temp.error_de((select llamada from rpcs where funcion = 'cancelar_orden')), 'NO_AUTORIZADO',
          'cancelar_orden rechaza la orden de otro Usuario');

-- mi_cupo y crear_orden_manual no reciben dueño: usan el de la sesión y solo tocan el cupo propio.
select is((select array_agg(subcuenta_id) from public.mi_cupo()), array[(select id from fx where clave = 'cupo_usuario_b')],
          'mi_cupo le devuelve a B solo su cupo');
set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select array_agg(subcuenta_id) from public.mi_cupo()), array[(select id from fx where clave = 'cupo_usuario_a')],
          'mi_cupo le devuelve a A solo su cupo');
-- Puede fallar por el horario o el motor de políticas; lo que importa es dónde cae si se crea.
select isnt(pg_temp.error_de((select llamada from rpcs where funcion = 'crear_orden_manual')), 'NO_AUTORIZADO',
            'crear_orden_manual no rechaza por rol al Usuario dueño de su cupo');
reset role;
select is((select count(*)::int from public.ordenes where subcuenta_id <> (select id from fx where clave = 'cupo_usuario_a')
             and subcuenta_id in (select id from fx where clave like 'cupo_%')),
          0, 'la orden manual de A no cae en el cupo de otro Usuario');

-- Lecturas abiertas a todos: el Usuario solo ve el bolsillo usuarios en oportunidades -------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select array_agg(distinct bolsillo::text) from public.oportunidades()), array['usuarios'],
          'oportunidades le muestra a un Usuario solo el bolsillo usuarios');
select is((select count(*)::int from public.resumen_fondo()), 3, 'resumen_fondo le muestra a un Usuario los tres bolsillos agregados');
set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is((select array_agg(distinct bolsillo::text order by bolsillo::text) from public.oportunidades()),
          array['arriesgadas', 'reserva', 'usuarios'], 'oportunidades le muestra a un Analista los tres bolsillos');
reset role;

-- Nada de lo rechazado cambió el estado --------------------------------------------------------------
select is((select rol::text from public.perfiles where id = '10900000-0000-4000-8000-000000000002'), 'usuario',
          'B sigue siendo Usuario: nadie sin permiso le cambió el rol');
select is((select estado::text from public.ordenes where id = (select id from fx where clave = 'orden_usuario_a')), 'aceptada',
          'la orden de A sigue aceptada: nadie más la canceló');
select is((select count(*)::int from public.invitaciones where email = 'hu109-invitada@prueba.test'), 0,
          'nadie sin permiso creó la invitación');

select * from finish();
rollback;

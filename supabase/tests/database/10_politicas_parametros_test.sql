-- HU-033 · Parámetros configurables con rango e historial.
-- Criterios: CA-1 a CA-5 (backlog/E-05-motor-de-politicas-y-configuracion/HU-033-*.md). Casos borde:
-- CB-75 y CB-78. Reglas: PM-54, PM-06, RN-02, docs/02 §10, docs/06 §5.6.
begin;
create extension if not exists pgtap with schema extensions;
select plan(65);

-- Cuentas de prueba: 0001 usuario · 0002 analista · 0003 administrador · 0004 suspendido (rol administrador).
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
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test', 'Suspendido de prueba', 'administrador', 'suspendido', now(), null);

-- Catálogo (02 §10) ------------------------------------------------------------------------------
select is((select count(*)::int from public.parametros), 52, 'el catálogo trae las 50 claves de 02 §10 más las dos de auth');
select is((select (valor, tipo, minimo, maximo)::text from public.parametros where clave = 'sugerencias.minutos_vencimiento'),
          '(30,numero,5,240)', 'sugerencias.minutos_vencimiento: 30, rango 5 a 240');
select is((select array_agg(valor order by clave) from public.parametros where clave like 'reparto.pct_%'),
          array['25'::jsonb, '50', '25'], 'reparto 50/25/25');
select is((select count(*)::int from public.parametros where descripcion is null or btrim(descripcion) = ''), 0,
          'todas tienen descripción');
select is((select (valor, minimo)::text from public.parametros where clave = 'cupos.maximo_usd'), '(null,0)',
          'cupos.maximo_usd: sin límite (null) y mínimo 0');

-- Estructura y permisos ---------------------------------------------------------------------------
select ok((select relrowsecurity from pg_class where oid = 'public.parametros_historial'::regclass), 'parametros_historial tiene RLS');
select table_privs_are('public', 'parametros_historial', 'authenticated', array['SELECT'], 'authenticated solo lee el historial');
select table_privs_are('public', 'parametros_historial', 'anon', array[]::text[], 'anon no toca el historial');
select table_privs_are('public', 'parametros_historial', 'service_role', array[]::text[], 'service_role no escribe el historial');
select table_privs_are('public', 'parametros', 'authenticated', array['SELECT'], 'authenticated solo lee parametros');
select ok(not has_table_privilege('service_role', 'public.parametros', 'insert')
          and not has_table_privilege('service_role', 'public.parametros', 'update')
          and not has_table_privilege('service_role', 'public.parametros', 'delete'),
          'service_role no escribe parametros');
select ok(has_function_privilege('authenticated', 'public.actualizar_parametro(text, jsonb, text)', 'execute')
          and not has_function_privilege('anon', 'public.actualizar_parametro(text, jsonb, text)', 'execute'),
          'actualizar_parametro: authenticated sí, anon no');
select ok(not has_function_privilege('authenticated', 'private.aplicar_parametro(text, jsonb, text, uuid)', 'execute')
          and not has_function_privilege('authenticated', 'private.validar_valor_parametro(text, jsonb, text, numeric, numeric)', 'execute'),
          'las funciones private no las ejecuta la API');
select ok((select bool_and(prosecdef and proconfig = array['search_path=""']) from pg_proc
            where oid in ('public.actualizar_parametro(text, jsonb, text)'::regprocedure,
                          'private.aplicar_parametro(text, jsonb, text, uuid)'::regprocedure,
                          'private.validar_valor_parametro(text, jsonb, text, numeric, numeric)'::regprocedure)),
          'security definer con search_path vacío');

-- CA-5: permisos ------------------------------------------------------------------------------------
set local role authenticated;

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select throws_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '45', 'prueba')$$, 'P0001',
                 'NO_AUTORIZADO', 'CA-5: un Usuario recibe NO_AUTORIZADO');
select is((select count(*)::int from public.parametros), 52, 'CA-5: el Usuario lee los parámetros vigentes');
select is((select count(*)::int from public.parametros_historial), 0, 'CA-5: el Usuario no recibe filas del historial');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select throws_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '45', 'prueba')$$, 'P0001',
                 'NO_AUTORIZADO', 'CA-5: un Analista recibe NO_AUTORIZADO');
select is((select count(*)::int from public.parametros), 52, 'CA-5: el Analista lee los parámetros vigentes');
select is((select count(*)::int from public.parametros_historial), 0, 'CA-5: el Analista no recibe filas del historial');

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select throws_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '45', 'prueba')$$, 'P0001',
                 'NO_AUTORIZADO', 'un Administrador suspendido con token vigente recibe NO_AUTORIZADO');
select is((select count(*)::int from public.parametros), 0, 'y una cuenta suspendida no lee parámetros');

set local request.jwt.claims to '';
select throws_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '45', 'prueba')$$, 'P0001',
                 'NO_AUTORIZADO', 'sin identidad tampoco');
reset role;

-- CA-1: el Administrador cambia un parámetro -----------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select lives_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '45', 'Más tiempo para decidir')$$,
                'CA-1: el Administrador cambia sugerencias.minutos_vencimiento de 30 a 45');
select is((select (valor, version, actualizado_por)::text from public.parametros where clave = 'sugerencias.minutos_vencimiento'),
          '(45,2,00000000-0000-4000-8000-000000000003)', 'CA-1: el valor rige, sube la versión y queda quién lo cambió');
select is((select (clave, valor_anterior, valor_nuevo, cambiado_por, motivo)::text from public.parametros_historial),
          '(sugerencias.minutos_vencimiento,30,45,00000000-0000-4000-8000-000000000003,"Más tiempo para decidir")',
          'CA-1: el historial guarda el anterior, el nuevo, quién y el motivo');
select is((select count(*)::int from public.parametros_historial), 1, 'el Administrador lee el historial');
reset role;
select is((select (accion, entidad, entidad_id, actor_id, antes, despues, detalle)::text from public.auditoria
            where accion = 'parametro.cambiado'),
          '(parametro.cambiado,parametros,sugerencias.minutos_vencimiento,00000000-0000-4000-8000-000000000003,30,45,"{""motivo"": ""Más tiempo para decidir""}")',
          'CA-1: se registra parametro.cambiado con valor anterior y nuevo');
select is((select payload from realtime.messages where event = 'parametro' and topic = 'admin' and private),
          '{"tabla": "parametros", "id": "sugerencias.minutos_vencimiento", "version": 2, "estado": "cambiado"}'::jsonb,
          'se publica parametro en admin con clave y versión, sin el valor');

-- Motivo, clave y tipo -----------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '50', '  ')$$, '22023', null, 'un motivo en blanco se rechaza');
select throws_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '50', null)$$, '22023', null, 'un motivo nulo se rechaza');
select throws_ok($$select public.actualizar_parametro('no.existe', '1', 'x')$$, 'P0001', 'NO_EXISTE', 'una clave que no existe responde NO_EXISTE');
select throws_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '"45"', 'x')$$, 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'un texto en un número se rechaza');
select throws_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', 'null', 'x')$$, 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'null en un número con tope se rechaza');
select throws_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', null, 'x')$$, 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'y un valor SQL nulo también');

-- CA-2: rango ----------------------------------------------------------------------------------------
select throws_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '4', 'x')$$, 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'CA-2: por debajo del mínimo');
select throws_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '241', 'x')$$, 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'CA-2: por encima del máximo');
select lives_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '5', 'borde inferior')$$, 'el mínimo se acepta');
select lives_ok($$select public.actualizar_parametro('sugerencias.minutos_vencimiento', '240', 'borde superior')$$, 'el máximo se acepta');
select lives_ok($$select public.actualizar_parametro('sugerencias.banda_precio_pct', '0.2', 'decimal')$$, 'un decimal en su rango se acepta');
select throws_ok($$select public.actualizar_parametro('aprobacion.umbral_doble_usd', '-1', 'x')$$, 'P0001', 'PARAMETRO_FUERA_DE_RANGO', '"≥ 0" rechaza un negativo');
select lives_ok($$select public.actualizar_parametro('aprobacion.umbral_doble_usd', '1000000', 'sin tope superior')$$, 'y no tiene tope superior');
select lives_ok($$select public.actualizar_parametro('cupos.maximo_usd', '5000', 'poner un tope')$$, 'cupos.maximo_usd acepta un número');
select lives_ok($$select public.actualizar_parametro('cupos.maximo_usd', 'null', 'volver a sin límite')$$, 'y null (sin límite)');
select throws_ok($$select public.actualizar_parametro('ia.horizonte.usuarios', '"meses"', 'x')$$, 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'un horizonte fuera de la lista se rechaza');
select lives_ok($$select public.actualizar_parametro('ia.horizonte.usuarios', '"días"', 'x')$$, 'un horizonte de la lista se acepta');
select throws_ok($$select public.actualizar_parametro('auth.dominios_permitidos', '"gmail.com"', 'x')$$, 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'una lista debe ser un arreglo de textos');
reset role;
select is((select valor from public.parametros where clave = 'sugerencias.minutos_vencimiento'), '240'::jsonb,
          'un rechazo no cambia el valor ni deja historial');

-- CA-3 y CB-78: reparto -------------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.actualizar_parametro('reparto', '{"pct_reserva": 60, "pct_arriesgadas": 25, "pct_usuarios": 25}', 'x')$$,
                 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'CA-3: porcentajes que suman 110 se rechazan');
select throws_ok($$select public.actualizar_parametro('reparto', '{"pct_reserva": 40, "pct_arriesgadas": 25, "pct_usuarios": 25}', 'x')$$,
                 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'CA-3: porcentajes que suman 90 se rechazan');
select throws_ok($$select public.actualizar_parametro('reparto.pct_reserva', '60', 'x')$$,
                 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'CA-3: cambiar uno solo se rechaza');
select throws_ok($$select public.actualizar_parametro('reparto', '{"pct_reserva": 100, "pct_arriesgadas": 25}', 'x')$$,
                 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'CA-3: faltan claves');
select throws_ok($$select public.actualizar_parametro('reparto', '{"pct_reserva": 110, "pct_arriesgadas": -5, "pct_usuarios": -5}', 'x')$$,
                 'P0001', 'PARAMETRO_FUERA_DE_RANGO', 'CA-3: suman 100 pero salen de 0 a 100');
reset role;
select is((select array_agg(valor order by clave) from public.parametros where clave like 'reparto.pct_%'),
          array['25'::jsonb, '50', '25'], 'CA-3: los rechazos dejan el reparto como estaba');

-- CA-4 y CB-75: un reparto válido -------------------------------------------------------------------
create temp table antes_reparto on commit drop as
  select (select count(*) from public.perfiles) as perfiles, (select count(*) from public.auditoria) as bitacora;
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select lives_ok($$select public.actualizar_parametro('reparto', '{"pct_reserva": 40, "pct_arriesgadas": 30, "pct_usuarios": 30}', 'Más a Arriesgadas y Usuarios')$$,
                'CA-4: un reparto 40/30/30 se guarda');
reset role;
select is((select array_agg(valor order by clave) from public.parametros where clave like 'reparto.pct_%'),
          array['30'::jsonb, '40', '30'], 'rige el nuevo reparto');
select is((select count(*)::int from public.parametros_historial where clave like 'reparto.pct_%'), 3, 'una fila de historial por porcentaje');
select is((select count(*)::int from public.auditoria where accion = 'parametro.cambiado' and entidad_id = 'reparto'), 1,
          'y una sola entrada de bitácora para la operación');
select is((select (antes, despues)::text from public.auditoria where entidad_id = 'reparto'),
          '("{""pct_reserva"": 50, ""pct_usuarios"": 25, ""pct_arriesgadas"": 25}","{""pct_reserva"": 40, ""pct_usuarios"": 30, ""pct_arriesgadas"": 30}")',
          'con el reparto anterior y el nuevo');
select is((select count(*)::int from realtime.messages where event = 'parametro' and payload ->> 'id' like 'reparto.pct\_%'), 3,
          'y un evento por porcentaje, sin valores');
select ok(not exists (select 1 from pg_proc p where p.oid in ('public.actualizar_parametro(text, jsonb, text)'::regprocedure,
                                                                 'private.aplicar_parametro(text, jsonb, text, uuid)'::regprocedure)
                       and (p.prosrc ilike '%registrar_movimiento%' or p.prosrc ilike '%movimientos%' or p.prosrc ilike '%saldo%')),
          'CB-75: cambiar el reparto no llama al libro ni toca saldos (solo afecta aportes y repartos futuros)');

-- margenes_de_compra lee parametros (HU-027 -> HU-033) -------------------------------------------------
select is((select (tras_apertura, antes_cierre)::text from private.margenes_de_compra()), '(5,15)', 'los márgenes parten en 5 y 15 minutos');
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select lives_ok($$select public.actualizar_parametro('mercado.minutos_tras_apertura', '10', 'ventana más ancha')$$, 'se cambia el margen de apertura');
select lives_ok($$select public.actualizar_parametro('mercado.minutos_antes_cierre', '20', 'ventana más ancha')$$, 'y el de cierre');
reset role;
select is((select (tras_apertura, antes_cierre)::text from private.margenes_de_compra()), '(10,20)', 'margenes_de_compra devuelve lo configurado');

select * from finish();
rollback;

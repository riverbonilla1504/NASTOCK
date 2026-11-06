-- HU-027 · Calendario, reloj y estado del mercado.
-- Cubre CA-1 a CA-7 de backlog/E-04-datos-de-mercado/HU-027-*.md en la capa de base de datos:
-- la tabla calendario_mercado (RLS, permisos y lectura por cuenta activa con private.rol_actual()),
-- las funciones de horario con el reloj fijado (día regular, feriado, media jornada, cambios de
-- horario de verano, ventana y ventana de compras), el estado del mercado, la sincronización del calendario y de los atributos de los activos,
-- y el trabajo diario `calendario` de pg_cron.
-- Todo corre dentro de una transacción que se deshace.
begin;
create extension if not exists pgtap with schema extensions;
select plan(154);

-- Cuentas de prueba (HU-001: perfiles y private.rol_actual()) ----------------------------------
-- 0001 usuario · 0002 analista · 0003 administrador · 0004 suspendido · 0005 de baja.
-- 0009 tiene sesión pero ninguna fila en perfiles.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test'),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista de prueba', 'analista', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test', 'Suspendido de prueba', 'usuario', 'suspendido', now(), null),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test', 'De baja de prueba', 'usuario', 'baja', null, now());

-- Ayudas: fijan el reloj (pruebas.fijar_reloj, docs/15 §3) y consultan el horario.
create function pg_temp.abierto_a(p_hora timestamptz) returns boolean language plpgsql as $$
begin
  perform pruebas.fijar_reloj(p_hora);
  return private.mercado_abierto();
end;
$$;
create function pg_temp.ventana_a(p_hora timestamptz, p_margen interval) returns boolean language plpgsql as $$
begin
  perform pruebas.fijar_reloj(p_hora);
  return private.mercado_en_ventana(p_margen);
end;
$$;

-- Tabla ----------------------------------------------------------------------------------------
select has_table('public', 'calendario_mercado', 'existe calendario_mercado');
select col_is_pk('public', 'calendario_mercado', 'fecha', 'calendario_mercado: llave fecha');
select col_type_is('public', 'calendario_mercado', 'apertura', 'timestamp with time zone', 'la apertura es timestamptz (UTC)');
select col_type_is('public', 'calendario_mercado', 'cierre', 'timestamp with time zone', 'el cierre es timestamptz (UTC)');
select is(
  (select count(*)::int from public.calendario_mercado), 0,
  'ninguna migración ni la semilla programan el calendario a mano (RN-41)');

-- RLS y permisos -------------------------------------------------------------------------------
select is((select relrowsecurity from pg_class where oid = 'public.calendario_mercado'::regclass), true,
          'calendario_mercado tiene RLS activo');
select policies_are('public', 'calendario_mercado', array['calendario_mercado_lectura'],
                    'calendario_mercado solo tiene su política de lectura');
select is(
  (select count(*)::int from information_schema.role_table_grants
    where grantee = 'anon' and table_schema = 'public' and table_name = 'calendario_mercado'),
  0, 'anon no tiene permisos sobre calendario_mercado');
select is(
  (select array_agg(distinct privilege_type::text)
     from information_schema.role_table_grants
    where grantee = 'authenticated' and table_schema = 'public' and table_name = 'calendario_mercado'),
  array['SELECT'::text], 'authenticated solo tiene SELECT');

-- Datos: lo que enviaría el broker, con las horas ya en UTC -------------------------------------
-- 2026-03-06 (viernes, antes del cambio) · 2026-03-09 (lunes, después) · 2026-10-30 (viernes, antes
-- del cambio de noviembre) · 2026-11-02 (lunes, después) · 2026-11-05 (jueves, regular) ·
-- 2026-11-26 (Acción de Gracias: sin fila) · 2026-11-27 (media jornada).
select is(
  (select guardados from private.sincronizar_calendario('2026-03-02', '2026-12-31', $json$[
     {"fecha":"2026-03-06","apertura":"2026-03-06T14:30:00Z","cierre":"2026-03-06T21:00:00Z","sesion":"regular"},
     {"fecha":"2026-03-09","apertura":"2026-03-09T13:30:00Z","cierre":"2026-03-09T20:00:00Z","sesion":"regular"},
     {"fecha":"2026-10-30","apertura":"2026-10-30T13:30:00Z","cierre":"2026-10-30T20:00:00Z","sesion":"regular"},
     {"fecha":"2026-11-02","apertura":"2026-11-02T14:30:00Z","cierre":"2026-11-02T21:00:00Z","sesion":"regular"},
     {"fecha":"2026-11-05","apertura":"2026-11-05T14:30:00Z","cierre":"2026-11-05T21:00:00Z","sesion":"regular"},
     {"fecha":"2026-11-27","apertura":"2026-11-27T14:30:00Z","cierre":"2026-11-27T18:00:00Z","sesion":"media_jornada"}
   ]$json$::jsonb)),
  6, 'CA-6: la primera sincronización guarda los seis días');
select is((select count(*)::int from public.calendario_mercado), 6, 'quedaron seis días en calendario_mercado');
select is(
  (select sesion from public.calendario_mercado where fecha = '2026-11-27'), 'media_jornada',
  'la media jornada queda marcada');

-- Lectura por cuenta (RLS) ---------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select count(*)::int from public.calendario_mercado), 6, 'un usuario activo lee el calendario');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is((select count(*)::int from public.calendario_mercado), 6, 'un analista activo lee el calendario');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is((select count(*)::int from public.calendario_mercado), 6, 'un administrador activo lee el calendario');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is((select count(*)::int from public.calendario_mercado), 0, 'una cuenta suspendida no lo ve, aunque el token diga lo contrario');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000005", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is((select count(*)::int from public.calendario_mercado), 0, 'una cuenta de baja no lo ve, aunque el token diga lo contrario');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000009", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is((select count(*)::int from public.calendario_mercado), 0, 'una cuenta sin perfil no lo ve, aunque el token diga lo contrario');
set local request.jwt.claims to '';
select is((select count(*)::int from public.calendario_mercado), 0, 'sin sesión no se ve el calendario');
-- Ni siquiera un administrador activo escribe directo
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$insert into public.calendario_mercado values ('2026-12-01', now(), now() + interval '1 hour', 'regular')$$,
                 '42501', null, 'authenticated no puede insertar en calendario_mercado');
select throws_ok($$update public.calendario_mercado set sesion = 'regular'$$,
                 '42501', null, 'authenticated no puede actualizar calendario_mercado');
select throws_ok($$delete from public.calendario_mercado$$,
                 '42501', null, 'authenticated no puede borrar de calendario_mercado');
reset role;
set local role anon;
select throws_ok($$select * from public.calendario_mercado$$, '42501', null, 'anon no puede leer calendario_mercado');
reset role;

-- private.mercado_abierto(): día regular (jueves 2026-11-05, 9:30–16:00 NY = 14:30–21:00 UTC) ----
select is(pg_temp.abierto_a('2026-11-05T14:29:59Z'), false, 'un segundo antes de la apertura está cerrado');
select is(pg_temp.abierto_a('2026-11-05T14:30:00Z'), true, 'a la apertura está abierto');
select is(pg_temp.abierto_a('2026-11-05T20:59:59Z'), true, 'un segundo antes del cierre está abierto');
select is(pg_temp.abierto_a('2026-11-05T21:00:00Z'), false, 'al cierre está cerrado');
select is(pg_temp.abierto_a('2026-11-06T15:00:00Z'), false, 'un día sin fila (viernes sin sincronizar) está cerrado');
select is(pg_temp.abierto_a('2026-11-07T15:00:00Z'), false, 'un sábado está cerrado');

-- CA-2 (CB-49): feriado — Acción de Gracias, 2026-11-26, sin fila: cerrado todo el día --------------
select is(pg_temp.abierto_a('2026-11-26T14:30:00Z'), false, 'CA-2: el feriado a la hora normal de apertura está cerrado');
select is(pg_temp.abierto_a('2026-11-26T17:00:00Z'), false, 'CA-2: el feriado a mediodía está cerrado');
select is(pg_temp.abierto_a('2026-11-26T20:59:00Z'), false, 'CA-2: el feriado antes del cierre normal está cerrado');
select is(pg_temp.ventana_a('2026-11-26T14:25:00Z', interval '10 minutes'), false,
          'CA-2: el feriado tampoco abre la ventana de la ingesta');

-- CA-3 (CB-50): media jornada — 2026-11-27 cierra a las 13:00 NY = 18:00 UTC -------------------------
select is(pg_temp.abierto_a('2026-11-27T14:30:00Z'), true, 'CA-3: la media jornada abre a la hora normal');
select is(pg_temp.abierto_a('2026-11-27T17:59:59Z'), true, 'CA-3: un segundo antes de las 13:00 está abierto');
select is(pg_temp.abierto_a('2026-11-27T18:00:00Z'), false, 'CA-3: a las 13:00 de Nueva York está cerrado');
select is(pg_temp.abierto_a('2026-11-27T20:00:00Z'), false, 'CA-3: a la hora del cierre normal ya estaba cerrado');

-- CA-4 (CB-51): cambio de horario de verano — las horas guardadas en UTC siguen correctas -------------
-- Marzo: hasta el 8 NY está en UTC−5 (abre 14:30 UTC); desde el 9 en UTC−4 (abre 13:30 UTC).
select is(pg_temp.abierto_a('2026-03-06T13:30:00Z'), false, 'CA-4: antes del cambio de marzo, 13:30 UTC todavía no abrió');
select is(pg_temp.abierto_a('2026-03-06T14:30:00Z'), true, 'CA-4: antes del cambio de marzo, abre a las 14:30 UTC');
select is(pg_temp.abierto_a('2026-03-09T13:30:00Z'), true, 'CA-4: después del cambio de marzo, abre a las 13:30 UTC');
select is(pg_temp.abierto_a('2026-03-09T20:00:00Z'), false, 'CA-4: después del cambio de marzo, cierra a las 20:00 UTC');
-- Noviembre: hasta el 1 NY está en UTC−4 (abre 13:30 UTC); desde el 2 en UTC−5 (abre 14:30 UTC).
select is(pg_temp.abierto_a('2026-10-30T13:30:00Z'), true, 'CA-4: antes del cambio de noviembre, abre a las 13:30 UTC');
select is(pg_temp.abierto_a('2026-11-02T13:30:00Z'), false, 'CA-4: después del cambio de noviembre, 13:30 UTC todavía no abrió');
select is(pg_temp.abierto_a('2026-11-02T14:30:00Z'), true, 'CA-4: después del cambio de noviembre, abre a las 14:30 UTC');
select is(pg_temp.abierto_a('2026-11-02T21:00:00Z'), false, 'CA-4: después del cambio de noviembre, cierra a las 21:00 UTC');

-- private.mercado_en_ventana(margen): abierto o a punto de abrir ---------------------------------------
select is(pg_temp.ventana_a('2026-11-05T14:19:59Z', interval '10 minutes'), false, 'la ventana no abre 10 min y 1 s antes');
select is(pg_temp.ventana_a('2026-11-05T14:20:00Z', interval '10 minutes'), true, 'la ventana abre 10 min antes de la apertura');
select is(pg_temp.ventana_a('2026-11-05T14:30:00Z', interval '10 minutes'), true, 'a la apertura sigue en ventana');
select is(pg_temp.ventana_a('2026-11-05T20:59:59Z', interval '10 minutes'), true, 'abierto está en ventana');
select is(pg_temp.ventana_a('2026-11-05T21:00:00Z', interval '10 minutes'), false, 'al cierre sale de la ventana');
select is(pg_temp.ventana_a('2026-11-05T14:29:59Z', interval '0'), false, 'con margen 0 es lo mismo que estar abierto: antes de abrir no');
select is(pg_temp.ventana_a('2026-11-05T14:30:00Z', interval '0'), true, 'con margen 0 es lo mismo que estar abierto: abierto sí');
select throws_ok($$select private.mercado_en_ventana(null)$$, 'P0001',
                 'mercado_en_ventana: el margen debe ser un intervalo no negativo', 'el margen es obligatorio');
select throws_ok($$select private.mercado_en_ventana(interval '-1 minute')$$, 'P0001',
                 'mercado_en_ventana: el margen debe ser un intervalo no negativo', 'el margen no puede ser negativo');

-- private.sincronizar_calendario ---------------------------------------------------------------------
-- Repetir la misma llamada no cambia nada
select is(
  (select guardados from private.sincronizar_calendario('2026-03-02', '2026-12-31', $json$[
     {"fecha":"2026-03-06","apertura":"2026-03-06T14:30:00Z","cierre":"2026-03-06T21:00:00Z","sesion":"regular"},
     {"fecha":"2026-03-09","apertura":"2026-03-09T13:30:00Z","cierre":"2026-03-09T20:00:00Z","sesion":"regular"},
     {"fecha":"2026-10-30","apertura":"2026-10-30T13:30:00Z","cierre":"2026-10-30T20:00:00Z","sesion":"regular"},
     {"fecha":"2026-11-02","apertura":"2026-11-02T14:30:00Z","cierre":"2026-11-02T21:00:00Z","sesion":"regular"},
     {"fecha":"2026-11-05","apertura":"2026-11-05T14:30:00Z","cierre":"2026-11-05T21:00:00Z","sesion":"regular"},
     {"fecha":"2026-11-27","apertura":"2026-11-27T14:30:00Z","cierre":"2026-11-27T18:00:00Z","sesion":"media_jornada"}
   ]$json$::jsonb)),
  0, 'CA-6: repetir la sincronización no cambia nada (idempotente)');
select is((select count(*)::int from public.calendario_mercado), 6, 'repetir la sincronización no duplica días');
-- Un cambio del broker (cierre anticipado de un día regular) actualiza la fila
select is(
  (select guardados from private.sincronizar_calendario('2026-11-05', '2026-11-05', $json$[
     {"fecha":"2026-11-05","apertura":"2026-11-05T14:30:00Z","cierre":"2026-11-05T18:00:00Z","sesion":"media_jornada"}
   ]$json$::jsonb)),
  1, 'un día que cambió se actualiza');
select is((select cierre from public.calendario_mercado where fecha = '2026-11-05'), '2026-11-05T18:00:00Z'::timestamptz,
          'el día cambiado quedó con su nuevo cierre');
select is((select count(*)::int from public.calendario_mercado), 6, 'las fechas fuera del rango sincronizado no se tocan');
-- Un día que el broker ya no lista dentro del rango se borra; los de fuera del rango se conservan
select is(
  (select eliminados from private.sincronizar_calendario('2026-11-02', '2026-11-30', $json$[
     {"fecha":"2026-11-02","apertura":"2026-11-02T14:30:00Z","cierre":"2026-11-02T21:00:00Z","sesion":"regular"},
     {"fecha":"2026-11-05","apertura":"2026-11-05T14:30:00Z","cierre":"2026-11-05T21:00:00Z","sesion":"regular"}
   ]$json$::jsonb)),
  1, 'un día que el broker ya no lista dentro del rango se elimina');
select is((select count(*)::int from public.calendario_mercado where fecha = '2026-11-27'), 0, 'la media jornada eliminada ya no está');
select is((select count(*)::int from public.calendario_mercado where fecha < '2026-11-02'), 3,
          'los días anteriores al rango se conservan');
select is((select cierre from public.calendario_mercado where fecha = '2026-11-05'), '2026-11-05T21:00:00Z'::timestamptz,
          'el día vuelto a su horario regular se actualizó');
-- Un arreglo vacío borra el rango y nada más
select is((select eliminados from private.sincronizar_calendario('2026-11-01', '2026-11-30', '[]'::jsonb)), 2,
          'un arreglo vacío elimina lo que haya en el rango');
select is((select count(*)::int from public.calendario_mercado), 3, 'y deja intacto lo demás');
-- Entradas inválidas
select throws_ok($$select * from private.sincronizar_calendario(null, '2026-12-01', '[]'::jsonb)$$, 'P0001',
                 'sincronizar_calendario: el rango de fechas no es válido', 'el rango es obligatorio');
select throws_ok($$select * from private.sincronizar_calendario('2026-12-02', '2026-12-01', '[]'::jsonb)$$, 'P0001',
                 'sincronizar_calendario: el rango de fechas no es válido', 'desde no puede ser posterior a hasta');
select throws_ok($$select * from private.sincronizar_calendario('2026-12-01', '2026-12-31', null)$$, 'P0001',
                 'sincronizar_calendario: se esperaba un arreglo', 'nulo no es un arreglo');
select throws_ok($$select * from private.sincronizar_calendario('2026-12-01', '2026-12-31', '{"fecha":"2026-12-01"}'::jsonb)$$, 'P0001',
                 'sincronizar_calendario: se esperaba un arreglo', 'un objeto no es un arreglo');
select throws_ok(
  $$select * from private.sincronizar_calendario('2026-12-01', '2026-12-31',
      '[{"fecha":"2027-01-04","apertura":"2027-01-04T14:30:00Z","cierre":"2027-01-04T21:00:00Z","sesion":"regular"}]'::jsonb)$$,
  'P0001', 'sincronizar_calendario: un día viene incompleto o fuera del rango', 'un día fuera del rango se rechaza');
select throws_ok(
  $$select * from private.sincronizar_calendario('2026-12-01', '2026-12-31',
      '[{"fecha":"2026-12-01","apertura":"2026-12-01T14:30:00Z","cierre":"2026-12-01T21:00:00Z"}]'::jsonb)$$,
  'P0001', 'sincronizar_calendario: un día viene incompleto o fuera del rango', 'un día sin sesión se rechaza');
select throws_ok(
  $$select * from private.sincronizar_calendario('2026-12-01', '2026-12-31', '[
      {"fecha":"2026-12-01","apertura":"2026-12-01T14:30:00Z","cierre":"2026-12-01T21:00:00Z","sesion":"regular"},
      {"fecha":"2026-12-01","apertura":"2026-12-01T14:30:00Z","cierre":"2026-12-01T21:00:00Z","sesion":"regular"}]'::jsonb)$$,
  'P0001', 'sincronizar_calendario: hay fechas repetidas', 'las fechas repetidas se rechazan');
-- CB-51: una apertura que no cae en su día de Nueva York delata una conversión de horario mal hecha
select throws_ok(
  $$select * from private.sincronizar_calendario('2026-12-01', '2026-12-31',
      '[{"fecha":"2026-12-02","apertura":"2026-12-01T14:30:00Z","cierre":"2026-12-01T21:00:00Z","sesion":"regular"}]'::jsonb)$$,
  'P0001', 'sincronizar_calendario: una apertura no cae en su día de mercado de Nueva York',
  'CA-4: una apertura en otro día de Nueva York se rechaza');
select throws_ok(
  $$select * from private.sincronizar_calendario('2026-12-01', '2026-12-31',
      '[{"fecha":"2026-12-01","apertura":"2026-12-01T21:00:00Z","cierre":"2026-12-01T14:30:00Z","sesion":"regular"}]'::jsonb)$$,
  '23514', null, 'un cierre anterior a la apertura se rechaza');
select throws_ok(
  $$select * from private.sincronizar_calendario('2026-12-01', '2026-12-31',
      '[{"fecha":"2026-12-01","apertura":"2026-12-01T14:30:00Z","cierre":"2026-12-01T21:00:00Z","sesion":"extendida"}]'::jsonb)$$,
  '23514', null, 'una sesión que no es regular ni media_jornada se rechaza');
select is((select count(*)::int from public.calendario_mercado), 3, 'ninguna entrada inválida dejó datos');

-- private.sincronizar_activos ------------------------------------------------------------------------------
select pruebas.fijar_reloj('2026-11-06T10:00:00Z');
-- AAPL también en Usuarios, para comprobar que se actualizan todas las filas del símbolo
insert into public.lista_blanca (bolsillo, simbolo, nombre) values ('usuarios', 'AAPL', 'Apple Inc.');
select is(
  (select count(*)::int from private.sincronizar_activos($json$[
     {"simbolo":"AAPL","negociable":true,"fraccionable":true},
     {"simbolo":"ASML","negociable":true,"fraccionable":false},
     {"simbolo":"SNDK","negociable":false,"fraccionable":false},
     {"simbolo":"NOEXISTE","negociable":true,"fraccionable":true}
   ]$json$::jsonb)),
  4, 'CA-7: devuelve una fila por cada fila de lista_blanca actualizada (AAPL en dos bolsillos; un símbolo ajeno se ignora)');
select is(
  (select array_agg(l.bolsillo::text || ':' || l.fraccionable::text order by l.bolsillo)
     from public.lista_blanca l where l.simbolo = 'AAPL'),
  array['arriesgadas:true', 'usuarios:true'], 'CA-7: AAPL quedó fraccionable en sus dos bolsillos');
select is((select fraccionable from public.lista_blanca where simbolo = 'ASML'), false, 'CA-7: ASML no es fraccionable');
select is((select negociable from public.lista_blanca where simbolo = 'ASML'), true, 'CA-7: ASML sí es negociable');
select is((select sincronizado_en from public.lista_blanca where simbolo = 'AAPL' and bolsillo = 'arriesgadas'),
          '2026-11-06T10:00:00Z'::timestamptz, 'sincronizado_en toma la hora de private.ahora()');
select is((select activo from public.lista_blanca where simbolo = 'ASML'), true, 'un símbolo negociable sigue activo');
select is((select activo from public.lista_blanca where simbolo = 'SNDK'), false,
          'CA-5: el símbolo que dejó de ser negociable queda desactivado');
select is((select negociable from public.lista_blanca where simbolo = 'SNDK'), false, 'CA-5: y guarda que no es negociable');
select is((select count(*)::int from public.lista_blanca where simbolo = 'MSFT' and sincronizado_en is not null), 0,
          'un símbolo que no vino en la sincronización no se toca');
select is(
  (select array_agg(s.simbolo order by s.simbolo)
     from private.sincronizar_activos('[{"simbolo":"SNDK","negociable":false,"fraccionable":false}]'::jsonb) s
    where s.desactivado),
  null::text[], 'CA-5: una segunda sincronización no vuelve a reportar como desactivado al que ya lo estaba');
-- No reactiva solo
select is((select count(*)::int from private.sincronizar_activos('[{"simbolo":"SNDK","negociable":true,"fraccionable":true}]'::jsonb)), 1,
          'un símbolo que vuelve a ser negociable también se actualiza');
select is((select activo from public.lista_blanca where simbolo = 'SNDK'), false,
          'pero no se reactiva solo: eso lo decide el Administrador (HU-036)');
select is((select negociable from public.lista_blanca where simbolo = 'SNDK'), true, 'aunque ahora sí guarda que es negociable');
-- El desactivado de esta llamada se informa
select is(
  (select s.desactivado from private.sincronizar_activos('[{"simbolo":"ADBE","negociable":false,"fraccionable":true}]'::jsonb) s),
  true, 'se informa el símbolo que se desactivó en esta llamada');
-- Entradas inválidas
select throws_ok($$select * from private.sincronizar_activos(null)$$, 'P0001',
                 'sincronizar_activos: se esperaba un arreglo', 'nulo no es un arreglo');
select throws_ok($$select * from private.sincronizar_activos('{"simbolo":"AAPL"}'::jsonb)$$, 'P0001',
                 'sincronizar_activos: se esperaba un arreglo', 'un objeto no es un arreglo');
select throws_ok($$select * from private.sincronizar_activos('[{"simbolo":"AAPL","negociable":true}]'::jsonb)$$, 'P0001',
                 'sincronizar_activos: un activo viene incompleto', 'un activo sin fraccionable se rechaza');
select throws_ok($$select * from private.sincronizar_activos('[{"simbolo":"AAPL","negociable":true,"fraccionable":true},{"simbolo":"AAPL","negociable":false,"fraccionable":false}]'::jsonb)$$,
                 'P0001', 'sincronizar_activos: hay símbolos repetidos', 'los símbolos repetidos se rechazan');
select is((select count(*)::int from private.sincronizar_activos('[]'::jsonb)), 0, 'un arreglo vacío no actualiza nada');

-- Las funciones son internas: la API no las ejecuta ---------------------------------------------------------------
select is(
  (select count(*)::int from pg_proc p
    where p.oid in ('private.mercado_abierto()'::regprocedure,
                    'private.mercado_en_ventana(interval)'::regprocedure,
                    'private.sincronizar_calendario(date, date, jsonb)'::regprocedure,
                    'private.sincronizar_activos(jsonb)'::regprocedure)
      and (has_function_privilege('anon', p.oid, 'execute') or has_function_privilege('authenticated', p.oid, 'execute'))),
  0, 'anon y authenticated no pueden ejecutar las funciones de horario ni de sincronización');
select is(
  (select count(*)::int from pg_proc p
    where p.oid in ('private.mercado_abierto()'::regprocedure,
                    'private.mercado_en_ventana(interval)'::regprocedure,
                    'private.sincronizar_calendario(date, date, jsonb)'::regprocedure,
                    'private.sincronizar_activos(jsonb)'::regprocedure)
      and p.prosecdef and p.proconfig = array['search_path=""']),
  4, 'las cuatro son security definer con search_path vacío');

-- Ventana de compras y estado del mercado (CA-1, CA-3) ------------------------------------------------------------
-- Calendario del mes: un día regular (2026-11-05) y una media jornada (2026-11-27); el feriado
-- (2026-11-26) no tiene fila.
select is(
  (select guardados from private.sincronizar_calendario('2026-11-01', '2026-11-30', $json$[
     {"fecha":"2026-11-05","apertura":"2026-11-05T14:30:00Z","cierre":"2026-11-05T21:00:00Z","sesion":"regular"},
     {"fecha":"2026-11-27","apertura":"2026-11-27T14:30:00Z","cierre":"2026-11-27T18:00:00Z","sesion":"media_jornada"}
   ]$json$::jsonb)),
  2, 'se vuelve a sincronizar noviembre: un día regular y una media jornada');

create function pg_temp.compras_a(p_hora timestamptz) returns boolean language plpgsql as $$
begin
  perform pruebas.fijar_reloj(p_hora);
  return private.ventana_compras_abierta();
end;
$$;
create function pg_temp.estado_a(p_hora timestamptz) returns text language plpgsql as $$
begin
  perform pruebas.fijar_reloj(p_hora);
  return (select e.estado from public.estado_mercado() e);
end;
$$;

set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';

-- Márgenes: los defectos de docs/02 §10 (mercado.minutos_tras_apertura = 5, minutos_antes_cierre = 15)
select is((select tras_apertura from private.margenes_de_compra()), 5, 'las compras empiezan 5 minutos tras la apertura (RR-07)');
select is((select antes_cierre from private.margenes_de_compra()), 15, 'y terminan 15 minutos antes del cierre (RR-07)');

-- private.ventana_compras_abierta(): apertura + 5 min a cierre − 15 min
select is(pg_temp.compras_a('2026-11-05T14:29:59Z'), false, 'antes de abrir no se compra');
select is(pg_temp.compras_a('2026-11-05T14:34:59Z'), false, 'en los primeros 5 minutos no se compra');
select is(pg_temp.compras_a('2026-11-05T14:35:00Z'), true, 'a los 5 minutos de abrir se compra');
select is(pg_temp.compras_a('2026-11-05T20:44:59Z'), true, 'hasta 15 minutos antes del cierre se compra');
select is(pg_temp.compras_a('2026-11-05T20:45:00Z'), false, 'en los últimos 15 minutos no se compra');
select is(pg_temp.compras_a('2026-11-26T17:00:00Z'), false, 'CA-2: en un feriado no se compra');
-- CA-3 (CB-50): en la media jornada la ventana se calcula con el cierre de las 13:00 de Nueva York
select is(pg_temp.compras_a('2026-11-27T14:35:00Z'), true, 'CA-3: en la media jornada se compra desde los 5 minutos');
select is(pg_temp.compras_a('2026-11-27T17:44:59Z'), true, 'CA-3: hasta 15 minutos antes de las 13:00 se compra');
select is(pg_temp.compras_a('2026-11-27T17:45:00Z'), false, 'CA-3: desde las 12:45 de Nueva York ya no se compra');
select is(pg_temp.compras_a('2026-11-27T20:00:00Z'), false, 'CA-3: a la hora del cierre normal tampoco');

-- public.estado_mercado(): los cinco estados de un día regular (docs/08 §6)
select is(pg_temp.estado_a('2026-11-05T14:19:59Z'), 'cerrado', 'CA-1: más de 10 minutos antes de abrir está cerrado');
select is(pg_temp.estado_a('2026-11-05T14:20:00Z'), 'pre_apertura', 'CA-1: 10 minutos antes de abrir empieza la preapertura');
select is(pg_temp.estado_a('2026-11-05T14:29:59Z'), 'pre_apertura', 'CA-1: sigue en preapertura hasta abrir');
select is(pg_temp.estado_a('2026-11-05T14:30:00Z'), 'abierto_sin_compras', 'CA-1: al abrir está abierto sin compras');
select is(pg_temp.estado_a('2026-11-05T14:34:59Z'), 'abierto_sin_compras', 'CA-1: abierto sin compras los primeros 5 minutos');
select is(pg_temp.estado_a('2026-11-05T14:35:00Z'), 'abierto', 'CA-1: a los 5 minutos está abierto');
select is(pg_temp.estado_a('2026-11-05T20:44:59Z'), 'abierto', 'CA-1: abierto hasta 15 minutos antes del cierre');
select is(pg_temp.estado_a('2026-11-05T20:45:00Z'), 'cierre_proximo', 'CA-1: los últimos 15 minutos son de cierre próximo');
select is(pg_temp.estado_a('2026-11-05T20:59:59Z'), 'cierre_proximo', 'CA-1: cierre próximo hasta cerrar');
select is(pg_temp.estado_a('2026-11-05T21:00:00Z'), 'cerrado', 'CA-1: al cierre está cerrado');
-- Feriado y media jornada
select is(pg_temp.estado_a('2026-11-26T15:00:00Z'), 'cerrado', 'CA-2: el feriado está cerrado a mediodía');
select is(pg_temp.estado_a('2026-11-26T14:30:00Z'), 'cerrado', 'CA-2: y no hay preapertura ni apertura el feriado');
select is(pg_temp.estado_a('2026-11-27T17:44:59Z'), 'abierto', 'CA-3: la media jornada sigue abierta hasta las 12:45 de Nueva York');
select is(pg_temp.estado_a('2026-11-27T17:45:00Z'), 'cierre_proximo', 'CA-3: desde las 12:45 es cierre próximo');
select is(pg_temp.estado_a('2026-11-27T18:00:00Z'), 'cerrado', 'CA-3: a las 13:00 de Nueva York cierra');

-- Las demás columnas, a media sesión regular
select pruebas.fijar_reloj('2026-11-05T16:00:00Z');
select is((select abierto from public.estado_mercado()), true, 'CA-1: abierto');
select is((select ahora from public.estado_mercado()), '2026-11-05T16:00:00Z'::timestamptz, 'CA-1: devuelve la hora del servidor (private.ahora())');
select is((select proximo_cierre from public.estado_mercado()), '2026-11-05T21:00:00Z'::timestamptz, 'CA-1: próximo cierre');
select is((select proxima_apertura from public.estado_mercado()), '2026-11-27T14:30:00Z'::timestamptz,
          'CA-1: próxima apertura (el feriado se salta)');
select is((select compras_desde from public.estado_mercado()), '2026-11-05T14:35:00Z'::timestamptz, 'CA-1: la ventana de compras empieza');
select is((select compras_hasta from public.estado_mercado()), '2026-11-05T20:45:00Z'::timestamptz, 'CA-1: y termina');
select is((select ventana_compras_abierta from public.estado_mercado()), true, 'CA-1: la ventana de compras está abierta');
select is((select sesion from public.estado_mercado()), 'regular', 'CA-1: sesión regular');
select is((select datos_actualizados_en from public.estado_mercado()), null::timestamptz,
          'la frescura de los datos queda nula hasta que HU-028 cree cotizaciones');
-- En la media jornada, la sesión y la ventana salen del cierre de las 13:00
select pruebas.fijar_reloj('2026-11-27T16:00:00Z');
select is((select sesion from public.estado_mercado()), 'media_jornada', 'CA-3: la sesión es media jornada');
select is((select compras_hasta from public.estado_mercado()), '2026-11-27T17:45:00Z'::timestamptz,
          'CA-3: la ventana de compras termina 15 minutos antes de las 13:00 de Nueva York');
select is((select proximo_cierre from public.estado_mercado()), '2026-11-27T18:00:00Z'::timestamptz, 'CA-3: el cierre es a las 13:00 de Nueva York');
-- Sin sesiones por delante: cerrado y sin próximas horas
select pruebas.fijar_reloj('2026-11-28T15:00:00Z');
select is((select estado from public.estado_mercado()), 'cerrado', 'sin más sesiones en el calendario está cerrado');
select is((select proxima_apertura from public.estado_mercado()), null::timestamptz, 'y no hay próxima apertura');
select is((select ventana_compras_abierta from public.estado_mercado()), false, 'ni ventana de compras');

-- Quién la llama: toda persona activa; el resto, NO_AUTORIZADO; anon, nada
select pruebas.fijar_reloj('2026-11-05T16:00:00Z');
set local role authenticated;
select is((select estado from public.estado_mercado()), 'abierto', 'un usuario activo consulta el estado del mercado');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is((select estado from public.estado_mercado()), 'abierto', 'un analista activo lo consulta');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is((select estado from public.estado_mercado()), 'abierto', 'un administrador activo lo consulta');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select throws_ok($$select * from public.estado_mercado()$$, 'P0001', 'NO_AUTORIZADO', 'una cuenta suspendida recibe NO_AUTORIZADO');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000009", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select throws_ok($$select * from public.estado_mercado()$$, 'P0001', 'NO_AUTORIZADO', 'una cuenta sin perfil recibe NO_AUTORIZADO');
set local request.jwt.claims to '';
select throws_ok($$select * from public.estado_mercado()$$, 'P0001', 'NO_AUTORIZADO', 'sin sesión recibe NO_AUTORIZADO');
reset role;
set local role anon;
select throws_ok($$select * from public.estado_mercado()$$, '42501', null, 'anon no puede llamar estado_mercado()');
reset role;
select ok(has_function_privilege('authenticated', 'public.estado_mercado()', 'execute'), 'authenticated puede ejecutar estado_mercado()');
select ok(not has_function_privilege('anon', 'public.estado_mercado()', 'execute'), 'anon no puede ejecutar estado_mercado()');
select is(
  (select count(*)::int from pg_proc p
    where p.oid in ('private.margenes_de_compra()'::regprocedure, 'private.ventana_compras_abierta()'::regprocedure)
      and (has_function_privilege('anon', p.oid, 'execute') or has_function_privilege('authenticated', p.oid, 'execute'))),
  0, 'la API no ejecuta las funciones internas de la ventana de compras');
select is(
  (select count(*)::int from pg_proc p
    where p.oid in ('public.estado_mercado()'::regprocedure, 'private.margenes_de_compra()'::regprocedure,
                    'private.ventana_compras_abierta()'::regprocedure)
      and p.prosecdef and p.proconfig = array['search_path=""']),
  3, 'las tres son security definer con search_path vacío');

-- Trabajo diario `calendario` de pg_cron (docs/05 §7) --------------------------------------------------------------
select is((select schedule from cron.job where jobname = 'calendario'), '0 10 * * *',
          'CA-6: el trabajo `calendario` corre todos los días a las 10:00 UTC');
select is((select command from cron.job where jobname = 'calendario'),
          $$select private.despertar_funcion('calendario-mercado')$$,
          'y despierta a calendario-mercado');
select is((select count(*)::int from cron.job where jobname = 'calendario'), 1, 'hay un solo trabajo `calendario`');

select pruebas.fijar_reloj(null);
select * from finish();
rollback;

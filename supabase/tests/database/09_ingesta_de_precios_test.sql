-- HU-028 · Ingesta de precios: tabla `cotizaciones`, private.publicar_cotizaciones, frescura en
-- estado_mercado() y trabajo `ingesta_mercado` de pg_cron.
-- Criterios: CA-1 a CA-5 de backlog/E-04-datos-de-mercado/HU-028-*.md (la parte de base de datos;
-- la de la función `ingesta-mercado` la cubren sus pruebas de deno). Reglas: docs/09 §2 y §4, CB-53.
-- Todo corre dentro de una transacción que se deshace.
begin;
create extension if not exists pgtap with schema extensions;
select plan(56);

-- Cuentas de prueba: 0001 usuario · 0004 suspendido.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test', 'Suspendido de prueba', 'usuario', 'suspendido', now(), null);

-- Estructura y seguridad -----------------------------------------------------------------------
select has_table('public', 'cotizaciones', 'existe la tabla cotizaciones');
select col_is_pk('public', 'cotizaciones', 'simbolo', 'cotizaciones guarda solo la última por símbolo (pk = simbolo)');
select ok((select relrowsecurity from pg_class where oid = 'public.cotizaciones'::regclass), 'cotizaciones tiene RLS activo');
select ok(not has_table_privilege('anon', 'public.cotizaciones', 'select'), 'anon no lee cotizaciones');
select ok(has_table_privilege('authenticated', 'public.cotizaciones', 'select'), 'authenticated lee cotizaciones');
select ok(not has_table_privilege('authenticated', 'public.cotizaciones', 'insert')
          and not has_table_privilege('authenticated', 'public.cotizaciones', 'update')
          and not has_table_privilege('authenticated', 'public.cotizaciones', 'delete'),
          'authenticated no escribe cotizaciones');
select has_function('private', 'publicar_cotizaciones', array['jsonb'], 'existe private.publicar_cotizaciones');
select ok(not has_function_privilege('authenticated', 'private.publicar_cotizaciones(jsonb)', 'execute')
          and not has_function_privilege('anon', 'private.publicar_cotizaciones(jsonb)', 'execute'),
          'ni authenticated ni anon ejecutan publicar_cotizaciones');

-- Un lote con válidos e inválidos (CA-1, CA-2, CB-53) -------------------------------------------
select pruebas.fijar_reloj('2031-03-04T15:00:00Z');
create temp table lote1 as
select * from private.publicar_cotizaciones($json$[
  {"simbolo": "AAPL", "precio": 101.5, "bid": 101.49, "ask": 101.51, "cierre_anterior": 100, "volumen_dia": 12345,
   "fuente": "simulado", "momento": "2031-03-04T14:59:50Z",
   "barra_minuto": {"momento": "2031-03-04T14:59:00Z", "apertura": 101, "maximo": 102, "minimo": 100.5, "cierre": 101.5, "volumen": 10}},
  {"simbolo": "QQQ", "precio": 400.25, "bid": 400.2, "ask": 400.3, "cierre_anterior": 398, "volumen_dia": 999,
   "fuente": "simulado", "momento": "2031-03-04T14:59:55Z",
   "barra_minuto": {"momento": "2031-03-04T14:59:00Z", "apertura": 400, "maximo": 400.5, "minimo": 399.9, "cierre": 400.25, "volumen": 50}},
  {"simbolo": "MSFT", "precio": 300, "fuente": "simulado", "momento": "2031-03-04T14:59:55Z"},
  {"simbolo": "NVDA", "precio": 0, "fuente": "simulado", "momento": "2031-03-04T14:59:55Z"},
  {"simbolo": "AMZN", "precio": -5, "fuente": "simulado", "momento": "2031-03-04T14:59:55Z"},
  {"simbolo": "GOOG", "precio": null, "fuente": "simulado", "momento": "2031-03-04T14:59:55Z"},
  {"simbolo": "META", "precio": "abc", "fuente": "simulado", "momento": "2031-03-04T14:59:55Z"},
  {"simbolo": "AMD", "fuente": "simulado", "momento": "2031-03-04T14:59:55Z"},
  {"simbolo": "ZZZZ", "precio": 10, "fuente": "simulado", "momento": "2031-03-04T14:59:55Z"}
]$json$::jsonb);
select is((select guardadas from lote1), 3, 'CA-1: se guardan las 3 cotizaciones válidas');
select is((select descartadas from lote1), 6, 'CA-2: se descartan las 6 inválidas (precio 0, negativo, nulo, texto, ausente y símbolo ajeno)');
select is((select barras_minuto from lote1), 2, 'se guardan las barras de minuto de la acción y del ETF (D-71)');
select is((select count(*)::int from public.cotizaciones where simbolo in ('AAPL', 'QQQ', 'MSFT')), 3, 'CA-1: cotizaciones tiene las válidas');
select is((select count(*)::int from public.cotizaciones where simbolo in ('NVDA', 'AMZN', 'GOOG', 'META', 'AMD', 'ZZZZ')), 0,
          'CA-2: ningún precio inválido llega a guardarse');
select is((select precio from public.cotizaciones where simbolo = 'AAPL'), 101.5000::numeric, 'AAPL guarda su precio');
select is((select variacion_dia_pct from public.cotizaciones where simbolo = 'AAPL'), 1.50::numeric,
          'la variación del día sale del precio y del cierre anterior');
select is((select bid from public.cotizaciones where simbolo = 'AAPL'), 101.4900::numeric, 'AAPL guarda el bid');
select is((select variacion_dia_pct from public.cotizaciones where simbolo = 'MSFT'), null::numeric, 'sin cierre anterior, la variación queda nula');
select is((select recibido_en from public.cotizaciones where simbolo = 'AAPL'), '2031-03-04T15:00:00Z'::timestamptz,
          'recibido_en es la hora del servidor (private.ahora())');
select is((select momento from public.cotizaciones where simbolo = 'AAPL'), '2031-03-04T14:59:50Z'::timestamptz, 'momento es la hora del proveedor');
select is((select motivo from lote1, jsonb_to_recordset(descartes) as d(simbolo text, motivo text) where d.simbolo = 'NVDA'),
          'PRECIO_INVALIDO', 'el descarte queda registrado con su motivo (precio 0)');
select is((select motivo from lote1, jsonb_to_recordset(descartes) as d(simbolo text, motivo text) where d.simbolo = 'META'),
          'PRECIO_INVALIDO', 'el descarte queda registrado con su motivo (precio no numérico)');
select is((select motivo from lote1, jsonb_to_recordset(descartes) as d(simbolo text, motivo text) where d.simbolo = 'ZZZZ'),
          'SIMBOLO_FUERA_DEL_UNIVERSO', 'un símbolo ajeno al universo se descarta');
select is((select count(*)::int from public.barras_minuto where simbolo = 'QQQ'), 1, 'el ETF QQQ guarda su barra de minuto');
select is((select count(*)::int from public.barras_minuto where simbolo = 'AAPL'), 1, 'una acción también guarda su barra de minuto (D-71)');

-- El evento en el canal mercado (CA-1, FR-069) -------------------------------------------------
select is((select count(*)::int from realtime.messages where topic = 'mercado' and event = 'cotizaciones' and private), 1,
          'CA-1: se publica un evento cotizaciones privado en el canal mercado');
select is((select jsonb_array_length(payload -> 'datos') from realtime.messages where topic = 'mercado' and event = 'cotizaciones'), 3,
          'el evento trae solo las cotizaciones guardadas');
select is((select payload -> 'momento' from realtime.messages where topic = 'mercado' and event = 'cotizaciones'),
          to_jsonb('2031-03-04T15:00:00Z'::timestamptz), 'el evento lleva la hora del lote');
select is((select (e ->> 'p')::numeric from realtime.messages m, jsonb_array_elements(m.payload -> 'datos') e
            where m.event = 'cotizaciones' and e ->> 's' = 'AAPL'), 101.5::numeric, 'el evento lleva el precio de AAPL en la clave p');
select is((select (e ->> 'vd')::numeric from realtime.messages m, jsonb_array_elements(m.payload -> 'datos') e
            where m.event = 'cotizaciones' and e ->> 's' = 'AAPL'), 1.5::numeric, 'el evento lleva la variación en la clave vd');

-- Un dato más viejo no reemplaza al guardado y no se publica -------------------------------------
select pruebas.fijar_reloj('2031-03-04T15:00:15Z');
create temp table lote2 as
select * from private.publicar_cotizaciones($json$[
  {"simbolo": "AAPL", "precio": 50, "fuente": "simulado", "momento": "2031-03-04T14:00:00Z"}]$json$::jsonb);
select is((select guardadas from lote2), 0, 'un dato más viejo no se guarda');
select is((select precio from public.cotizaciones where simbolo = 'AAPL'), 101.5000::numeric, 'el precio guardado no retrocede');
select is((select count(*)::int from realtime.messages where event = 'cotizaciones'), 1, 'un lote sin nada guardado no publica evento');

-- Un dato del mismo momento (el mercado no operó) sí refresca la recepción ------------------------
create temp table lote3 as
select * from private.publicar_cotizaciones($json$[
  {"simbolo": "AAPL", "precio": 101.5, "cierre_anterior": 100, "fuente": "simulado", "momento": "2031-03-04T14:59:50Z"}]$json$::jsonb);
select is((select guardadas from lote3), 1, 'el dato del mismo momento se guarda');
select is((select recibido_en from public.cotizaciones where simbolo = 'AAPL'), '2031-03-04T15:00:15Z'::timestamptz,
          'recibido_en avanza con la última consulta aunque el precio sea el mismo');
select is((select count(*)::int from realtime.messages where event = 'cotizaciones'), 2, 'cada lote guardado publica un evento');

-- Una barra de minuto incoherente se omite sin perder la cotización -----------------------------
create temp table lote4 as
select * from private.publicar_cotizaciones($json$[
  {"simbolo": "QLD", "precio": 80, "fuente": "simulado", "momento": "2031-03-04T15:00:10Z",
   "barra_minuto": {"momento": "2031-03-04T15:00:00Z", "apertura": 80, "maximo": 70, "minimo": 90, "cierre": 80, "volumen": 1}}]$json$::jsonb);
select is((select guardadas from lote4), 1, 'la cotización con barra incoherente se guarda');
select is((select barras_minuto from lote4), 0, 'la barra incoherente no se guarda');
select is((select motivo from lote4, jsonb_to_recordset(descartes) as d(simbolo text, motivo text)), 'BARRA_MINUTO_INVALIDA',
          'la barra incoherente queda registrada');

-- Datos que no son un arreglo --------------------------------------------------------------------
select throws_ok($$select * from private.publicar_cotizaciones('{"simbolo": "AAPL"}'::jsonb)$$, '22023', null, 'unos datos que no son un arreglo se rechazan');
select throws_ok($$select * from private.publicar_cotizaciones(null)$$, '22023', null, 'unos datos nulos se rechazan');
select is((select count(*)::int from private.publicar_cotizaciones('[]'::jsonb) where guardadas = 0 and descartadas = 0), 1, 'un arreglo vacío no hace nada');

-- Lectura por RLS y frescura en estado_mercado() -------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select count(*)::int from public.cotizaciones), 4, 'una persona activa lee las cotizaciones');
select is((select datos_actualizados_en from public.estado_mercado()), '2031-03-04T15:00:15Z'::timestamptz,
          'estado_mercado() informa la recepción de la última cotización');
select throws_ok($$insert into public.cotizaciones (simbolo, precio, fuente, momento) values ('AAPL', 1, 'x', now())$$, '42501', null,
                 'una escritura directa en cotizaciones falla');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated"}';
select is((select count(*)::int from public.cotizaciones), 0, 'una cuenta suspendida no lee cotizaciones');
select throws_ok($$select * from public.estado_mercado()$$, 'P0001', 'NO_AUTORIZADO', 'una cuenta suspendida no consulta estado_mercado()');
reset role;
set local role anon;
select throws_ok($$select count(*) from public.cotizaciones$$, '42501', null, 'anon no lee cotizaciones');
reset role;

-- El trabajo ingesta_mercado de pg_cron (CA-1, CA-3) ----------------------------------------------
select is((select count(*)::int from cron.job where jobname = 'ingesta_mercado'), 1, 'hay un solo trabajo `ingesta_mercado`');
select is((select schedule from cron.job where jobname = 'ingesta_mercado'), '15 seconds', 'corre cada 15 segundos');
select ok((select command like '%despertar_funcion(''ingesta-mercado'')%mercado_en_ventana(interval ''10 minutes'')%'
             from cron.job where jobname = 'ingesta_mercado'),
          'despierta ingesta-mercado solo si el mercado está en ventana de 10 minutos');
create function pg_temp.filas_del_trabajo() returns integer language plpgsql as $$
declare v_comando text; v_filas integer;
begin
  select command into v_comando from cron.job where jobname = 'ingesta_mercado';
  execute 'select count(*) from (' || v_comando || ') t' into v_filas;
  return v_filas;
end $$;
-- CA-3: con el mercado cerrado la condición no se cumple y no se llama a la función (ni a Vault ni a pg_net).
select pruebas.fijar_reloj('2031-03-04T03:00:00Z');
select is(pg_temp.filas_del_trabajo(), 0, 'CA-3: con el mercado cerrado el trabajo no despierta la función');
insert into public.calendario_mercado (fecha, apertura, cierre, sesion)
  values ('2031-03-04', '2031-03-04T14:30:00Z', '2031-03-04T21:00:00Z', 'regular');
select pruebas.fijar_reloj('2031-03-04T14:19:00Z');
select ok(not private.mercado_en_ventana(interval '10 minutes'), 'más de 10 minutos antes de abrir, el mercado no está en ventana');
select pruebas.fijar_reloj('2031-03-04T14:21:00Z');
select ok(private.mercado_en_ventana(interval '10 minutes'), '9 minutos antes de abrir ya está en ventana');
select pruebas.fijar_reloj('2031-03-04T21:30:00Z');
select is(pg_temp.filas_del_trabajo(), 0, 'CA-3: después del cierre el trabajo no despierta la función');

-- D-71: las barras de las acciones sirven el día en curso y la limpieza de la madrugada las borra ---
select pruebas.fijar_reloj('2031-03-05T08:00:00Z');
select private.limpiar_barras_minuto();
select is((select count(*)::int from public.barras_minuto where simbolo = 'AAPL'), 0,
          'D-71: al día siguiente la limpieza borra la barra de la acción sin posición');
select is((select count(*)::int from public.barras_minuto where simbolo = 'QQQ'), 1,
          'D-71: la limpieza conserva la barra reciente del ETF');

select * from finish();
rollback;

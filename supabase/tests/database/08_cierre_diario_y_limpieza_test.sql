-- HU-029 · Barra diaria tras el cierre y retención de barras de minuto.
-- Cubre en la capa de base de datos CA-2, CA-3 y CA-4 de backlog/E-04-datos-de-mercado/HU-029-*.md
-- (CA-1 lo cubre el deno test de `cierre-diario`): la condición del trabajo `cierre_diario`
-- con el reloj fijado (antes y después del cierre, con y sin las barras de hoy, día sin sesión,
-- feriado, media jornada y fecha de Nueva York), la retención de `barras_minuto` y los trabajos
-- de pg_cron. Todo corre dentro de una transacción que se deshace.
begin;
create extension if not exists pgtap with schema extensions;
select plan(32);

-- Calendario: dos días regulares, una media jornada y un feriado sin fila (2026-11-26).
select private.sincronizar_calendario('2026-11-02', '2026-11-30', $json$[
  {"fecha":"2026-11-05","apertura":"2026-11-05T14:30:00Z","cierre":"2026-11-05T21:00:00Z","sesion":"regular"},
  {"fecha":"2026-11-25","apertura":"2026-11-25T14:30:00Z","cierre":"2026-11-25T21:00:00Z","sesion":"regular"},
  {"fecha":"2026-11-27","apertura":"2026-11-27T14:30:00Z","cierre":"2026-11-27T18:00:00Z","sesion":"media_jornada"}
]$json$::jsonb);

create function pg_temp.pendiente_a(p_hora timestamptz) returns boolean language plpgsql as $$
begin
  perform pruebas.fijar_reloj(p_hora);
  return private.cierre_diario_pendiente();
end;
$$;

-- Barra de un día para cada símbolo del universo (lo que dejaría `cierre-diario`).
create function pg_temp.barras_de(p_fecha date) returns integer language sql as $$
  select private.guardar_barras_diarias((
    select jsonb_agg(jsonb_build_object(
             'simbolo', u.simbolo, 'fecha', p_fecha, 'apertura', 10, 'maximo', 11,
             'minimo', 9, 'cierre', 10.5, 'volumen', 1000))
      from private.simbolos_del_universo() u))
$$;

-- Condición del trabajo -------------------------------------------------------------------------
select is(pg_temp.pendiente_a('2026-11-05T20:59:00Z'), false,
          'antes del cierre no toca (el mercado aún no cerró hoy)');
select is(pg_temp.pendiente_a('2026-11-05T21:00:00Z'), true,
          'al cierre, sin las barras de hoy, toca');
select is(pg_temp.pendiente_a('2026-11-05T23:50:00Z'), true,
          'horas después del cierre, sin las barras de hoy, sigue tocando');

select is(pg_temp.barras_de('2026-11-05'), (select count(*)::int from private.simbolos_del_universo()),
          'preparación: se guarda la barra de hoy de cada símbolo del universo');
select is(pg_temp.pendiente_a('2026-11-05T21:30:00Z'), false,
          'CA-2: con las barras de hoy ya guardadas, el trabajo no corre otra vez');

delete from public.barras_diarias where simbolo = 'AAPL' and fecha = '2026-11-05';
select is(pg_temp.pendiente_a('2026-11-05T21:40:00Z'), true,
          'si a un solo símbolo le falta la barra de hoy, vuelve a tocar');
select is(pg_temp.barras_de('2026-11-05'), 1, 'repetir el guardado solo agrega la barra que faltaba');
select is(pg_temp.pendiente_a('2026-11-05T21:50:00Z'), false, 'con la barra completa ya no toca');

-- La fecha es la de Nueva York: 02:00 UTC del 6 aún es el 5 allá.
delete from public.barras_diarias where fecha = '2026-11-05';
select is(pg_temp.pendiente_a('2026-11-06T02:00:00Z'), true,
          'a las 02:00 UTC aún es de noche del 5 en Nueva York: sigue tocando');
select is(pg_temp.pendiente_a('2026-11-06T15:00:00Z'), false,
          'el viernes 6 no hay fila en el calendario: no toca');

-- Días sin sesión (CA-4) ------------------------------------------------------------------------
select is(pg_temp.pendiente_a('2026-11-07T22:00:00Z'), false, 'CA-4: un sábado no toca');
select is(pg_temp.pendiente_a('2026-11-08T22:00:00Z'), false, 'CA-4: un domingo no toca');
select is(pg_temp.pendiente_a('2026-11-26T22:00:00Z'), false, 'CA-4: un feriado (Acción de Gracias) no toca');

-- Media jornada: toca desde el cierre real de las 13:00 de Nueva York (18:00 UTC) ---------------
select is(pg_temp.pendiente_a('2026-11-27T17:59:00Z'), false, 'media jornada: antes del cierre anticipado no toca');
select is(pg_temp.pendiente_a('2026-11-27T18:00:00Z'), true, 'media jornada: toca desde el cierre anticipado');

-- Un símbolo nuevo del universo sin barra de hoy vuelve a hacer tocar ---------------------------
select pg_temp.barras_de('2026-11-25');
select is(pg_temp.pendiente_a('2026-11-25T21:10:00Z'), false, 'preparación: el día 25 quedó completo');
insert into public.lista_blanca (bolsillo, simbolo, nombre, en_nasdaq100)
values ('arriesgadas', 'ZZNUEVO', 'Símbolo nuevo de prueba', true);
select is(pg_temp.pendiente_a('2026-11-25T21:20:00Z'), true,
          'un símbolo nuevo del universo sin su barra de hoy vuelve a hacer tocar');

-- Permisos de las funciones ---------------------------------------------------------------------
select is(
  (select count(*)::int
     from unnest(array['private.cierre_diario_pendiente()', 'private.limpiar_barras_minuto()']) f,
          unnest(array['anon', 'authenticated']) r
    where has_function_privilege(r, f, 'execute')),
  0, 'ni anon ni authenticated pueden ejecutar las funciones nuevas');
select is(
  (select count(*)::int from pg_proc p
    where p.oid in ('private.cierre_diario_pendiente()'::regprocedure, 'private.limpiar_barras_minuto()'::regprocedure)
      and p.prosecdef and p.proconfig = array['search_path=""']),
  2, 'las dos son security definer con search_path vacío');

-- Retención de barras de minuto (CA-3) ----------------------------------------------------------
select pruebas.fijar_reloj('2026-11-05T15:00:00Z');

insert into public.barras_minuto (simbolo, momento, apertura, maximo, minimo, cierre, volumen) values
  ('QQQ',  '2026-11-04T15:00:00Z', 10, 11, 9, 10, 1),   -- ETF reciente: se queda
  ('QQQ',  '2026-10-29T15:00:00Z', 10, 11, 9, 10, 1),   -- ETF de 7 días: se borra
  ('QQQ',  '2026-10-30T15:00:00Z', 10, 11, 9, 10, 1),   -- ETF de 6 días: se borra
  ('QLD',  '2026-11-02T15:00:00Z', 10, 11, 9, 10, 1),   -- ETF de 3 días: se queda
  ('TQQQ', '2026-11-05T14:59:00Z', 10, 11, 9, 10, 1),   -- ETF reciente: se queda
  ('AAPL', '2026-11-05T14:00:00Z', 10, 11, 9, 10, 1),   -- acción sin posición: se borra
  ('MSFT', '2026-11-05T14:00:00Z', 10, 11, 9, 10, 1),   -- acción sin posición todavía: se borra
  ('NVDA', '2026-11-05T14:00:00Z', 10, 11, 9, 10, 1);   -- ídem

select is(private.limpiar_barras_minuto(), 5,
          'CA-3: borra las de más de 5 días y las de símbolos que no son ETF (sin tabla de posiciones)');
select is((select array_agg(simbolo || '@' || momento::date order by simbolo, momento) from public.barras_minuto),
          array['QLD@2026-11-02', 'QQQ@2026-11-04', 'TQQQ@2026-11-05'],
          'solo quedan las recientes de los ETF');
select is(private.limpiar_barras_minuto(), 0, 'repetir la limpieza no borra nada más');

-- Con la tabla de posiciones (docs/06 §5.5) se conservan las de los símbolos con posición abierta.
create table public.posiciones (simbolo text not null, cerrada_en timestamptz);
insert into public.posiciones (simbolo, cerrada_en) values
  ('MSFT', null), ('NVDA', '2026-11-04T20:00:00Z');
insert into public.barras_minuto (simbolo, momento, apertura, maximo, minimo, cierre, volumen) values
  ('MSFT', '2026-11-05T14:00:00Z', 10, 11, 9, 10, 1),   -- posición abierta reciente: se queda
  ('MSFT', '2026-10-28T14:00:00Z', 10, 11, 9, 10, 1),   -- posición abierta de 8 días: se borra
  ('NVDA', '2026-11-05T14:00:00Z', 10, 11, 9, 10, 1),   -- posición ya cerrada: se borra
  ('AAPL', '2026-11-05T14:00:00Z', 10, 11, 9, 10, 1);   -- sin posición: se borra
select is(private.limpiar_barras_minuto(), 3,
          'CA-3: con posiciones, borra lo viejo y lo de símbolos sin posición abierta');
select is((select array_agg(simbolo || '@' || momento::date order by simbolo, momento) from public.barras_minuto),
          array['MSFT@2026-11-05', 'QLD@2026-11-02', 'QQQ@2026-11-04', 'TQQQ@2026-11-05'],
          'quedan los ETF recientes y la barra reciente del símbolo con posición abierta');

-- La limpieza no toca las barras diarias ---------------------------------------------------------
select ok((select count(*) from public.barras_diarias where fecha < '2026-10-01') > 100,
          'las barras diarias (de un año) siguen intactas: se guardan siempre');

-- Trabajos de pg_cron (docs/05 §7) ---------------------------------------------------------------
select is((select schedule from cron.job where jobname = 'cierre_diario'), '*/10 * * * *',
          'el trabajo `cierre_diario` corre cada 10 minutos');
select is((select command from cron.job where jobname = 'cierre_diario'),
          $$select private.despertar_funcion('cierre-diario') where private.cierre_diario_pendiente()$$,
          'y despierta a cierre-diario solo si el cierre diario está pendiente');
select is((select count(*)::int from cron.job where jobname = 'cierre_diario'), 1,
          'hay un solo trabajo `cierre_diario`');
select is((select schedule from cron.job where jobname = 'limpieza'), '0 8 * * *',
          'el trabajo `limpieza` corre todos los días a las 08:00 UTC');
select is((select command from cron.job where jobname = 'limpieza'),
          $$select private.limpiar_barras_minuto()$$,
          'y aplica la retención de barras_minuto');
select is((select count(*)::int from cron.job where jobname = 'limpieza'), 1,
          'hay un solo trabajo `limpieza`');

select pruebas.fijar_reloj('2026-11-07T22:00:00Z');
select is(
  (select count(*)::int from (select 1 where private.cierre_diario_pendiente()) q),
  0, 'CA-4: un sábado la condición del trabajo no devuelve filas');

select pruebas.fijar_reloj(null);
select * from finish();
rollback;

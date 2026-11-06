-- HU-026 · Universo del NASDAQ-100 y carga histórica de barras.
-- Cubre CA-1 a CA-4 de backlog/E-04-datos-de-mercado/HU-026-*.md en la capa de base de datos:
-- tipo bolsillo, lista_blanca, barras_diarias y barras_minuto (RLS y permisos), la semilla del
-- universo, las barras sembradas por seed.sql y las funciones de private.
-- Todo corre dentro de una transacción que se deshace.
begin;
create extension if not exists pgtap with schema extensions;
select plan(85);

-- Tipo y tablas --------------------------------------------------------------------------------
select has_type('public', 'bolsillo', 'existe el tipo bolsillo');
select enum_has_labels('public', 'bolsillo', array['reserva', 'arriesgadas', 'usuarios'],
                       'bolsillo tiene los tres valores de docs/06 §3');
select has_table('public', 'lista_blanca', 'existe lista_blanca');
select has_table('public', 'barras_diarias', 'existe barras_diarias');
select has_table('public', 'barras_minuto', 'existe barras_minuto');
select col_is_pk('public', 'lista_blanca', array['bolsillo', 'simbolo'], 'lista_blanca: llave (bolsillo, simbolo)');
select col_is_pk('public', 'barras_diarias', array['simbolo', 'fecha'], 'barras_diarias: llave (simbolo, fecha)');
select col_is_pk('public', 'barras_minuto', array['simbolo', 'momento'], 'barras_minuto: llave (simbolo, momento)');
select col_type_is('public', 'barras_diarias', 'cierre', 'numeric(14,4)', 'los precios son numeric(14,4)');
select col_type_is('public', 'barras_diarias', 'volumen', 'bigint', 'el volumen es bigint');
select col_type_is('public', 'barras_minuto', 'momento', 'timestamp with time zone', 'barras_minuto.momento es timestamptz');

-- RLS y permisos (CA-4) ------------------------------------------------------------------------
select is(
  (select count(*)::int from pg_class
    where oid in ('public.lista_blanca'::regclass, 'public.barras_diarias'::regclass, 'public.barras_minuto'::regclass)
      and relrowsecurity),
  3, 'las tres tablas tienen RLS activo');
select policies_are('public', 'lista_blanca', array['lista_blanca_lectura'], 'lista_blanca solo tiene su política de lectura');
select policies_are('public', 'barras_diarias', array['barras_diarias_lectura'], 'barras_diarias solo tiene su política de lectura');
select policies_are('public', 'barras_minuto', array['barras_minuto_lectura'], 'barras_minuto solo tiene su política de lectura');
select is(
  (select count(*)::int from pg_policies
    where schemaname = 'public' and tablename in ('lista_blanca', 'barras_diarias', 'barras_minuto')
      and cmd <> 'SELECT'),
  0, 'ninguna política de escritura');
select is(
  (select count(*)::int from information_schema.role_table_grants
    where grantee = 'anon' and table_schema = 'public'
      and table_name in ('lista_blanca', 'barras_diarias', 'barras_minuto')),
  0, 'anon no tiene permisos sobre las tres tablas');
select is(
  (select array_agg(distinct privilege_type::text)
     from information_schema.role_table_grants
    where grantee = 'authenticated' and table_schema = 'public'
      and table_name in ('lista_blanca', 'barras_diarias', 'barras_minuto')),
  array['SELECT'::text], 'authenticated solo tiene SELECT');

-- anon no ve nada
set local role anon;
select throws_ok($$select * from public.lista_blanca$$, '42501', null, 'anon no puede leer lista_blanca');
select throws_ok($$select * from public.barras_diarias$$, '42501', null, 'anon no puede leer barras_diarias');
reset role;

-- Una persona autenticada lee y no puede escribir directo
set local role authenticated;
select cmp_ok((select count(*)::int from public.lista_blanca), '>', 0, 'authenticated lee lista_blanca');
select cmp_ok((select count(*)::int from public.barras_diarias), '>', 0, 'authenticated lee barras_diarias');
select is((select count(*)::int from public.barras_minuto), 0, 'authenticated lee barras_minuto (vacía)');
select throws_ok($$insert into public.lista_blanca (bolsillo, simbolo, nombre) values ('usuarios', 'ZZZ', 'Prueba')$$,
                 '42501', null, 'authenticated no puede insertar en lista_blanca');
select throws_ok($$update public.lista_blanca set activo = false$$,
                 '42501', null, 'authenticated no puede actualizar lista_blanca');
select throws_ok($$delete from public.lista_blanca$$,
                 '42501', null, 'authenticated no puede borrar de lista_blanca');
select throws_ok($$insert into public.barras_diarias values ('ZZZ', '2026-01-02', 1, 1, 1, 1, 1)$$,
                 '42501', null, 'authenticated no puede insertar en barras_diarias');
select throws_ok($$update public.barras_diarias set cierre = 1$$,
                 '42501', null, 'authenticated no puede actualizar barras_diarias');
select throws_ok($$delete from public.barras_diarias$$,
                 '42501', null, 'authenticated no puede borrar de barras_diarias');
select throws_ok($$insert into public.barras_minuto values ('ZZZ', now(), 1, 1, 1, 1, 1)$$,
                 '42501', null, 'authenticated no puede insertar en barras_minuto');
reset role;

-- CA-1: la lista blanca recién creada ---------------------------------------------------------
select is(
  (select array_agg(simbolo order by simbolo) from public.lista_blanca where bolsillo = 'usuarios'),
  array['QLD', 'QQQ'], 'Usuarios tiene QLD y QQQ');
select is((select count(*)::int from public.lista_blanca where bolsillo = 'arriesgadas'), 102,
          'Arriesgadas tiene TQQQ y 101 acciones');
select is((select count(*)::int from public.lista_blanca where bolsillo = 'arriesgadas' and simbolo = 'TQQQ'), 1,
          'Arriesgadas tiene TQQQ');
select is((select count(*)::int from public.lista_blanca where en_nasdaq100), 101,
          '101 símbolos son componentes del NASDAQ-100');
select is((select count(*)::int from public.lista_blanca where bolsillo = 'reserva'), 0,
          'la Reserva no tiene lista blanca');
select is(
  (select count(*)::int from public.lista_blanca
    where en_nasdaq100 and (bolsillo <> 'arriesgadas' or nullif(trim(nombre), '') is null or nullif(trim(sector), '') is null)),
  0, 'los componentes están en Arriesgadas y traen nombre y sector');
select is(
  (select count(*)::int from public.lista_blanca where not en_nasdaq100 and sector is not null),
  0, 'los ETF no llevan sector');
select is(
  (select array_agg(simbolo order by simbolo) from public.lista_blanca where not en_nasdaq100),
  array['QLD', 'QQQ', 'TQQQ'], 'los ETF son QLD, QQQ y TQQQ');
select is(
  (select count(*)::int from public.lista_blanca
    where sector not in ('Communication Services', 'Consumer Discretionary', 'Consumer Staples', 'Energy',
                         'Financials', 'Health Care', 'Industrials', 'Information Technology', 'Materials',
                         'Real Estate', 'Utilities')),
  0, 'los sectores son de los once GICS');
select is(
  (select count(*)::int from public.lista_blanca
    where not activo or fraccionable is not null or negociable is not null or sincronizado_en is not null
       or actualizado_por is not null),
  0, 'la semilla trae todo activo y sin atributos sincronizados');
select is(
  (select count(distinct sector)::int from public.lista_blanca), 10, 'la semilla usa diez sectores');
select throws_ok($$insert into public.lista_blanca (bolsillo, simbolo, nombre) values ('reserva', 'AAPL', 'Apple')$$,
                 '23514', null, 'la Reserva no puede tener lista blanca (check)');
select throws_ok($$insert into public.lista_blanca (bolsillo, simbolo, nombre) values ('usuarios', 'QQQ', 'Otra vez')$$,
                 '23505', null, 'no se repite un símbolo en un bolsillo');

-- Barras sembradas por seed.sql (docs/15 §3) -----------------------------------------------------
select is((select count(distinct simbolo)::int from public.barras_diarias), 104,
          'seed.sql trae barras de los 104 símbolos');
select is(
  (select count(*)::int from (select simbolo from public.barras_diarias group by simbolo having count(*) <> 260) t),
  0, 'cada símbolo tiene 260 días hábiles');
select is((select min(fecha) from public.barras_diarias), date '2025-11-03', 'las barras empiezan el 2025-11-03');
select is((select max(fecha) from public.barras_diarias), date '2026-10-30', 'las barras terminan el 2026-10-30');
select is((select count(*)::int from public.barras_diarias where extract(isodow from fecha) > 5), 0,
          'solo hay barras de lunes a viernes');
select is(
  (select count(distinct b.simbolo)::int
     from public.barras_diarias b join public.lista_blanca l using (simbolo)),
  104, 'los símbolos de las barras son los de la lista blanca');
-- Valores conocidos: los mismos de simulado_test.ts. Si no coinciden, el algoritmo de seed.sql y el del
-- proveedor simulado se separaron (specs/026-universo-y-carga-historica/contracts/mercado.md).
select is(
  (select (apertura, maximo, minimo, cierre, volumen)::text from public.barras_diarias
    where simbolo = 'QQQ' and fecha = '2026-06-01'),
  '(389.8220,390.4826,387.4463,388.5635,1156260)', 'QQQ 2026-06-01 coincide con el simulado');
select is(
  (select (apertura, maximo, minimo, cierre, volumen)::text from public.barras_diarias
    where simbolo = 'AAPL' and fecha = '2026-06-01'),
  '(128.0763,129.3337,126.8377,127.0639,919189)', 'AAPL 2026-06-01 coincide con el simulado');
select is(
  (select (apertura, maximo, minimo, cierre, volumen)::text from public.barras_diarias
    where simbolo = 'TQQQ' and fecha = '2025-11-03'),
  '(62.3450,62.6551,60.4177,60.8589,1467833)', 'TQQQ 2025-11-03 coincide con el simulado');

-- La restricción de coherencia de las barras ----------------------------------------------------
select throws_ok($$insert into public.barras_diarias values ('ZZZ', '2026-01-02', 10, 9, 8, 10, 1)$$,
                 '23514', null, 'máximo menor que la apertura se rechaza');
select throws_ok($$insert into public.barras_diarias values ('ZZZ', '2026-01-02', 10, 11, 12, 10, 1)$$,
                 '23514', null, 'mínimo mayor que la apertura se rechaza');
select throws_ok($$insert into public.barras_diarias values ('ZZZ', '2026-01-02', 0, 0, 0, 0, 1)$$,
                 '23514', null, 'precios en cero se rechazan');
select throws_ok($$insert into public.barras_diarias values ('ZZZ', '2026-01-02', 10, 11, 9, 10, -1)$$,
                 '23514', null, 'volumen negativo se rechaza');

-- Funciones de private: existen y están cerradas a la API ---------------------------------------
select has_function('private', 'simbolos_del_universo', array[]::text[], 'existe private.simbolos_del_universo()');
select has_function('private', 'simbolos_sin_historia', array['date'], 'existe private.simbolos_sin_historia(date)');
select has_function('private', 'guardar_barras_diarias', array['jsonb'], 'existe private.guardar_barras_diarias(jsonb)');
select is(
  (select count(*)::int from pg_proc
    where oid in ('private.simbolos_del_universo()'::regprocedure, 'private.simbolos_sin_historia(date)'::regprocedure,
                  'private.guardar_barras_diarias(jsonb)'::regprocedure)
      and prosecdef and proconfig = array['search_path=""']),
  3, 'las tres son security definer con search_path vacío');
select is(
  (select count(*)::int from pg_proc
    where oid in ('private.simbolos_del_universo()'::regprocedure, 'private.simbolos_sin_historia(date)'::regprocedure,
                  'private.guardar_barras_diarias(jsonb)'::regprocedure)
      and (has_function_privilege('anon', oid, 'execute') or has_function_privilege('authenticated', oid, 'execute'))),
  0, 'anon y authenticated no pueden ejecutarlas');

-- private.simbolos_del_universo() ------------------------------------------------------------------
select is((select count(*)::int from private.simbolos_del_universo()), 104, 'el universo tiene 104 símbolos');
select is(
  (select array_agg(simbolo) from private.simbolos_del_universo() where simbolo in ('QLD', 'QQQ', 'TQQQ', 'AAPL')),
  array['AAPL', 'QLD', 'QQQ', 'TQQQ'], 'el universo incluye los ETF y las acciones, ordenado');
update public.lista_blanca set activo = false where simbolo = 'AAPL';
select is((select count(*)::int from private.simbolos_del_universo() where simbolo = 'AAPL'), 0,
          'un símbolo inactivo sale del universo');
update public.lista_blanca set activo = false where simbolo = 'QQQ';
select is((select count(*)::int from private.simbolos_del_universo() where simbolo = 'QQQ'), 1,
          'QQQ se ingiere siempre, aunque no esté activo en ningún bolsillo');
select is((select count(*)::int from private.simbolos_del_universo()), 104 - 1,
          'solo salió AAPL; QQQ se queda');
update public.lista_blanca set activo = true where simbolo in ('AAPL', 'QQQ');

-- private.simbolos_sin_historia(desde) ---------------------------------------------------------------
-- La semilla solo trae un año (desde 2025-11-03): con una ventana de dos años, todos faltan.
select is((select count(*)::int from private.simbolos_sin_historia('2024-11-05')), 104,
          'con una ventana de dos años, los 104 símbolos no tienen historia completa');
select is((select count(*)::int from private.simbolos_sin_historia('2025-11-03')), 0,
          'con una ventana de un año, ninguno falta');
-- Una barra dentro de los primeros 7 días de la ventana basta.
insert into public.barras_diarias values ('AAPL', '2024-11-12', 10, 11, 9, 10, 100);
select is((select count(*)::int from private.simbolos_sin_historia('2024-11-05') where simbolo = 'AAPL'), 0,
          'una barra a 7 días del inicio de la ventana completa la historia');
insert into public.barras_diarias values ('MSFT', '2024-11-13', 10, 11, 9, 10, 100);
select is((select count(*)::int from private.simbolos_sin_historia('2024-11-05') where simbolo = 'MSFT'), 1,
          'una barra a 8 días del inicio no la completa');
select throws_ok($$select * from private.simbolos_sin_historia(null)$$, 'P0001',
                 'simbolos_sin_historia: desde es obligatorio', 'desde es obligatorio');

-- private.guardar_barras_diarias(datos) --------------------------------------------------------------
select is(
  private.guardar_barras_diarias(
    '[{"simbolo":"QQQ","fecha":"2024-11-05","apertura":400.1,"maximo":402.2,"minimo":399.9,"cierre":401.5,"volumen":1200},
      {"simbolo":"QQQ","fecha":"2024-11-06","apertura":401.5,"maximo":405,"minimo":401,"cierre":404.25,"volumen":1500}]'::jsonb),
  2, 'guarda dos barras nuevas y devuelve 2 (CA-2)');
select is((select count(*)::int from public.barras_diarias where simbolo = 'QQQ'), 262,
          'quedaron guardadas: 260 sembradas + 2');
select is(
  private.guardar_barras_diarias(
    '[{"simbolo":"QQQ","fecha":"2024-11-05","apertura":400.1,"maximo":402.2,"minimo":399.9,"cierre":401.5,"volumen":1200},
      {"simbolo":"QQQ","fecha":"2024-11-06","apertura":401.5,"maximo":405,"minimo":401,"cierre":404.25,"volumen":1500}]'::jsonb),
  0, 'repetir la carga no guarda nada (CA-3)');
select is((select count(*)::int from public.barras_diarias where simbolo = 'QQQ'), 262,
          'repetir la carga no duplica barras (CA-3)');
select is(
  private.guardar_barras_diarias(
    '[{"simbolo":"QQQ","fecha":"2024-11-05","apertura":1,"maximo":2,"minimo":1,"cierre":2,"volumen":9}]'::jsonb),
  0, 'una barra que ya existe no se reemplaza');
select is((select cierre from public.barras_diarias where simbolo = 'QQQ' and fecha = '2024-11-05'), 401.5000,
          'la barra existente conserva sus valores');
select is(
  private.guardar_barras_diarias(
    '[{"simbolo":"QQQ","fecha":"2024-11-07","apertura":1,"maximo":2,"minimo":1,"cierre":2,"volumen":9},
      {"simbolo":"QQQ","fecha":"2024-11-07","apertura":1,"maximo":2,"minimo":1,"cierre":2,"volumen":9}]'::jsonb),
  1, 'dos barras iguales en el mismo arreglo guardan una sola');
select is(private.guardar_barras_diarias('[]'::jsonb), 0, 'un arreglo vacío no guarda nada');
select throws_ok($$select private.guardar_barras_diarias('{"simbolo":"QQQ"}'::jsonb)$$, 'P0001',
                 'guardar_barras_diarias: se esperaba un arreglo', 'un objeto no es un arreglo');
select throws_ok($$select private.guardar_barras_diarias(null)$$, 'P0001',
                 'guardar_barras_diarias: se esperaba un arreglo', 'nulo no es un arreglo');
select throws_ok(
  $$select private.guardar_barras_diarias(
      '[{"simbolo":"QQQ","fecha":"2024-11-08","apertura":1,"maximo":2,"minimo":1,"cierre":2,"volumen":9},
        {"simbolo":"QQQ","fecha":"2024-11-11","apertura":1,"maximo":1,"minimo":1,"cierre":3,"volumen":9}]'::jsonb)$$,
  '23514', null, 'una barra incoherente hace fallar el lote');
select is((select count(*)::int from public.barras_diarias where simbolo = 'QQQ' and fecha = '2024-11-08'), 0,
          'el lote con una barra incoherente no guarda ninguna');
select throws_ok(
  $$select private.guardar_barras_diarias(
      '[{"simbolo":"QQQ","fecha":"2024-11-12","apertura":1,"maximo":2,"minimo":1,"cierre":2,"volumen":9.5}]'::jsonb)$$,
  '22P02', null, 'un volumen con decimales no se acepta');
select throws_ok(
  $$select private.guardar_barras_diarias('[{"simbolo":"QQQ","fecha":"2024-11-12"}]'::jsonb)$$,
  '23502', null, 'una barra sin precios no se acepta');

select * from finish();
rollback;

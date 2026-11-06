-- TT-05 · private.ahora() y el esquema pruebas (reloj, escenarios y push simulados).
-- Criterios de terminado de backlog/E-01-cimientos-y-calidad-continua/TT-05-*.md.
-- El esquema pruebas lo crea seed.sql, que `supabase db reset` aplica antes de estas pruebas.
-- Todo corre dentro de una transacción que se deshace, incluido el DROP SCHEMA del final.
begin;
create extension if not exists pgtap with schema extensions;
select plan(33);

-- private.ahora(): función interna, cerrada a la API ----------------------------------------
select has_function('private', 'ahora', array[]::text[], 'existe private.ahora()');
select ok(not has_function_privilege('anon', 'private.ahora()', 'execute'),
          'anon no puede ejecutar private.ahora()');
select ok(not has_function_privilege('authenticated', 'private.ahora()', 'execute'),
          'authenticated no puede ejecutar private.ahora()');
select is((select prosecdef from pg_proc where oid = 'private.ahora()'::regprocedure), true,
          'private.ahora() es security definer');
select is((select proconfig from pg_proc where oid = 'private.ahora()'::regprocedure),
          array['search_path=""'], 'private.ahora() fija search_path vacío');

-- El esquema pruebas existe (lo creó seed.sql) y está cerrado a la API ----------------------
select has_schema('pruebas', 'seed.sql creó el esquema pruebas');
select has_table('pruebas', 'reloj', 'existe pruebas.reloj');
select has_table('pruebas', 'escenarios', 'existe pruebas.escenarios');
select has_table('pruebas', 'push_simulados', 'existe pruebas.push_simulados');
select ok(not has_schema_privilege('anon', 'pruebas', 'usage'), 'anon no puede usar el esquema pruebas');
select ok(not has_schema_privilege('authenticated', 'pruebas', 'usage'),
          'authenticated no puede usar el esquema pruebas');
select is(
  (select count(*)::int
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'pruebas' and c.relkind = 'r'
      and (has_table_privilege('anon', c.oid, 'select,insert,update,delete')
        or has_table_privilege('authenticated', c.oid, 'select,insert,update,delete'))),
  0, 'anon y authenticated no tienen permisos sobre ninguna tabla de pruebas');
select is(
  (select count(*)::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'pruebas'
      and (has_function_privilege('anon', p.oid, 'execute')
        or has_function_privilege('authenticated', p.oid, 'execute'))),
  0, 'anon y authenticated no pueden ejecutar ninguna función de pruebas');
select is(
  (select count(*)::int
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'pruebas' and c.relkind = 'r' and not c.relrowsecurity),
  0, 'todas las tablas de pruebas tienen RLS activo');

-- Reloj: sin hora fijada es la hora real -----------------------------------------------------
select is((select count(*)::int from pruebas.reloj), 1, 'pruebas.reloj tiene exactamente una fila');
select is(private.ahora(), now(), 'sin hora fijada, private.ahora() devuelve now()');

-- Reloj: con hora fijada ----------------------------------------------------------------------
select is(pruebas.fijar_reloj('2027-03-15 14:30:00+00'), '2027-03-15 14:30:00+00'::timestamptz,
          'fijar_reloj devuelve la hora que queda vigente');
select is(private.ahora(), '2027-03-15 14:30:00+00'::timestamptz,
          'private.ahora() devuelve la hora fijada con fijar_reloj');
select pruebas.fijar_reloj('2026-12-31 23:59:59+00');
select is(private.ahora(), '2026-12-31 23:59:59+00'::timestamptz,
          'fijar_reloj de nuevo reemplaza la hora fijada');
select is(pruebas.fijar_reloj(null), now(), 'fijar_reloj(null) devuelve la hora real');
select is(private.ahora(), now(), 'con fijar_reloj(null), private.ahora() vuelve a now()');

-- Escenarios de los proveedores simulados --------------------------------------------------------
select pruebas.elegir_escenario('broker', 'llenado_parcial');
select is((select escenario from pruebas.escenarios where proveedor = 'broker'), 'llenado_parcial',
          'elegir_escenario guarda el escenario del proveedor');
select pruebas.elegir_escenario('broker', 'rechazo');
select is((select escenario from pruebas.escenarios where proveedor = 'broker'), 'rechazo',
          'elegir_escenario reemplaza el escenario anterior');
select is((select count(*)::int from pruebas.escenarios), 1, 'hay una sola fila por proveedor');
select pruebas.elegir_escenario('broker', null);
select is((select count(*)::int from pruebas.escenarios), 0,
          'elegir_escenario con nulo vuelve al comportamiento normal');
select throws_ok($$select pruebas.elegir_escenario('banco', 'rechazo')$$, '23514', null,
                 'rechaza un proveedor que no es una integración');
select throws_ok($$select pruebas.elegir_escenario('broker', '')$$, '23514', null,
                 'rechaza un escenario vacío');

-- Push simulados: la hora de creación sale del reloj controlable -------------------------------
select pruebas.fijar_reloj('2027-01-10 09:00:00+00');
insert into pruebas.push_simulados (token_fcm, titulo, cuerpo, datos)
values ('token-de-prueba', 'Orden llenada', 'Se llenó tu orden de AAPL', '{"referencia_id": "x"}');
select is((select creado_en from pruebas.push_simulados), '2027-01-10 09:00:00+00'::timestamptz,
          'push_simulados.creado_en usa private.ahora()');
select is((select datos ->> 'referencia_id' from pruebas.push_simulados), 'x',
          'push_simulados guarda los datos de la notificación');
select throws_ok($$insert into pruebas.push_simulados (token_fcm, titulo) values ('t', 'sin cuerpo')$$,
                 '23502', null, 'push_simulados exige el cuerpo');

-- Sin el esquema pruebas (la nube), private.ahora() es la hora real ----------------------------
select pruebas.fijar_reloj('2000-01-01 00:00:00+00');
select is(private.ahora(), '2000-01-01 00:00:00+00'::timestamptz, 'con el reloj fijado devuelve esa hora');
drop schema pruebas cascade;
select hasnt_schema('pruebas', 'se quitó el esquema pruebas');
select is(private.ahora(), now(),
          'sin el esquema pruebas, private.ahora() devuelve now() sin error');

select * from finish();
rollback;

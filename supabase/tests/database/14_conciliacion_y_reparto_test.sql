-- HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25.
-- Criterios: CA-1 a CA-5 (backlog/E-03-fondo-y-libro-contable/HU-015-*.md). Reglas: docs/02 RN-07 a RN-09,
-- docs/08 §4 y §7.6, docs/10 §4.1 y §8, docs/12 CB-11 y CB-12.
-- El flujo completo con la Edge Function y el broker simulado lo cubre el manejador de `conciliacion`
-- (deno test); aquí se prueba la parte de base de datos.
begin;
create extension if not exists pgtap with schema extensions;
select plan(56);

set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario');
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador', 'activo', null, null);

-- Ayudas -----------------------------------------------------------------------------------------
create function pg_temp.saldo(p_tipo text) returns numeric
language sql as $$ select efectivo from public.subcuentas where tipo = p_tipo::public.tipo_subcuenta $$;
create function pg_temp.estado_aporte(p_monto numeric) returns text
language sql as $$ select estado::text from public.movimientos_capital where monto = p_monto $$;
create function pg_temp.eventos(p_topico text, p_evento text, p_estado text) returns int
language sql as $$
  select count(*)::int from realtime.messages
   where topic = p_topico and event = p_evento and private and payload->>'estado' is not distinct from p_estado
$$;
create function pg_temp.registrar(p_monto numeric) returns void
language plpgsql as $$
begin
  set local role authenticated;
  set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
  perform public.registrar_aporte(p_monto, 'prueba', null);
  reset role;
end;
$$;

-- Estructura y permisos -----------------------------------------------------------------------------
select has_table('public', 'conciliaciones', 'existe conciliaciones');
select has_type('public', 'resultado_conciliacion', 'existe resultado_conciliacion');
select is((select array_agg(e.enumlabel::text order by e.enumsortorder) from pg_enum e
            where e.enumtypid = 'public.resultado_conciliacion'::regtype),
          array['ok', 'diferencia_menor', 'descuadre_critico'], 'el tipo tiene los tres resultados de docs/06 §2');
select ok(not has_table_privilege('authenticated', 'public.conciliaciones', 'insert')
          and not has_table_privilege('authenticated', 'public.conciliaciones', 'update')
          and not has_table_privilege('service_role', 'public.conciliaciones', 'insert')
          and not has_table_privilege('anon', 'public.conciliaciones', 'select'),
          'la API no escribe conciliaciones y anon no la lee');
select ok(not has_function_privilege('authenticated', 'private.confirmar_aporte(uuid)', 'execute')
          and not has_function_privilege('service_role', 'private.confirmar_aporte(uuid)', 'execute')
          and not has_function_privilege('authenticated', 'private.registrar_conciliacion(numeric, jsonb)', 'execute')
          and not has_function_privilege('service_role', 'private.registrar_conciliacion(numeric, jsonb)', 'execute'),
          'nadie por la API confirma un aporte ni registra una conciliación (RN-07)');
select ok((select array_to_string(proconfig, ',') from pg_proc where oid = 'private.confirmar_aporte(uuid)'::regprocedure)
            like '%search_path=""%'
          and (select array_to_string(proconfig, ',') from pg_proc where oid = 'private.registrar_conciliacion(numeric, jsonb)'::regprocedure)
            like '%search_path=""%', 'las dos fijan search_path vacío');
select is((select schedule from cron.job where jobname = 'conciliacion'), '* * * * *', 'el trabajo conciliacion corre cada minuto');
select ok((select command from cron.job where jobname = 'conciliacion') like '%conciliacion_pendiente%',
          'el trabajo pregunta a SQL si le toca');
select is((select count(*)::int from public.conciliaciones), 0, 'sin conciliaciones al empezar');

-- Entradas inválidas ---------------------------------------------------------------------------------
select throws_ok($$select private.registrar_conciliacion(null)$$, '22023', null, 'el efectivo del broker no puede ser nulo');
select throws_ok($$select private.registrar_conciliacion(-1)$$, '22023', null, 'ni negativo');

-- Sin aportes: el broker con más efectivo que el libro es excedente (ok) ----------------------------
select is((select (resultado, efectivo_libro, efectivo_broker, diferencia_efectivo, accion_tomada)::text
             from private.registrar_conciliacion(100000)),
          '(ok,0.00,100000.00,100000.00,ninguna)',
          'sin aportes, el efectivo de la cuenta paper es excedente no asignado: ok y no se usa (docs/10 §4.1)');
select is(pg_temp.saldo('reserva') + pg_temp.saldo('arriesgadas') + pg_temp.saldo('usuarios_comun'), 0::numeric,
          'el excedente no entra al libro');
select is(pg_temp.eventos('supervision', 'conciliacion', 'ok'), 1, 'se publica el evento conciliacion en supervision');

-- CA-3 / CB-11: el broker no tiene el efectivo --------------------------------------------------------
select pg_temp.registrar(10000);
select is(private.conciliacion_pendiente(), false, 'recién conciliado, el trabajo espera conciliacion.minutos_entre');
update public.conciliaciones set ejecutada_en = now() - interval '10 minutes';
select is(private.conciliacion_pendiente(), true, 'pasado el intervalo y con un aporte registrado esperando, el trabajo corre aunque el mercado esté cerrado');
select is((select (resultado, accion_tomada)::text from private.registrar_conciliacion(9999.99)),
          '(ok,ninguna)', 'CA-3: el broker con 9.999,99 no cubre el aporte de 10.000: nada se confirma');
select is(pg_temp.estado_aporte(10000), 'registrado', 'CA-3 (CB-11): el aporte sigue registrado');
select is(pg_temp.saldo('reserva'), 0::numeric, 'CA-3: el libro no cambia');
select is((select count(*)::int from public.movimientos where tipo = 'aporte'), 0, 'CA-3: ningún movimiento aporte');

-- CA-3: a la hora se alerta --------------------------------------------------------------------------
select is((select count(*)::int from private.aportes_sin_confirmar()), 0, 'recién registrado: aún no cumple la hora');
update public.movimientos_capital set registrado_en = now() - interval '61 minutes' where monto = 10000;
select is((select count(*)::int from private.aportes_sin_confirmar()), 1, 'CA-3: pasada la hora, el aporte aparece como sin confirmar');
select is((select nota from private.registrar_conciliacion(9999.99)),
          '1 aporte(s) registrado(s) sin confirmar desde hace más de una hora',
          'CA-3: la conciliación deja constancia del aporte atrasado');

-- CA-1: el broker cubre el aporte ----------------------------------------------------------------------
select is((select (resultado, efectivo_libro, efectivo_broker, diferencia_efectivo, accion_tomada)::text
             from private.registrar_conciliacion(10000)),
          '(ok,0.00,10000.00,10000.00,aporte_confirmado)', 'CA-1: con 10.000 en la cuenta paper corre la conciliación y confirma');
select is(pg_temp.estado_aporte(10000), 'confirmado', 'CA-1: el aporte pasa a confirmado');
select is((select (pg_temp.saldo('externa'), pg_temp.saldo('reserva'), pg_temp.saldo('arriesgadas'), pg_temp.saldo('usuarios_comun'))::text),
          '(-10000.00,5000.00,2500.00,2500.00)', 'CA-1: externa −10.000, reserva +5.000, arriesgadas +2.500, usuarios_comun +2.500');
select is((select count(*)::int from public.movimientos where tipo = 'aporte'), 1, 'un solo movimiento aporte');
select is((select movimiento_id from public.movimientos_capital where monto = 10000),
          (select id from public.movimientos where tipo = 'aporte'), 'el aporte guarda su movimiento del libro');
select ok((select confirmado_en is not null from public.movimientos_capital where monto = 10000), 'guarda cuándo se confirmó');
select is((select (referencia_tabla, referencia_id)::text from public.movimientos where tipo = 'aporte'),
          '(movimientos_capital,' || (select id from public.movimientos_capital where monto = 10000) || ')',
          'el movimiento apunta al aporte');
select is((select creado_por from public.movimientos where tipo = 'aporte'), null, 'lo crea el sistema, no una persona');

-- CA-4 (parte 1): los porcentajes vigentes quedan guardados ------------------------------------------
select is((select parametros from public.movimientos where tipo = 'aporte'),
          '{"reparto": {"pct_reserva": 50, "pct_usuarios": 25, "pct_arriesgadas": 25}}'::jsonb,
          'CA-4: el movimiento guarda los porcentajes con que se repartió');

-- CA-5: bitácora y eventos -------------------------------------------------------------------------------
select is((select (accion, entidad, actor_id, origen)::text from public.auditoria where accion = 'capital.aporte_confirmado'),
          '(capital.aporte_confirmado,movimientos_capital,,sistema)', 'CA-5: se registra capital.aporte_confirmado por el sistema');
select is((select entidad_id from public.auditoria where accion = 'capital.aporte_confirmado'),
          (select id::text from public.movimientos_capital where monto = 10000), 'la bitácora apunta al aporte');
select is(pg_temp.eventos('admin', 'capital', 'confirmado'), 1, 'CA-5: el evento capital sale con el estado confirmado');
select is(pg_temp.eventos('fondo', 'resumen_cambio', null), 1, 'CA-5: se publica resumen_cambio en el canal fondo');
select ok(not exists (select 1 from realtime.messages m where m.topic = 'fondo' and m.event = 'resumen_cambio'
                         and m.payload::text ~ '[0-9]{4,}\.[0-9]'), 'el evento no lleva montos');
select throws_ok($$select private.confirmar_aporte((select id from public.movimientos_capital where monto = 10000))$$,
                 'P0001', 'ESTADO_INVALIDO', 'un aporte ya confirmado no se confirma de nuevo');
select throws_ok($$select private.confirmar_aporte(gen_random_uuid())$$, 'P0001', 'NO_EXISTE', 'un aporte inexistente responde NO_EXISTE');

-- CA-2 / CB-12: 1.000,03 -----------------------------------------------------------------------------------
select pg_temp.registrar(1000.03);
select private.registrar_conciliacion(11000.03);
select is(pg_temp.estado_aporte(1000.03), 'confirmado', 'CA-2: el aporte de 1.000,03 se confirma');
select is((select array_agg(a.monto order by s.tipo) from public.asientos a
             join public.subcuentas s on s.id = a.subcuenta_id
            where a.movimiento_id = (select movimiento_id from public.movimientos_capital where monto = 1000.03)),
          array[500.03, 250.00, 250.00, -1000.03]::numeric[],
          'CA-2 (CB-12): reserva 500,03, arriesgadas 250,00, usuarios 250,00 y externa −1.000,03');
select is(pg_temp.saldo('reserva'), 5500.03, 'la reserva recibe el resto');

-- Tolerancia y descuadre ----------------------------------------------------------------------------------
select pg_temp.registrar(50);
select is((select (resultado, accion_tomada)::text from private.registrar_conciliacion(11000.00)),
          '(diferencia_menor,ninguna)', 'al broker le faltan 0,03: diferencia_menor, dentro de la tolerancia de 1,00');
select is((select (resultado, diferencia_efectivo)::text from private.registrar_conciliacion(10900.03)),
          '(descuadre_critico,-100.00)', 'al broker le faltan 100,00: descuadre_critico');
select is(pg_temp.estado_aporte(50), 'registrado', 'ni diferencia menor ni descuadre confirman aportes');
select is((select trading_activo from public.fondos), false, 'esta versión no cambia los interruptores (la pausa llega con HU-080)');
select is(pg_temp.eventos('supervision', 'conciliacion', 'descuadre_critico'), 1, 'el descuadre se publica como evento conciliacion');

-- CA-4 (parte 2): porcentajes vigentes al confirmar -----------------------------------------------------------
update public.parametros set valor = case clave
    when 'reparto.pct_reserva' then '60'::jsonb
    when 'reparto.pct_arriesgadas' then '20'::jsonb
    else '20'::jsonb end
 where clave in ('reparto.pct_reserva', 'reparto.pct_arriesgadas', 'reparto.pct_usuarios');
select private.registrar_conciliacion(11050.03);
select is((select (pg_temp.saldo('reserva'), pg_temp.saldo('arriesgadas'), pg_temp.saldo('usuarios_comun'))::text),
          '(5530.03,2760.00,2760.00)', 'CA-4: el aporte de 50 se repartió 60/20/20 (30 / 10 / 10), no 50/25/25');
select is((select parametros -> 'reparto' ->> 'pct_reserva' from public.movimientos
            where referencia_id = (select id from public.movimientos_capital where monto = 50)),
          '60', 'CA-4: guarda el 60 % vigente');

-- Varios aportes: del más antiguo al más nuevo, mientras el efectivo alcance --------------------------------------
update public.parametros set valor = case clave
    when 'reparto.pct_reserva' then '50'::jsonb else '25'::jsonb end
 where clave in ('reparto.pct_reserva', 'reparto.pct_arriesgadas', 'reparto.pct_usuarios');
select pg_temp.registrar(200);
select pg_temp.registrar(300);
update public.movimientos_capital set registrado_en = now() - interval '2 minutes' where monto = 200;
-- Libro: 11050,03 + aportes 200 y 300 → el broker cubre 200 pero no 300.
select is((select accion_tomada from private.registrar_conciliacion(11250.03)), 'aporte_confirmado', 'confirma el que cubre');
select is((pg_temp.estado_aporte(200), pg_temp.estado_aporte(300))::text, '(confirmado,registrado)',
          'confirma el más antiguo y deja el que el efectivo no cubre');
select is((select accion_tomada from private.registrar_conciliacion(11250.03)), 'ninguna', 'la siguiente no encuentra efectivo para el de 300');
select private.registrar_conciliacion(11550.03);
select is(pg_temp.estado_aporte(300), 'confirmado', 'con el efectivo, el segundo también se confirma');

-- Lectura por rol ---------------------------------------------------------------------------------------------------
select is((select count(*)::int > 0 from public.conciliaciones), true, 'postgres lee las conciliaciones');
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is((select count(*)::int > 0 from public.conciliaciones), true, 'el Administrador lee las conciliaciones');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select count(*)::int from public.conciliaciones), 0, 'el Usuario no las ve');
reset role;

select * from finish();
rollback;

-- HU-013 · Libro contable de doble partida: estructura, datos iniciales, registrar_movimiento, invariantes
-- L1 a L5, saldos no negativos, inmutabilidad, lectura por rol y verificación diaria.
-- Criterios: CA-1 a CA-5 (backlog/E-03-fondo-y-libro-contable/HU-013-*.md). Reglas: docs/06 §4 y §7,
-- docs/03 §4.3, docs/02 RN-01, RN-04, RN-05 y RN-06. El E2E-04 ejercita el libro de punta a punta.
begin;
create extension if not exists pgtap with schema extensions;
select plan(68);

-- Cuentas de prueba: 0001 y 0006 usuarios · 0002 analista · 0003 administrador · 0004 administrador suspendido.
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test'),
  ('00000000-0000-4000-8000-000000000006', 'otro@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario'),
  ('00000000-0000-4000-8000-000000000006', 'otro@prueba.test', 'Otro usuario', 'usuario');
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista de prueba', 'analista', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test', 'Suspendido de prueba', 'administrador', 'suspendido', now(), null);

-- Ayuda: id de una subcuenta fija por su tipo.
create function pg_temp.sc(p_tipo text) returns uuid language sql as
  $$ select id from public.subcuentas where tipo = p_tipo::public.tipo_subcuenta $$;
create function pg_temp.a(p_sub uuid, p_concepto text, p_monto numeric) returns jsonb language sql as
  $$ select jsonb_build_object('subcuenta_id', p_sub, 'concepto', p_concepto, 'monto', p_monto) $$;
grant execute on function pg_temp.sc(text), pg_temp.a(uuid, text, numeric) to authenticated, service_role;

-- Estructura (docs/06 §3 y §4) --------------------------------------------------------------------
select enum_has_labels('public', 'bolsillo', array['reserva', 'arriesgadas', 'usuarios'], 'bolsillo tiene sus tres valores');
select enum_has_labels('public', 'tipo_subcuenta', array['reserva', 'arriesgadas', 'usuarios_comun', 'cupo', 'externa', 'resultados'],
                       'tipo_subcuenta tiene sus seis valores');
select enum_has_labels('public', 'estado_subcuenta', array['abierta', 'cerrada'], 'estado_subcuenta tiene sus dos valores');
select enum_has_labels('public', 'concepto_asiento', array['efectivo', 'invertido'], 'concepto_asiento tiene sus dos valores');
select enum_has_labels('public', 'tipo_movimiento', array['aporte', 'retiro', 'asignacion_cupo', 'reduccion_cupo', 'cierre_cupo',
                       'compra', 'venta', 'reparto_ganancia', 'rebalanceo', 'ajuste'], 'tipo_movimiento tiene sus diez valores');
select columns_are('public', 'subcuentas', array['id', 'fondo_id', 'tipo', 'bolsillo', 'usuario_id', 'efectivo', 'invertido',
                   'retenido', 'estado', 'version', 'creado_en'], 'subcuentas tiene las columnas de docs/06 §4');
select columns_are('public', 'asientos', array['id', 'movimiento_id', 'subcuenta_id', 'concepto', 'monto'],
                   'asientos tiene las columnas de docs/06 §4');
select ok((select bool_and(relrowsecurity) from pg_class
           where oid in ('public.fondos'::regclass, 'public.subcuentas'::regclass, 'public.movimientos'::regclass, 'public.asientos'::regclass)),
          'las cuatro tablas tienen RLS activo');
select ok(not has_function_privilege('authenticated', 'private.registrar_movimiento(public.tipo_movimiento, jsonb, jsonb, text, jsonb, uuid)', 'execute')
      and not has_function_privilege('service_role', 'private.registrar_movimiento(public.tipo_movimiento, jsonb, jsonb, text, jsonb, uuid)', 'execute'),
          'ni authenticated ni service_role ejecutan registrar_movimiento');

-- CA-1 · Fondo y subcuentas iniciales --------------------------------------------------------------
select is((select count(*)::int from public.fondos), 1, 'existe un solo fondo');
select throws_ok($$insert into public.fondos (nombre) values ('Segundo fondo')$$, '23505', null, 'no admite un segundo fondo (RN-01)');
select is((select (moneda, ia_activa, trading_activo)::text from public.fondos), '(USD,f,f)', 'USD y los interruptores nacen apagados');
select is((select array_agg(tipo::text order by tipo::text) from public.subcuentas),
          array['arriesgadas', 'externa', 'reserva', 'resultados', 'usuarios_comun'], 'hay las cinco subcuentas fijas');
select is((select count(*)::int from public.subcuentas where efectivo = 0 and invertido = 0 and retenido = 0), 5, 'todas nacen en 0');
select throws_ok($$insert into public.subcuentas (fondo_id, tipo, bolsillo) select id, 'reserva', 'reserva' from public.fondos$$,
                 '23505', null, 'no admite una segunda subcuenta del mismo tipo fijo');
select throws_ok($$insert into public.subcuentas (fondo_id, tipo, bolsillo) select id, 'cupo', 'usuarios' from public.fondos$$,
                 '23514', null, 'un cupo exige usuario');
select throws_ok($$insert into public.subcuentas (fondo_id, tipo, bolsillo) select id, 'externa', 'reserva' from public.fondos$$,
                 '23514', null, 'externa no tiene bolsillo');

-- Cupos de prueba (el alta real de cupos es de HU-017) -----------------------------------------------
insert into public.subcuentas (fondo_id, tipo, bolsillo, usuario_id)
select f.id, 'cupo', 'usuarios', u.id
from public.fondos f, (values ('00000000-0000-4000-8000-000000000001'::uuid), ('00000000-0000-4000-8000-000000000006'::uuid)) u (id);
select throws_ok($$insert into public.subcuentas (fondo_id, tipo, bolsillo, usuario_id)
                   select f.id, 'cupo', 'usuarios', '00000000-0000-4000-8000-000000000001' from public.fondos f$$,
                 '23505', null, 'una persona no tiene dos cupos abiertos');

-- registrar_movimiento: un aporte de 10.000 (docs/06 §4.2) ---------------------------------------------
create temp table mov as
select private.registrar_movimiento(
  'aporte',
  jsonb_build_array(
    pg_temp.a(pg_temp.sc('externa'), 'efectivo', -10000),
    pg_temp.a(pg_temp.sc('reserva'), 'efectivo', 5000),
    pg_temp.a(pg_temp.sc('arriesgadas'), 'efectivo', 2500),
    pg_temp.a(pg_temp.sc('usuarios_comun'), 'efectivo', 2500)),
  jsonb_build_object('tabla', 'movimientos_capital', 'id', gen_random_uuid()),
  'Aporte de prueba', '{"reparto": [50, 25, 25]}', '00000000-0000-4000-8000-000000000003') as id;
select is((select count(*)::int from public.movimientos m join mov on mov.id = m.id), 1, 'el aporte quedó registrado');
select is((select count(*)::int from public.asientos a join mov on mov.id = a.movimiento_id), 4, 'con sus cuatro asientos');
select is((select (tipo, creado_por is not null, referencia_tabla, parametros->>'reparto')::text from public.movimientos m join mov on mov.id = m.id),
          '(aporte,t,movimientos_capital,"[50, 25, 25]")', 'guarda tipo, autor, referencia y parámetros');
select is((select array[efectivo, invertido]::text from public.subcuentas where tipo = 'reserva'), '{5000.00,0.00}', 'la reserva tiene 5.000 (L2)');
select is((select efectivo from public.subcuentas where tipo = 'externa'), -10000.00::numeric, 'externa queda negativa por lo aportado (L4)');
select is((select version from public.subcuentas where tipo = 'reserva'), 2, 'la versión de lo tocado sube');
select is((select version from public.subcuentas where tipo = 'resultados'), 1, 'la de lo no tocado, no');
select is((select sum(efectivo) from public.subcuentas), 0.00::numeric, 'L4 · la suma de efectivo de todas las subcuentas es 0');

-- Asignar un cupo y comprar: efectivo e invertido (docs/06 §4.2) ----------------------------------------------
select lives_ok($$select private.registrar_movimiento('asignacion_cupo', jsonb_build_array(
    pg_temp.a(pg_temp.sc('usuarios_comun'), 'efectivo', -400),
    pg_temp.a((select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001'), 'efectivo', 400)),
  null, 'Cupo de prueba')$$, 'asignar un cupo es un movimiento válido');
select lives_ok($$select private.registrar_movimiento('compra', jsonb_build_array(
    pg_temp.a((select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001'), 'efectivo', -110.20),
    pg_temp.a((select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001'), 'invertido', 110.20)),
  null, 'Compra de prueba')$$, 'una compra mueve efectivo a invertido en la misma subcuenta');
select is((select array[efectivo, invertido]::text from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001'),
          '{289.80,110.20}', 'el cupo queda con 289,80 de efectivo y 110,20 invertido');

-- CA-2 / L1 · Suma cero -------------------------------------------------------------------------------------
select throws_ok($$select private.registrar_movimiento('ajuste', jsonb_build_array(
    pg_temp.a(pg_temp.sc('reserva'), 'efectivo', -1), pg_temp.a(pg_temp.sc('arriesgadas'), 'efectivo', 2)), null, 'Descuadrado')$$,
  '23514', 'LIBRO_DESCUADRADO', 'registrar_movimiento rechaza asientos que no suman cero');
select throws_ok($$select private.registrar_movimiento('ajuste', jsonb_build_array(
    pg_temp.a(pg_temp.sc('reserva'), 'efectivo', 0), pg_temp.a(pg_temp.sc('arriesgadas'), 'efectivo', 0)), null, 'Ceros')$$,
  '23514', 'LIBRO_DESCUADRADO', 'rechaza asientos de monto cero');
select throws_ok($$select private.registrar_movimiento('ajuste', jsonb_build_array(
    pg_temp.a(pg_temp.sc('reserva'), 'efectivo', -1)), null, 'Uno solo')$$,
  '23514', 'LIBRO_DESCUADRADO', 'rechaza un movimiento de un solo asiento');
select throws_ok($$select private.registrar_movimiento('ajuste', jsonb_build_array(
    pg_temp.a(pg_temp.sc('reserva'), 'efectivo', -0.001), pg_temp.a(pg_temp.sc('arriesgadas'), 'efectivo', 0.001)), null, 'Decimales')$$,
  '23514', 'LIBRO_DESCUADRADO', 'rechaza montos con más de dos decimales');
select throws_ok($$select private.registrar_movimiento('ajuste', '[{"x": 1}, {"y": 2}]'::jsonb, null, 'Mal formado')$$,
  '22023', null, 'rechaza asientos mal formados');
select throws_ok($$select private.registrar_movimiento('ajuste', jsonb_build_array(
    pg_temp.a(gen_random_uuid(), 'efectivo', -1), pg_temp.a(pg_temp.sc('reserva'), 'efectivo', 1)), null, 'Sin subcuenta')$$,
  'P0001', 'NO_EXISTE', 'rechaza una subcuenta que no existe');
select throws_ok($$select private.registrar_movimiento('ajuste', jsonb_build_array(
    pg_temp.a(pg_temp.sc('reserva'), 'efectivo', -1), pg_temp.a(pg_temp.sc('arriesgadas'), 'efectivo', 1)), null, '  ')$$,
  '22023', null, 'rechaza una descripción vacía');
select is((select count(*)::int from public.movimientos), 3, 'ningún rechazado dejó rastro en el libro');

-- Verificación diferida (segunda línea de L1): un insert directo que no suma cero falla al confirmar
savepoint directo;
insert into public.movimientos (id, fondo_id, tipo, descripcion)
  select '11111111-1111-4111-8111-111111111111', id, 'ajuste', 'Directo' from public.fondos;
insert into public.asientos (movimiento_id, subcuenta_id, concepto, monto)
  values ('11111111-1111-4111-8111-111111111111', pg_temp.sc('reserva'), 'efectivo', 5),
         ('11111111-1111-4111-8111-111111111111', pg_temp.sc('arriesgadas'), 'efectivo', -3);
select throws_ok($$set constraints all immediate$$, '23514', 'LIBRO_DESCUADRADO', 'la verificación diferida rechaza un insert directo descuadrado');
rollback to savepoint directo;
savepoint sin_asientos;
insert into public.movimientos (id, fondo_id, tipo, descripcion)
  select '22222222-2222-4222-8222-222222222222', id, 'ajuste', 'Vacío' from public.fondos;
select throws_ok($$set constraints all immediate$$, '23514', 'LIBRO_DESCUADRADO', 'y un movimiento sin asientos');
rollback to savepoint sin_asientos;

-- CA-3 / RN-05 · No negativos -----------------------------------------------------------------------------
select throws_ok($$select private.registrar_movimiento('retiro', jsonb_build_array(
    pg_temp.a(pg_temp.sc('reserva'), 'efectivo', -5000.01), pg_temp.a(pg_temp.sc('externa'), 'efectivo', 5000.01)), null, 'Retiro de más')$$,
  '23514', null, 'el efectivo de un bolsillo no puede quedar negativo');
select throws_ok($$select private.registrar_movimiento('venta', jsonb_build_array(
    pg_temp.a((select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001'), 'invertido', -110.21),
    pg_temp.a((select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-000000000001'), 'efectivo', 110.21)), null, 'Vende de más')$$,
  '23514', null, 'el invertido de un cupo no puede quedar negativo');
select lives_ok($$select private.registrar_movimiento('retiro', jsonb_build_array(
    pg_temp.a(pg_temp.sc('reserva'), 'efectivo', -5000), pg_temp.a(pg_temp.sc('externa'), 'efectivo', 5000)), null, 'Retiro exacto')$$,
  'dejar el efectivo exactamente en 0 sí se puede');
update public.subcuentas set efectivo = 100, retenido = 100 where tipo = 'arriesgadas';
select throws_ok($$update public.subcuentas set retenido = 100.01 where tipo = 'arriesgadas'$$, '23514', null,
                 'el retenido no puede superar al efectivo');
select throws_ok($$select private.registrar_movimiento('rebalanceo', jsonb_build_array(
    pg_temp.a(pg_temp.sc('arriesgadas'), 'efectivo', -50), pg_temp.a(pg_temp.sc('reserva'), 'efectivo', 50)), null, 'Toca lo retenido')$$,
  '23514', null, 'un movimiento no puede bajar el efectivo por debajo de lo retenido');
update public.subcuentas set retenido = 0, efectivo = 2500 where tipo = 'arriesgadas'; -- devuelve el saldo coherente con los asientos

-- CA-4 / L3 · Inmutabilidad -------------------------------------------------------------------------------
set constraints all immediate; -- un TRUNCATE no se admite con eventos diferidos pendientes
select throws_ok($$update public.asientos set monto = monto$$, 'P0001', null, 'UPDATE de asientos rechazado (dueño de la tabla)');
select throws_ok($$delete from public.asientos$$, 'P0001', null, 'DELETE de asientos rechazado');
select throws_ok($$truncate public.asientos$$, 'P0001', null, 'TRUNCATE de asientos rechazado');
select throws_ok($$update public.movimientos set descripcion = 'x'$$, 'P0001', null, 'UPDATE de movimientos rechazado');
select throws_ok($$delete from public.movimientos where false$$, 'P0001', null, 'DELETE de movimientos rechazado aunque no toque filas');
select throws_ok($$truncate public.movimientos cascade$$, 'P0001', null, 'TRUNCATE de movimientos rechazado');
set local role service_role;
select throws_ok($$delete from public.asientos$$, '42501', null, 'la llave secreta no puede borrar asientos');
select throws_ok($$update public.movimientos set descripcion = 'x'$$, '42501', null, 'la llave secreta no puede modificar movimientos');
select throws_ok($$update public.subcuentas set efectivo = 1$$, '42501', null, 'la llave secreta no puede editar saldos');
reset role;

-- Lectura por rol (docs/03 §4.3) ------------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select count(*)::int from public.subcuentas), 1, 'el Usuario ve solo su cupo');
select is((select count(*)::int from public.movimientos), 2, 've los movimientos que tocan su cupo (asignación y compra)');
select is((select count(*)::int from public.asientos), 3, 'y solo los asientos de su cupo');
select is((select count(*)::int from public.fondos), 0, 'no ve el fondo');
select throws_ok($$insert into public.asientos (movimiento_id, subcuenta_id, concepto, monto) values (gen_random_uuid(), gen_random_uuid(), 'efectivo', 1)$$,
                 '42501', null, 'no escribe en el libro');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000006", "role": "authenticated"}';
select is((select count(*)::int from public.movimientos), 0, 'otro Usuario no ve movimientos ajenos');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is((select array[count(*)::text] from public.subcuentas), array['7'], 'el analista ve todas las subcuentas');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is((select count(*)::int from public.movimientos), 4, 'el administrador ve todos los movimientos');
select is((select count(*)::int from public.fondos), 1, 'y el fondo');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated"}';
select is((select count(*)::int from public.subcuentas), 0, 'una cuenta suspendida no ve nada');
reset role;
set local role anon;
select throws_ok($$select count(*) from public.subcuentas$$, '42501', null, 'anon no lee el libro');
reset role;

-- CA-5 / L2 · Verificación diaria -------------------------------------------------------------------------------
select is((select count(*)::int from private.verificar_libro()), 0, 'con el libro íntegro, la verificación no encuentra diferencias');
update public.subcuentas set efectivo = efectivo + 1 where tipo = 'reserva';
select is((select subcuenta_id from private.verificar_libro()), pg_temp.sc('reserva'),
          'un saldo que difiere de sus asientos aparece en la verificación');
select is((select efectivo_guardado - efectivo_calculado from private.verificar_libro()), 1.00::numeric, 'con su diferencia');
select ok(exists (select 1 from cron.job where jobname = 'verificar_libro'), 'el trabajo diario verificar_libro está programado');

select * from finish();
rollback;

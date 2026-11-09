-- HU-014 · Registrar y anular aportes: tabla, RPC, auditoría, evento `capital` y permisos.
-- Criterios: CA-1 a CA-5 (backlog/E-03-fondo-y-libro-contable/HU-014-*.md). Reglas: docs/06 §4.3, §8.1 y §9,
-- docs/03 §4.3 y §4.4, docs/02 RN-07 y RN-10, docs/09 §3 y §4, docs/11 §4.1.
begin;
create extension if not exists pgtap with schema extensions;
select plan(55);

-- Cuentas de prueba: 0001 usuario · 0002 analista · 0003 administrador · 0004 administrador suspendido.
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

-- Ayudas: el evento publicado y el saldo total del libro (efectivo de todas las subcuentas).
create function pg_temp.eventos(p_id uuid, p_estado text) returns int
language sql as $$
  select count(*)::int from realtime.messages
   where topic = 'admin' and event = 'capital' and private
     and payload->>'id' = p_id::text and payload->>'estado' = p_estado
$$;
create function pg_temp.libro() returns text
language sql security definer as $$
  select (select count(*) from public.movimientos)::text || '|' ||
         (select count(*) from public.asientos)::text || '|' ||
         (select coalesce(sum(efectivo), 0) from public.subcuentas)::text
$$;
grant execute on function pg_temp.eventos(uuid, text), pg_temp.libro() to authenticated;

-- Estructura -------------------------------------------------------------------------------------
select has_table('public', 'movimientos_capital', 'existe movimientos_capital');
select has_type('public', 'estado_mov_capital', 'existe el tipo estado_mov_capital');
select is((select array_agg(e.enumlabel::text order by e.enumsortorder) from pg_enum e
            where e.enumtypid = 'public.estado_mov_capital'::regtype),
          array['registrado', 'confirmado', 'anulado'], 'el tipo tiene los tres estados de docs/06 §2');
select ok((select relrowsecurity from pg_class where oid = 'public.movimientos_capital'::regclass), 'RLS activo');
select ok(not has_table_privilege('authenticated', 'public.movimientos_capital', 'insert')
          and not has_table_privilege('authenticated', 'public.movimientos_capital', 'update')
          and not has_table_privilege('authenticated', 'public.movimientos_capital', 'delete')
          and not has_table_privilege('service_role', 'public.movimientos_capital', 'insert')
          and not has_table_privilege('anon', 'public.movimientos_capital', 'select'),
          'la API no escribe la tabla y anon no la lee');
select has_function('public', 'registrar_aporte', array['numeric', 'text', 'text'], 'existe registrar_aporte');
select has_function('public', 'anular_aporte', array['uuid', 'text'], 'existe anular_aporte');
select ok(has_function_privilege('authenticated', 'public.registrar_aporte(numeric, text, text)', 'execute')
          and has_function_privilege('authenticated', 'public.anular_aporte(uuid, text)', 'execute'),
          'authenticated ejecuta las dos (la función decide por el rol)');
select ok(not has_function_privilege('anon', 'public.registrar_aporte(numeric, text, text)', 'execute')
          and not has_function_privilege('anon', 'public.anular_aporte(uuid, text)', 'execute'),
          'anon no ejecuta ninguna');
select is_definer('public', 'registrar_aporte', array['numeric', 'text', 'text'], 'registrar_aporte es security definer');
select is_definer('public', 'anular_aporte', array['uuid', 'text'], 'anular_aporte es security definer');
select ok((select array_to_string(proconfig, ',') from pg_proc where oid = 'public.registrar_aporte(numeric, text, text)'::regprocedure)
            like '%search_path=""%'
          and (select array_to_string(proconfig, ',') from pg_proc where oid = 'public.anular_aporte(uuid, text)'::regprocedure)
            like '%search_path=""%',
          'las dos fijan search_path vacío');
select has_trigger('public', 'movimientos_capital', 'movimientos_capital_publicar_evento', 'la tabla tiene el trigger del evento');

-- CA-1: el Administrador registra ---------------------------------------------------------------
create temp table libro_antes as select pg_temp.libro() as v;
grant select on libro_antes to authenticated;

set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select lives_ok($$select public.registrar_aporte(10000, 'paper-inicial', 'Capital inicial')$$,
                'CA-1: el Administrador registra un aporte de 10.000 con la referencia paper-inicial');
select is((select count(*)::int from public.movimientos_capital), 1, 'el Administrador ve el aporte por la API (RLS)');
reset role;

select is((select (tipo, monto, estado, referencia_externa, nota, registrado_por)::text from public.movimientos_capital),
          '(aporte,10000.00,registrado,paper-inicial,"Capital inicial",00000000-0000-4000-8000-000000000003)',
          'CA-1: queda registrado, con su monto, referencia, nota y quién lo registró');
select ok((select confirmado_en is null and anulado_en is null and anulado_por is null and movimiento_id is null
             from public.movimientos_capital), 'sin confirmar, sin anular y sin movimiento del libro');
select is(pg_temp.libro(), (select v from libro_antes), 'CA-1: el libro no cambia (RN-07)');
select is((select (accion, entidad, actor_id, actor_rol, origen)::text from public.auditoria
            where accion = 'capital.aporte_registrado'),
          '(capital.aporte_registrado,movimientos_capital,00000000-0000-4000-8000-000000000003,administrador,app)',
          'CA-1: se registra capital.aporte_registrado con quién lo hizo');
select is((select entidad_id from public.auditoria where accion = 'capital.aporte_registrado'),
          (select id::text from public.movimientos_capital), 'la bitácora apunta al aporte');
select is(pg_temp.eventos((select id from public.movimientos_capital), 'registrado'), 1,
          'se publica un evento capital en el canal admin con el estado registrado');
select is((select array_agg(k order by k) from realtime.messages m, jsonb_object_keys(m.payload) k
            where m.topic = 'admin' and m.event = 'capital'),
          array['estado', 'id', 'tabla', 'version'], 'el evento lleva solo tabla, id, versión y estado');
select ok(not exists (select 1 from realtime.messages m where m.topic = 'admin' and m.event = 'capital'
                         and m.payload::text like '%10000%'), 'el evento no lleva montos');

-- Referencia y nota son opcionales ----------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select lives_ok($$select public.registrar_aporte(250.55)$$, 'referencia y nota son opcionales');
select lives_ok($$select public.registrar_aporte(100, '   ', '')$$, 'referencia y nota en blanco se guardan como nulas');
reset role;
select is((select count(*)::int from public.movimientos_capital where referencia_externa is null and nota is null), 2,
          'sin referencia ni nota quedan nulas');

-- CA-4: monto no positivo -----------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.registrar_aporte(0, 'x', null)$$, '23514', null, 'CA-4: monto 0 se rechaza');
select throws_ok($$select public.registrar_aporte(-5, 'x', null)$$, '23514', null, 'CA-4: monto negativo se rechaza');
select throws_ok($$select public.registrar_aporte(null, 'x', null)$$, '23514', null, 'CA-4: monto nulo se rechaza');
select throws_ok($$select public.registrar_aporte(10.005, 'x', null)$$, '23514', null, 'más de dos decimales se rechaza');
reset role;
select throws_ok($$insert into public.movimientos_capital (tipo, monto, registrado_por)
                    values ('aporte', 0, '00000000-0000-4000-8000-000000000003')$$,
                 '23514', null, 'CA-4: la tabla misma rechaza un monto 0, aunque se salten la función');
select is((select count(*)::int from public.movimientos_capital), 3, 'los rechazos no dejaron filas');

-- CA-2: anular -----------------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.anular_aporte((select id from public.movimientos_capital where monto = 250.55), '  ')$$,
                 '22023', null, 'la anulación exige un motivo');
select lives_ok($$select public.anular_aporte((select id from public.movimientos_capital where monto = 250.55), 'Se registró por error')$$,
                'CA-2: anula un aporte registrado con un motivo');
reset role;
select is((select (estado, anulado_por, motivo_anulacion)::text from public.movimientos_capital where monto = 250.55),
          '(anulado,00000000-0000-4000-8000-000000000003,"Se registró por error")',
          'CA-2: pasa a anulado y guarda quién y el motivo');
select ok((select anulado_en is not null from public.movimientos_capital where monto = 250.55), 'CA-2: guarda cuándo');
select is((select (antes, despues)::text from public.auditoria where accion = 'capital.aporte_anulado'),
          '("{""estado"": ""registrado""}","{""estado"": ""anulado""}")',
          'CA-2: se registra capital.aporte_anulado con el antes y el después');
select is((select detalle ->> 'motivo' from public.auditoria where accion = 'capital.aporte_anulado'),
          'Se registró por error', 'la bitácora guarda el motivo');
select is(pg_temp.eventos((select id from public.movimientos_capital where monto = 250.55), 'anulado'), 1,
          'se publica el evento capital con el estado anulado');
select is(pg_temp.libro(), (select v from libro_antes), 'anular tampoco mueve el libro');

set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.anular_aporte((select id from public.movimientos_capital where monto = 250.55), 'otra vez')$$,
                 'P0001', 'ESTADO_INVALIDO', 'un aporte ya anulado no se anula de nuevo');
select throws_ok($$select public.anular_aporte(gen_random_uuid(), 'no existe')$$, 'P0001', 'NO_EXISTE',
                 'un aporte que no existe responde NO_EXISTE');
reset role;

-- CA-3: un aporte confirmado no se anula ---------------------------------------------------------
-- La confirmación llega con HU-015; aquí se simula como postgres para probar la regla de anulación.
update public.movimientos_capital set estado = 'confirmado', confirmado_en = now() where monto = 100;
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.anular_aporte((select id from public.movimientos_capital where monto = 100), 'corregir')$$,
                 'P0001', 'ESTADO_INVALIDO', 'CA-3: un aporte confirmado responde ESTADO_INVALIDO');
reset role;
select is((select estado::text from public.movimientos_capital where monto = 100), 'confirmado',
          'CA-3: sigue confirmado');
select is((select count(*)::int from public.auditoria where accion = 'capital.aporte_anulado'), 1,
          'CA-3: el intento rechazado no dejó bitácora');

-- Coherencia de estado y marcas (CHECK) ------------------------------------------------------------
select throws_ok($$update public.movimientos_capital set estado = 'anulado' where monto = 10000$$, '23514', null,
                 'anulado sin sus marcas se rechaza');
select throws_ok($$update public.movimientos_capital set estado = 'confirmado' where monto = 10000$$, '23514', null,
                 'confirmado sin fecha de confirmación se rechaza');

-- CA-5: permisos ---------------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select throws_ok($$select public.registrar_aporte(5, 'x', null)$$, 'P0001', 'NO_AUTORIZADO', 'CA-5: el Usuario no registra');
select throws_ok($$select public.anular_aporte((select id from public.movimientos_capital where monto = 10000), 'x')$$,
                 'P0001', 'NO_AUTORIZADO', 'CA-5: el Usuario no anula');
select is((select count(*)::int from public.movimientos_capital), 0, 'el Usuario no ve el capital del fondo');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select throws_ok($$select public.registrar_aporte(5, 'x', null)$$, 'P0001', 'NO_AUTORIZADO', 'CA-5: el Analista no registra');
select throws_ok($$select public.anular_aporte((select id from public.movimientos_capital where monto = 10000), 'x')$$,
                 'P0001', 'NO_AUTORIZADO', 'CA-5: el Analista no anula');
select is((select count(*)::int from public.movimientos_capital), 3, 'el Analista sí lee el capital');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated"}';
select throws_ok($$select public.registrar_aporte(5, 'x', null)$$, 'P0001', 'SESION_INVALIDA',
                 'una cuenta suspendida responde SESION_INVALIDA');
reset role;
set local role anon;
select throws_ok($$select public.registrar_aporte(5, 'x', null)$$, '42501', null, 'anon no puede llamar registrar_aporte');
reset role;

select * from finish();
rollback;

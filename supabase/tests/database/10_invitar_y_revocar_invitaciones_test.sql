-- HU-003 · Invitar a una persona y revocar invitaciones: RPC, auditoría, evento `invitacion` y permisos.
-- Criterios: CA-1 a CA-7 (backlog/E-02-identidad-y-acceso/HU-003-*.md). Reglas: docs/06 §8.1 y §9,
-- docs/03 §4.4, docs/08 §5, docs/09 §3 y §4, docs/11 §4.1, docs/12 CB-02, CB-03, CB-04.
-- El flujo completo con Auth real (invitar, entrar, revocada que no entra) lo cubre el E2E-02.
begin;
create extension if not exists pgtap with schema extensions;
select plan(91);

-- Cuentas de prueba: 0001 usuario · 0002 analista · 0003 administrador · 0004 administrador suspendido ·
-- 0005 de baja. Suspender llega con HU-010 (R2): por eso la cuenta suspendida se crea ya así (CA-7).
set local session_replication_role = replica;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test'),
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test'),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test'),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test'),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-000000000001', 'usuario@prueba.test', 'Usuario de prueba', 'usuario');
insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en, baja_en) values
  ('00000000-0000-4000-8000-000000000002', 'analista@prueba.test', 'Analista de prueba', 'analista', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000003', 'administrador@prueba.test', 'Administrador de prueba', 'administrador', 'activo', null, null),
  ('00000000-0000-4000-8000-000000000004', 'suspendido@prueba.test', 'Suspendido de prueba', 'administrador', 'suspendido', now(), null),
  ('00000000-0000-4000-8000-000000000005', 'baja@prueba.test', 'De baja de prueba', 'usuario', 'baja', null, now());

-- El hook, como en la nube: solo Google y un dominio.
update public.parametros set valor = '["google"]'::jsonb where clave = 'auth.proveedores_permitidos';
update public.parametros set valor = '["prueba.test"]'::jsonb where clave = 'auth.dominios_permitidos';

-- Ayudas: el evento publicado (busca en realtime.messages, que lee postgres) y la respuesta del hook.
create function pg_temp.eventos(p_id uuid, p_estado text) returns int
language sql as $$
  select count(*)::int from realtime.messages
   where topic = 'admin' and event = 'invitacion' and private
     and payload->>'id' = p_id::text and payload->>'estado' = p_estado
$$;
create function pg_temp.hook(p_correo text) returns text
language sql as $$
  select coalesce(private.antes_de_crear_usuario(jsonb_build_object(
    'user', jsonb_build_object('email', p_correo, 'app_metadata', jsonb_build_object('provider', 'google'))
  )) -> 'error' ->> 'message', 'acepta')
$$;
create function pg_temp.id_de(p_correo text, p_estado text) returns uuid
language sql security definer as $$
  select id from public.invitaciones where email = p_correo and estado = p_estado::public.estado_invitacion
$$;
grant execute on function pg_temp.eventos(uuid, text), pg_temp.hook(text), pg_temp.id_de(text, text) to authenticated;

-- Estructura -------------------------------------------------------------------------------------
select has_function('public', 'invitar_usuario', array['text', 'rol_app', 'numeric'], 'existe public.invitar_usuario');
select has_function('public', 'revocar_invitacion', array['uuid'], 'existe public.revocar_invitacion');
select ok(has_function_privilege('authenticated', 'public.invitar_usuario(text, public.rol_app, numeric)', 'execute'),
          'authenticated ejecuta invitar_usuario (la función decide por el rol)');
select ok(not has_function_privilege('anon', 'public.invitar_usuario(text, public.rol_app, numeric)', 'execute'),
          'anon no ejecuta invitar_usuario');
select ok(has_function_privilege('authenticated', 'public.revocar_invitacion(uuid)', 'execute'),
          'authenticated ejecuta revocar_invitacion');
select ok(not has_function_privilege('anon', 'public.revocar_invitacion(uuid)', 'execute'),
          'anon no ejecuta revocar_invitacion');
select is_definer('public', 'invitar_usuario', array['text', 'rol_app', 'numeric'], 'invitar_usuario es security definer');
select is_definer('public', 'revocar_invitacion', array['uuid'], 'revocar_invitacion es security definer');
select ok((select array_to_string(proconfig, ',') from pg_proc where oid = 'public.invitar_usuario(text, public.rol_app, numeric)'::regprocedure)
            like '%search_path=""%'
          and (select array_to_string(proconfig, ',') from pg_proc where oid = 'public.revocar_invitacion(uuid)'::regprocedure)
            like '%search_path=""%',
          'las dos fijan search_path vacío');
select has_trigger('public', 'invitaciones', 'invitaciones_publicar_evento', 'invitaciones tiene el trigger del evento');
select ok(not has_function_privilege('authenticated', 'private.publicar_evento_invitacion()', 'execute')
          and not has_function_privilege('anon', 'private.publicar_evento_invitacion()', 'execute'),
          'la función del trigger no la ejecuta la API');

-- Fixtures de estados que la API no puede crear (las crea postgres) --------------------------------
insert into public.invitaciones (email, rol, estado, aceptada_en) values ('aceptada@prueba.test', 'usuario', 'aceptada', now());
insert into public.invitaciones (email, rol, estado) values ('yavencida@prueba.test', 'usuario', 'vencida');
-- Una pendiente cuya fecha ya pasó (CB-02).
insert into public.invitaciones (email, rol, expira_en) values ('vieja@prueba.test', 'analista', now() - interval '1 day');

-- CA-1: el Administrador invita -----------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select lives_ok($$select public.invitar_usuario('  Nueva@Prueba.Test ', 'usuario', 250.50)$$,
                'CA-1: el Administrador invita un correo con un rol y un cupo inicial');
select is((select count(*)::int from public.invitaciones where email = 'nueva@prueba.test'), 1,
          'el Administrador ve la invitación por la API (RLS)');
reset role;

select is((select (email, rol, cupo_inicial, estado, creada_por)::text from public.invitaciones where email = 'nueva@prueba.test'),
          '(nueva@prueba.test,usuario,250.50,pendiente,00000000-0000-4000-8000-000000000003)',
          'CA-1: queda pendiente, con el correo en minúsculas y sin espacios, su rol, su cupo y quién invitó');
select is((select expira_en - creado_en from public.invitaciones where email = 'nueva@prueba.test'), interval '7 days',
          'CA-1: vence a los 7 días');
select is((select (accion, entidad, entidad_id, actor_id, actor_rol, origen)::text from public.auditoria
            where accion = 'cuenta.invitada' and entidad_id = pg_temp.id_de('nueva@prueba.test', 'pendiente')::text),
          '(cuenta.invitada,invitaciones,' || pg_temp.id_de('nueva@prueba.test', 'pendiente')
            || ',00000000-0000-4000-8000-000000000003,administrador,app)',
          'CA-1: se registra cuenta.invitada con quién invitó');
select is((select detalle - 'expira_en' from public.auditoria
            where accion = 'cuenta.invitada' and entidad_id = pg_temp.id_de('nueva@prueba.test', 'pendiente')::text),
          '{"rol": "usuario", "email": "nueva@prueba.test", "cupo_inicial": 250.50}'::jsonb,
          'la bitácora guarda el correo, el rol y el cupo de la invitación');
select is(pg_temp.eventos(pg_temp.id_de('nueva@prueba.test', 'pendiente'), 'pendiente'), 1,
          'se publica un evento invitacion en el canal admin con el estado pendiente');
select is((select array_agg(k order by k) from realtime.messages m, jsonb_object_keys(m.payload) k
            where m.topic = 'admin' and m.event = 'invitacion'
              and m.payload->>'id' = pg_temp.id_de('nueva@prueba.test', 'pendiente')::text),
          array['estado', 'id', 'tabla', 'version'],
          'el evento lleva solo tabla, id, versión y estado');
select ok(not exists (select 1 from realtime.messages m
                       where m.topic = 'admin' and m.event = 'invitacion'
                         and m.payload::text like '%@%'),
          'el evento no lleva correos ni montos');
select is(pg_temp.hook('nueva@prueba.test'), 'acepta', 'CA-1: con esa invitación el hook deja entrar al correo');

-- CA-2 (CB-04): invitar dos veces el mismo correo --------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.invitar_usuario('nueva@prueba.test', 'analista', 0)$$, 'P0001', 'INVITACION_DUPLICADA',
                 'CA-2: invitar de nuevo un correo con invitación vigente responde INVITACION_DUPLICADA');
select throws_ok($$select public.invitar_usuario('NUEVA@PRUEBA.TEST', 'usuario', 0)$$, 'P0001', 'INVITACION_DUPLICADA',
                 'CA-2: el duplicado se detecta sin importar las mayúsculas');
select lives_ok($$select public.revocar_invitacion(pg_temp.id_de('nueva@prueba.test', 'pendiente'))$$,
                'CA-2: puede revocar la vigente');
select lives_ok($$select public.invitar_usuario('nueva@prueba.test', 'analista', 0)$$, 'CA-2: y crear otra');
reset role;
select is((select count(*)::int from public.invitaciones where email = 'nueva@prueba.test'), 2,
          'CA-2: quedan dos invitaciones del correo: la revocada y la nueva');
select is((select estado::text from public.invitaciones where email = 'nueva@prueba.test' and rol = 'analista'), 'pendiente',
          'CA-2: la nueva queda pendiente con el rol nuevo');

-- CA-3 (CB-03): el correo ya tiene cuenta ------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.invitar_usuario('usuario@prueba.test', 'usuario', 0)$$, 'P0001', 'CORREO_YA_REGISTRADO',
                 'CA-3: un correo con cuenta activa responde CORREO_YA_REGISTRADO');
select throws_ok($$select public.invitar_usuario('Baja@Prueba.Test', 'usuario', 0)$$, 'P0001', 'CORREO_YA_REGISTRADO',
                 'CA-3: también si la cuenta está de baja (la reincorporación es de HU-012)');
select throws_ok($$select public.invitar_usuario('suspendido@prueba.test', 'usuario', 0)$$, 'P0001', 'CORREO_YA_REGISTRADO',
                 'CA-3: también si la cuenta está suspendida');
select throws_ok($$select public.invitar_usuario('administrador@prueba.test', 'usuario', 0)$$, 'P0001', 'CORREO_YA_REGISTRADO',
                 'CA-3: y quien invita no puede invitarse a sí mismo');
reset role;
select is((select count(*)::int from public.invitaciones where email in ('usuario@prueba.test', 'baja@prueba.test', 'suspendido@prueba.test', 'administrador@prueba.test')),
          0, 'CA-3: ninguna de esas llamadas dejó una invitación');

-- CA-4: revocar ------------------------------------------------------------------------------------
select is(pg_temp.hook('nueva@prueba.test'), 'acepta', 'antes de revocar, la invitación pendiente deja entrar');
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select lives_ok($$select public.revocar_invitacion(pg_temp.id_de('nueva@prueba.test', 'pendiente'))$$,
                'CA-4: el Administrador revoca una invitación pendiente');
reset role;
select is((select count(*)::int from public.invitaciones where email = 'nueva@prueba.test' and estado = 'revocada' and revocada_en is not null), 2,
          'CA-4: pasa a revocada y registra cuándo');
select is((select (accion, entidad, actor_id, antes, despues, detalle)::text from public.auditoria
            where accion = 'cuenta.invitacion_revocada'
              and entidad_id = (select max(id::text) from public.invitaciones where email = 'nueva@prueba.test' and rol = 'analista')),
          '(cuenta.invitacion_revocada,invitaciones,00000000-0000-4000-8000-000000000003,"{""estado"": ""pendiente""}","{""estado"": ""revocada""}","{""rol"": ""analista"", ""email"": ""nueva@prueba.test""}")',
          'CA-4: se registra cuenta.invitacion_revocada con el estado antes y después');
select is(pg_temp.eventos((select id from public.invitaciones where email = 'nueva@prueba.test' and rol = 'analista'), 'revocada'), 1,
          'CA-4: se publica el evento invitacion con el estado revocada');
select is(pg_temp.hook('nueva@prueba.test'), 'Tu correo no tiene una invitación vigente. Pídele una al administrador.',
          'CA-4: ese correo ya no puede ingresar');
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.revocar_invitacion((select id from public.invitaciones where email = 'nueva@prueba.test' and rol = 'analista'))$$,
                 'P0001', 'ESTADO_INVALIDO', 'revocar una ya revocada responde ESTADO_INVALIDO');
select throws_ok($$select public.revocar_invitacion(pg_temp.id_de('aceptada@prueba.test', 'aceptada'))$$,
                 'P0001', 'ESTADO_INVALIDO', 'revocar una aceptada responde ESTADO_INVALIDO');
select throws_ok($$select public.revocar_invitacion(pg_temp.id_de('yavencida@prueba.test', 'vencida'))$$,
                 'P0001', 'ESTADO_INVALIDO', 'revocar una vencida responde ESTADO_INVALIDO');
select throws_ok($$select public.revocar_invitacion('00000000-0000-4000-8000-00000000ffff')$$,
                 'P0001', 'NO_EXISTE', 'revocar una invitación que no existe responde NO_EXISTE');
select throws_ok($$select public.revocar_invitacion(null)$$, 'P0001', 'NO_EXISTE', 'revocar sin id responde NO_EXISTE');
reset role;

-- CA-5: Usuario y Analista --------------------------------------------------------------------------
insert into public.invitaciones (email, rol) values ('pendiente-de-otro@prueba.test', 'usuario');
create temp table antes as select count(*)::int as invitaciones_antes from public.invitaciones;
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}';
select throws_ok($$select public.invitar_usuario('otra@prueba.test', 'usuario', 0)$$, 'P0001', 'NO_AUTORIZADO',
                 'CA-5: un Usuario que invita recibe NO_AUTORIZADO');
select throws_ok($$select public.revocar_invitacion(pg_temp.id_de('pendiente-de-otro@prueba.test', 'pendiente'))$$,
                 'P0001', 'NO_AUTORIZADO', 'CA-5: un Usuario que revoca recibe NO_AUTORIZADO');
select is((select count(*)::int from public.invitaciones), 0, 'un Usuario no lee invitaciones');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000002", "role": "authenticated"}';
select throws_ok($$select public.invitar_usuario('otra@prueba.test', 'usuario', 0)$$, 'P0001', 'NO_AUTORIZADO',
                 'CA-5: un Analista que invita recibe NO_AUTORIZADO');
select throws_ok($$select public.revocar_invitacion(pg_temp.id_de('pendiente-de-otro@prueba.test', 'pendiente'))$$,
                 'P0001', 'NO_AUTORIZADO', 'CA-5: un Analista que revoca recibe NO_AUTORIZADO');
select is((select count(*)::int from public.invitaciones), 0, 'un Analista no recibe filas de invitaciones');
reset role;
select is((select count(*)::int from public.invitaciones), (select invitaciones_antes from antes),
          'CA-5: ninguna de esas llamadas cambió las invitaciones');
select is((select estado::text from public.invitaciones where email = 'pendiente-de-otro@prueba.test'), 'pendiente',
          'CA-5: y la pendiente sigue pendiente');

-- CA-6 (CB-02): una pendiente con más de 7 días ------------------------------------------------
select is(pg_temp.hook('vieja@prueba.test'), 'Tu correo no tiene una invitación vigente. Pídele una al administrador.',
          'CA-6: con la fecha pasada, su correo no puede entrar');
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select lives_ok($$select public.invitar_usuario('vieja@prueba.test', 'usuario', 100)$$,
                'CA-6: el Administrador invita de nuevo ese correo: la pasada de fecha no lo impide');
reset role;
select is((select count(*)::int from public.invitaciones where email = 'vieja@prueba.test' and estado = 'vencida'), 1,
          'CA-6: la anterior pasa a vencida');
select is((select count(*)::int from public.invitaciones where email = 'vieja@prueba.test' and estado = 'pendiente' and expira_en > now()), 1,
          'CA-6: y se crea una nueva pendiente y vigente');
select is(pg_temp.eventos(pg_temp.id_de('vieja@prueba.test', 'vencida'), 'vencida'), 1,
          'CA-6: el paso a vencida también se publica');
select is((select detalle ->> 'reemplaza' from public.auditoria
            where accion = 'cuenta.invitada' and entidad_id = pg_temp.id_de('vieja@prueba.test', 'pendiente')::text),
          pg_temp.id_de('vieja@prueba.test', 'vencida')::text,
          'CA-6: cuenta.invitada anota cuál invitación reemplaza');
select is(pg_temp.hook('vieja@prueba.test'), 'acepta', 'CA-6: con la nueva invitación ese correo ya puede entrar');

-- CA-6 con el reloj: a los 8 días la vigente deja de servir y se puede invitar de nuevo ---------------
select pruebas.fijar_reloj(now() + interval '8 days');
select is(pg_temp.hook('vieja@prueba.test'), 'Tu correo no tiene una invitación vigente. Pídele una al administrador.',
          'CA-6: pasados 7 días, la invitación pendiente deja de servir');
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select lives_ok($$select public.invitar_usuario('vieja@prueba.test', 'analista', 0)$$,
                'CA-6: con el reloj adelantado se invita de nuevo ese correo');
reset role;
select is((select count(*)::int from public.invitaciones where email = 'vieja@prueba.test' and estado = 'vencida'), 2,
          'CA-6: la anterior pasó a vencida');
select is((select (expira_en - private.ahora())::text from public.invitaciones where email = 'vieja@prueba.test' and estado = 'pendiente'),
          '7 days', 'el vencimiento de la nueva se cuenta con el reloj de private.ahora()');
select is(pg_temp.hook('vieja@prueba.test'), 'acepta', 'y con el reloj adelantado la nueva sí deja entrar');
select pruebas.fijar_reloj(null);

-- CA-7: sin sesión activa ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000004", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select throws_ok($$select public.invitar_usuario('otra@prueba.test', 'usuario', 0)$$, 'P0001', 'SESION_INVALIDA',
                 'CA-7: un administrador suspendido con token vigente no puede invitar');
select throws_ok($$select public.revocar_invitacion(pg_temp.id_de('pendiente-de-otro@prueba.test', 'pendiente'))$$,
                 'P0001', 'SESION_INVALIDA', 'CA-7: ni revocar');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000005", "role": "authenticated"}';
select throws_ok($$select public.invitar_usuario('otra@prueba.test', 'usuario', 0)$$, 'P0001', 'SESION_INVALIDA',
                 'una cuenta de baja no puede invitar');
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000009", "role": "authenticated"}';
select throws_ok($$select public.invitar_usuario('otra@prueba.test', 'usuario', 0)$$, 'P0001', 'SESION_INVALIDA',
                 'quien no tiene perfil no puede invitar');
select throws_ok($$select public.revocar_invitacion(pg_temp.id_de('pendiente-de-otro@prueba.test', 'pendiente'))$$,
                 'P0001', 'SESION_INVALIDA', 'ni revocar');
reset role;
select is((select estado::text from public.invitaciones where email = 'pendiente-de-otro@prueba.test'), 'pendiente',
          'CA-7: ninguna de esas llamadas tocó la invitación');
set local role anon;
select throws_ok($$select public.invitar_usuario('otra@prueba.test', 'usuario', 0)$$, '42501', null,
                 'anon no puede llamar invitar_usuario');
select throws_ok($$select public.revocar_invitacion('00000000-0000-4000-8000-00000000ffff')$$, '42501', null,
                 'anon no puede llamar revocar_invitacion');
reset role;

-- Datos mal formados ---------------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$select public.invitar_usuario('no-es-un-correo', 'usuario', 0)$$, '22023', null,
                 'un correo sin arroba se rechaza');
select throws_ok($$select public.invitar_usuario('a@b', 'usuario', 0)$$, '22023', null, 'un correo sin punto en el dominio se rechaza');
select throws_ok($$select public.invitar_usuario('con espacio@prueba.test', 'usuario', 0)$$, '22023', null, 'un correo con espacios se rechaza');
select throws_ok($$select public.invitar_usuario('   ', 'usuario', 0)$$, '22023', null, 'un correo vacío se rechaza');
select throws_ok($$select public.invitar_usuario(null, 'usuario', 0)$$, '22023', null, 'un correo nulo se rechaza');
select throws_ok($$select public.invitar_usuario('x@prueba.test', null, 0)$$, '22023', null, 'un rol nulo se rechaza');
select throws_ok($$select public.invitar_usuario('x@prueba.test', 'superadmin', 0)$$, '22P02', null, 'un rol que no existe se rechaza');
select throws_ok($$select public.invitar_usuario('x@prueba.test', 'usuario', -1)$$, '22023', null, 'un cupo negativo se rechaza');
select throws_ok($$select public.invitar_usuario('x@prueba.test', 'usuario', null)$$, '22023', null, 'un cupo nulo se rechaza');
select lives_ok($$select public.invitar_usuario('cupo-cero@prueba.test', 'administrador', 0)$$, 'un cupo de 0 es válido y el rol administrador también');
reset role;
select is((select count(*)::int from public.invitaciones where email = 'x@prueba.test'), 0, 'nada de eso dejó una invitación');

-- La tabla sigue sin escrituras directas ----------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-000000000003", "role": "authenticated"}';
select throws_ok($$insert into public.invitaciones (email, rol) values ('directa@prueba.test', 'usuario')$$, '42501', null,
                 'ni el Administrador inserta en invitaciones por la API');
select throws_ok($$update public.invitaciones set estado = 'revocada'$$, '42501', null,
                 'ni el Administrador actualiza invitaciones por la API');
select throws_ok($$delete from public.invitaciones$$, '42501', null, 'ni el Administrador borra invitaciones por la API');
reset role;

-- La aceptación del alta también se publica ---------------------------------------------------------
insert into public.invitaciones (email, rol) values ('alta@prueba.test', 'usuario');
insert into auth.users (id, email) values ('00000000-0000-4000-8000-0000000000a1', 'alta@prueba.test');
select is((select estado::text from public.invitaciones where email = 'alta@prueba.test'), 'aceptada', 'el alta acepta la invitación (HU-002)');
select is(pg_temp.eventos((select id from public.invitaciones where email = 'alta@prueba.test'), 'aceptada'), 1,
          'y esa aceptación publica el evento invitacion con el estado aceptada');
select is(pg_temp.eventos((select id from public.invitaciones where email = 'alta@prueba.test'), 'pendiente'), 1,
          'la creación de una invitación por SQL también publica su evento');

-- Cada invitación y cada revocación quedó en la bitácora (SC-004) -------------------------------------
select is((select count(*)::int from public.auditoria where accion = 'cuenta.invitada'), 5,
          'SC-004: cuenta.invitada quedó registrada por cada invitación creada con la RPC');
select is((select count(*)::int from public.auditoria where accion = 'cuenta.invitacion_revocada'), 2,
          'SC-004: cuenta.invitacion_revocada quedó registrada por cada revocación');
select is((select count(*)::int from public.auditoria where accion like 'cuenta.invit%' and actor_id is null), 0,
          'toda entrada tiene quién actuó');

select * from finish();
rollback;

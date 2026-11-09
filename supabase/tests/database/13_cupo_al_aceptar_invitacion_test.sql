-- HU-017 · Cupo al aceptar la invitación: private.crear_cupo, trigger de alta y lectura del propio cupo.
-- Criterios: CA-1 a CA-5 (backlog/E-03-fondo-y-libro-contable/HU-017-*.md). Reglas: docs/02 RN-18 y RN-20,
-- docs/04 §6, docs/12 CB-15. El relleno de CA-4 corre en la migración; aquí se prueba con la misma función.
-- La alerta cupo_inicial_no_asignado es de HU-085 (aún sin tabla alertas).
begin;
create extension if not exists pgtap with schema extensions;
select plan(21);

update public.parametros set valor = '["google"]'::jsonb where clave = 'auth.proveedores_permitidos';
update public.parametros set valor = '["ritech.test"]'::jsonb where clave = 'auth.dominios_permitidos';

-- Fondos en la bolsa común: 2.500 (docs/06 §4.2, aporte de 10.000).
select private.registrar_movimiento('aporte', jsonb_build_array(
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'externa'), 'concepto', 'efectivo', 'monto', -2500),
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'usuarios_comun'), 'concepto', 'efectivo', 'monto', 2500)),
  null, 'Fondos de prueba');

insert into public.invitaciones (email, rol, cupo_inicial) values
  ('con400@ritech.test', 'usuario', 400),
  ('sin0@ritech.test', 'usuario', 0),
  ('grande@ritech.test', 'usuario', 5000),
  ('analista@ritech.test', 'analista', 0),
  ('admin@ritech.test', 'administrador', 0);

-- Las altas pasan por el trigger de auth.users, como en la nube.
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-0000000000a1', 'con400@ritech.test'),
  ('00000000-0000-4000-8000-0000000000a2', 'sin0@ritech.test');

-- CA-1 · Cupo con monto ------------------------------------------------------------------------------
select is((select array[efectivo, invertido]::text from public.subcuentas where usuario_id = '00000000-0000-4000-8000-0000000000a1'),
          '{400.00,0.00}', 'CA-1 · la persona con cupo inicial de 400 recibe 400 en su cupo');
select is((select efectivo from public.subcuentas where tipo = 'usuarios_comun'), 2100.00::numeric, 'y usuarios_comun baja de 2.500 a 2.100');
select is((select count(*)::int from public.movimientos where tipo = 'asignacion_cupo'), 1, 'con un movimiento asignacion_cupo');
select is((select count(*)::int from public.asientos a join public.movimientos m on m.id = a.movimiento_id where m.tipo = 'asignacion_cupo'), 2,
          'de dos asientos que suman cero');
select is((select count(*)::int from public.auditoria where accion = 'cupo.asignado'
            and detalle->>'usuario_id' = '00000000-0000-4000-8000-0000000000a1'), 1, 'y se audita cupo.asignado');
select is((select bolsillo::text from public.subcuentas where usuario_id = '00000000-0000-4000-8000-0000000000a1'), 'usuarios',
          'el cupo es del bolsillo usuarios');

-- Cupo inicial 0: cupo creado, sin movimiento ----------------------------------------------------------
select is((select efectivo from public.subcuentas where usuario_id = '00000000-0000-4000-8000-0000000000a2'), 0.00::numeric,
          'un cupo inicial de 0 crea el cupo en 0');
select is((select count(*)::int from public.movimientos where tipo = 'asignacion_cupo'), 1, 'sin movimiento de asignación');

-- CA-2 / CB-15 · La bolsa común no cubre -----------------------------------------------------------------
select lives_ok($$insert into auth.users (id, email) values ('00000000-0000-4000-8000-0000000000a3', 'grande@ritech.test')$$,
                'CB-15 · el ingreso no falla si usuarios_comun no cubre el cupo inicial');
select is((select efectivo from public.subcuentas where usuario_id = '00000000-0000-4000-8000-0000000000a3'), 0.00::numeric,
          'entra con el cupo en 0');
select is((select efectivo from public.subcuentas where tipo = 'usuarios_comun'), 2100.00::numeric, 'y la bolsa común no se toca');
select is((select count(*)::int from public.perfiles where id = '00000000-0000-4000-8000-0000000000a3' and estado = 'activo'), 1,
          'la persona queda con su perfil activo');

-- CA-3 · Analista y administrador no tienen cupo -----------------------------------------------------------
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-0000000000b1', 'analista@ritech.test'),
  ('00000000-0000-4000-8000-0000000000b2', 'admin@ritech.test');
select is((select count(*)::int from public.subcuentas where usuario_id in
            ('00000000-0000-4000-8000-0000000000b1', '00000000-0000-4000-8000-0000000000b2')), 0,
          'CA-3 · un analista y un administrador no reciben cupo');

-- Idempotencia y validación de crear_cupo ---------------------------------------------------------------------
select is(private.crear_cupo('00000000-0000-4000-8000-0000000000a1', 999),
          (select id from public.subcuentas where usuario_id = '00000000-0000-4000-8000-0000000000a1'),
          'repetir crear_cupo devuelve el cupo abierto');
select is((select efectivo from public.subcuentas where usuario_id = '00000000-0000-4000-8000-0000000000a1'), 400.00::numeric,
          'y no vuelve a asignar');
select throws_ok($$select private.crear_cupo('00000000-0000-4000-8000-0000000000a1', -1)$$, '22023', null, 'rechaza un monto negativo');
select throws_ok($$select private.crear_cupo(gen_random_uuid(), 0)$$, 'P0001', 'NO_EXISTE', 'rechaza una persona sin perfil');
select ok(not has_function_privilege('authenticated', 'private.crear_cupo(uuid, numeric)', 'execute'), 'la API no ejecuta crear_cupo');

-- CA-4 · Relleno de los Usuarios anteriores al libro: un Usuario sin cupo recibe el suyo en 0 ---------------------
set local session_replication_role = replica;
insert into auth.users (id, email) values ('00000000-0000-4000-8000-0000000000c1', 'antiguo@ritech.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol) values
  ('00000000-0000-4000-8000-0000000000c1', 'antiguo@ritech.test', 'Antiguo', 'usuario');
select private.crear_cupo(p.id, 0) from public.perfiles p where p.rol = 'usuario' and p.estado <> 'baja'
  and not exists (select 1 from public.subcuentas s where s.usuario_id = p.id);
select is((select efectivo from public.subcuentas where usuario_id = '00000000-0000-4000-8000-0000000000c1'), 0.00::numeric,
          'CA-4 · un Usuario anterior queda con su cupo en 0');

-- CA-5 · Aislamiento ---------------------------------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims to '{"sub": "00000000-0000-4000-8000-0000000000a1", "role": "authenticated"}';
select is((select count(*)::int from public.subcuentas), 1, 'CA-5 · el Usuario solo ve su cupo');
select is((select efectivo from public.subcuentas), 400.00::numeric, 'y es el suyo');
reset role;

select * from finish();
rollback;

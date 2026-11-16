-- HU-020 · Agregación por bolsillo e aislamiento de las cuentas.
begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

set local session_replication_role = replica;
insert into auth.users (id, email)
values ('00000000-0000-4000-8000-000000000020', 'resumen@prueba.test');
set local session_replication_role = origin;
insert into public.perfiles (id, email, nombre, rol)
values ('00000000-0000-4000-8000-000000000020', 'resumen@prueba.test', 'Prueba resumen', 'usuario');

-- Se fijan los saldos de la foto para probar la lectura agregada.
update public.subcuentas
set efectivo = case tipo when 'reserva' then 5000 when 'arriesgadas' then 2500 else 1500 end
where tipo in ('reserva', 'arriesgadas', 'usuarios_comun');

insert into public.subcuentas (fondo_id, tipo, bolsillo, usuario_id, efectivo)
select id, 'cupo', 'usuarios', '00000000-0000-4000-8000-000000000020', 1000
from public.fondos;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000020';
select results_eq(
  $$select * from public.resumen_fondo()$$,
  $$values ('reserva'::public.bolsillo, 5000::numeric, 0::numeric, 5000::numeric, 50::numeric, 50::numeric),
           ('arriesgadas'::public.bolsillo, 2500::numeric, 0::numeric, 2500::numeric, 25::numeric, 25::numeric),
           ('usuarios'::public.bolsillo, 2500::numeric, 0::numeric, 2500::numeric, 25::numeric, 25::numeric)$$,
  'entrega solo los tres agregados e incluye el saldo del cupo en Usuarios'
);
reset role;

update public.perfiles set estado = 'suspendido', suspendido_en = now()
where id = '00000000-0000-4000-8000-000000000020';
set local role authenticated;
select is_empty($$select * from public.resumen_fondo()$$, 'un token vigente de una cuenta suspendida no recibe datos');
reset role;

select ok(not has_function_privilege('anon', 'public.resumen_fondo()', 'EXECUTE'), 'anónimo no puede llamar el resumen');

select * from finish();
rollback;

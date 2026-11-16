-- HU-108 · Una cadena válida pasa y una alteración identifica el registro afectado.
begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

select is(private.verificar_cadena_auditoria(), null::bigint, 'la cadena inicial es válida');

select private.auditar(null, 'parametro.cambiado', 'parametros', 'ia.umbral');
select private.auditar(null, 'cupo.asignado', 'subcuentas', '5');
select is(private.verificar_cadena_auditoria(), null::bigint, 'los registros nuevos conservan la cadena');

-- Solo se permite alterar el registro dentro de esta transacción de prueba.
set local session_replication_role = replica;
update public.auditoria
   set detalle = '{"alterado": true}'::jsonb
 where id = (select max(id) from public.auditoria);
set local session_replication_role = origin;

select is(
  private.verificar_cadena_auditoria(),
  (select max(id) from public.auditoria),
  'detecta un contenido alterado y devuelve su id'
);
select ok(
  not has_function_privilege('authenticated', 'private.verificar_cadena_auditoria()', 'EXECUTE'),
  'la verificación interna no está expuesta a las sesiones de la app'
);

select * from finish();
rollback;

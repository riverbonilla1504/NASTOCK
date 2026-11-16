-- HU-108 · Verifica los enlaces y recalcula el hash de cada registro (docs/11 §4.3).
-- El primer id inválido permite identificar el punto de ruptura. Una cadena
-- válida, incluida una bitácora vacía, devuelve NULL.
create function private.verificar_cadena_auditoria()
returns bigint
language sql
stable
set search_path = ''
as $$
  with cadena as (
    select a.*, lag(a.hash, 1, repeat('0', 64)) over (order by a.id) as esperado
    from public.auditoria a
  )
  select c.id
  from cadena c
  where c.hash_anterior is distinct from c.esperado
     or c.hash is distinct from private.hash_auditoria(
       c.hash_anterior, c.momento, c.actor_id, c.actor_rol, c.accion,
       c.entidad, c.entidad_id, c.antes, c.despues, c.detalle, c.origen
     )
  order by c.id
  limit 1;
$$;

revoke all on function private.verificar_cadena_auditoria()
from public, anon, authenticated, service_role;

comment on function private.verificar_cadena_auditoria() is
  'Devuelve el id del primer registro inválido de la bitácora o NULL si la cadena es válida.';

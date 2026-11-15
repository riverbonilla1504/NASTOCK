-- HU-076 · PM-13, docs/08 §2, docs/10 §7; historial 3.30 aprobado.
alter table public.ordenes add column cancelacion_solicitada_en timestamptz;
alter table public.ordenes add column cancelacion_solicitada_por uuid references public.perfiles(id);

create function public.cancelar_orden(p_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := (select auth.uid());
  v_rol public.rol_app := private.rol_actual();
  v_orden public.ordenes;
begin
  if v_rol is null then raise exception 'SESION_INVALIDA'; end if;
  if v_rol <> 'usuario' then raise exception 'NO_AUTORIZADO'; end if;
  select * into v_orden from public.ordenes where id=p_id for update;
  if not found then raise exception 'NO_EXISTE'; end if;
  if not exists (
    select 1 from public.subcuentas where id=v_orden.subcuenta_id and usuario_id=v_actor
  ) then raise exception 'NO_AUTORIZADO'; end if;
  if v_orden.estado='cancelada' and v_orden.cancelacion_solicitada_por=v_actor then return; end if;
  if v_orden.estado not in ('creada','enviada','aceptada','parcialmente_llenada','desconocida') then
    raise exception 'ESTADO_INVALIDO' using detail=v_orden.estado::text;
  end if;
  if v_orden.cancelacion_solicitada_en is not null then return; end if;
  update public.ordenes set cancelacion_solicitada_en=private.ahora(),
    cancelacion_solicitada_por=v_actor, version=version+1 where id=p_id;
  if v_orden.estado='creada' then
    perform private.cambiar_estado_orden(p_id,'cancelada',jsonb_build_object('origen','solicitud_usuario'));
  else
    perform private.despertar_funcion('sincronizar-ordenes','{}'::jsonb);
  end if;
end;
$$;
revoke all on function public.cancelar_orden(uuid) from public, anon, authenticated, service_role;
grant execute on function public.cancelar_orden(uuid) to authenticated;

create function private.ordenes_por_cancelar()
returns table(orden_id uuid, broker_order_id text)
language sql stable security definer set search_path = '' as $$
  select t.orden_id,t.broker_order_id from private.ordenes_por_cancelar_por_tiempo() t
  union
  select o.id,o.broker_order_id from public.ordenes o
   where o.cancelacion_solicitada_en is not null and o.broker_order_id is not null
     and o.estado in ('aceptada','parcialmente_llenada','desconocida','enviada');
$$;
revoke all on function private.ordenes_por_cancelar() from public, anon, authenticated, service_role;

create function private.auditar_cancelacion_orden() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.estado='cancelada' and old.estado<>'cancelada' and new.cancelacion_solicitada_por is not null then
    perform private.auditar(new.cancelacion_solicitada_por,'orden.cancelada','ordenes',new.id::text,
      jsonb_build_object('cantidad_llenada',new.cantidad_llenada));
  end if;
  return null;
end;
$$;
revoke all on function private.auditar_cancelacion_orden() from public, anon, authenticated, service_role;
create trigger ordenes_auditar_cancelacion after update of estado on public.ordenes
  for each row execute function private.auditar_cancelacion_orden();
comment on function public.cancelar_orden(uuid) is 'HU-076: solicita cancelar la orden propia. El broker confirma vía sincronizar-ordenes; creada se cancela localmente. Idempotente.';

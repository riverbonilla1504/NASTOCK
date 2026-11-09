-- HU-074 · private.cambiar_estado_orden guarda también lo llenado en el evento.
-- Fuentes: docs/06 §5.4 (`ordenes_eventos.cantidad_llenada` y `precio`), docs/08 §2.2.
--
-- Reemplaza la función de 20261110130000 (HU-073) por una con dos parámetros más, opcionales: las llamadas
-- de cuatro argumentos del ejecutor siguen valiendo. Las migraciones solo van hacia adelante, por eso no se
-- edita la anterior.

drop function private.cambiar_estado_orden(uuid, public.estado_orden, jsonb, text);

create function private.cambiar_estado_orden(
  p_orden_id         uuid,
  p_estado           public.estado_orden,
  p_detalle          jsonb default null,
  p_motivo           text default null,
  p_cantidad_llenada numeric default null,
  p_precio           numeric default null
)
returns public.ordenes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_orden public.ordenes;
  v_antes public.estado_orden;
  v_ahora timestamptz := private.ahora();
  v_final boolean := p_estado in ('llenada', 'cancelada', 'vencida', 'rechazada', 'error_envio');
  v_retenida numeric(14,2);
begin
  select * into v_orden from public.ordenes where id = p_orden_id for update;
  if not found then
    raise exception 'NO_EXISTE';
  end if;
  v_antes := v_orden.estado;
  v_retenida := v_orden.retencion;
  -- Una orden terminada no vuelve a cambiar.
  if v_antes in ('llenada', 'cancelada', 'vencida', 'rechazada', 'error_envio') then
    raise exception 'ESTADO_INVALIDO' using detail = v_antes::text;
  end if;

  update public.ordenes set
    estado         = p_estado,
    motivo_rechazo = coalesce(p_motivo, motivo_rechazo),
    enviada_en     = case when p_estado = 'enviada' then v_ahora else enviada_en end,
    terminada_en   = case when v_final then v_ahora else terminada_en end,
    retencion      = case when v_final then 0 else retencion end,
    version        = version + 1
  where id = p_orden_id returning * into v_orden;

  if v_final and v_retenida > 0 then
    -- La retención no es del libro (L5): se libera sin tocar efectivo ni invertido.
    update public.subcuentas set
      retenido = greatest(retenido - v_retenida, 0),
      version  = version + 1
    where id = v_orden.subcuenta_id;
  end if;

  insert into public.ordenes_eventos (orden_id, estado_anterior, estado_nuevo, cantidad_llenada, precio, detalle)
  values (p_orden_id, v_antes, p_estado, p_cantidad_llenada, p_precio, p_detalle);
  return v_orden;
end;
$$;

comment on function private.cambiar_estado_orden(uuid, public.estado_orden, jsonb, text, numeric, numeric) is
  'Pasa una orden a otro estado, deja el evento (con lo llenado y el precio, si se informan) y, si la orden termina, libera lo que retenía su subcuenta (docs/08 §2.2).';
revoke all on function private.cambiar_estado_orden(uuid, public.estado_orden, jsonb, text, numeric, numeric) from public, anon, authenticated, service_role;

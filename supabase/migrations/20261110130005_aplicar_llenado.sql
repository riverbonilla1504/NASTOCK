-- HU-074 · private.aplicar_llenado: aplica al libro, a la posición y a la retención lo que el broker reporta
-- de una orden.
-- Fuentes: docs/08 §2 (estados, §2.1 correspondencia con Alpaca, §2.2 reglas), docs/02 §6.2 (costo promedio,
-- RN-25), §7.1 (resultado realizado), RN-27 (el costo vuelve completo), RN-23 (retención), docs/06 §4.2
-- (asientos de `compra` y `venta`), docs/12 CB-34, CB-35, CB-38, CB-39.
--
-- Idempotente: recibe la cantidad TOTAL llenada y el precio promedio que reporta el broker y aplica solo la
-- diferencia contra lo ya aplicado (`cantidad_llenada`, `monto_llenado`). Llamarla dos veces con los mismos
-- datos no cambia nada (CA-2).
--
-- MVP corto (D-65): las órdenes son manuales; no hay sugerencia que cerrar. Dos piezas llegan en otras
-- historias y se agregan a esta función con una migración nueva: el reparto 50/25/25 de la ganancia de una venta
-- (HU-023: movimiento `reparto_ganancia`, RN-26 a RN-30) y la protección nativa (HU-077). Mientras tanto la
-- ganancia queda entera en la subcuenta que vendió y `resultados` la refleja.

-- Estado crudo de Alpaca → estado nuestro (docs/08 §2.1). Nulo = se conserva el estado anterior (el estado
-- crudo se guarda igual).
create function private.estado_desde_broker(p_estado text)
returns public.estado_orden
language plpgsql
immutable
set search_path = ''
as $$
begin
  case lower(coalesce(p_estado, ''))
    when 'new', 'accepted', 'pending_new', 'accepted_for_bidding', 'calculated', 'held' then
      return 'aceptada'::public.estado_orden;
    when 'partially_filled' then
      return 'parcialmente_llenada'::public.estado_orden;
    when 'filled' then
      return 'llenada'::public.estado_orden;
    when 'canceled', 'done_for_day' then
      return 'cancelada'::public.estado_orden;
    when 'expired' then
      return 'vencida'::public.estado_orden;
    when 'rejected', 'suspended', 'stopped' then
      return 'rechazada'::public.estado_orden;
    when 'pending_cancel', 'pending_replace', 'replaced' then
      return null;
    else
      raise exception 'Estado del broker desconocido: %', p_estado using errcode = '22023';
  end case;
end;
$$;

comment on function private.estado_desde_broker(text) is
  'Correspondencia de docs/08 §2.1: estado crudo de Alpaca → estado de la orden. Nulo para pending_cancel, pending_replace y replaced (se conserva el estado). Un estado desconocido falla.';

-- Un llenado de compra: libera la retención que le toca, mueve efectivo a invertido y suma a la posición.
create function private.aplicar_compra(
  p_orden        public.ordenes,
  p_cantidad     numeric,
  p_monto        numeric,
  p_comisiones   numeric
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_costo     numeric(14,2) := p_monto + p_comisiones;
  v_pendiente numeric := p_orden.cantidad - p_orden.cantidad_llenada;
  v_liberar   numeric(14,2);
  v_pos       public.posiciones;
begin
  -- RN-23: al llenarse se libera la retención y se descuenta el costo real. Con un llenado parcial se libera la
  -- parte proporcional; el resto lo libera el cierre de la orden. Primero se libera y luego se mueve el efectivo
  -- para que `retenido <= efectivo` se cumpla en todo momento.
  v_liberar := case
    when p_cantidad >= v_pendiente then p_orden.retencion
    else least(p_orden.retencion, round(p_orden.retencion * p_cantidad / v_pendiente, 2))
  end;
  if v_liberar > 0 then
    update public.ordenes set retencion = retencion - v_liberar where id = p_orden.id;
    update public.subcuentas set retenido = greatest(retenido - v_liberar, 0), version = version + 1
     where id = p_orden.subcuenta_id;
  end if;

  if v_costo > 0 then
    perform private.registrar_movimiento(
      'compra',
      jsonb_build_array(
        jsonb_build_object('subcuenta_id', p_orden.subcuenta_id, 'concepto', 'efectivo', 'monto', -v_costo),
        jsonb_build_object('subcuenta_id', p_orden.subcuenta_id, 'concepto', 'invertido', 'monto', v_costo)),
      jsonb_build_object('tabla', 'ordenes', 'id', p_orden.id),
      'Compra de ' || p_orden.simbolo,
      jsonb_build_object('simbolo', p_orden.simbolo, 'cantidad', p_cantidad, 'comisiones', p_comisiones),
      null
    );
  end if;

  select * into v_pos from public.posiciones
   where subcuenta_id = p_orden.subcuenta_id and simbolo = p_orden.simbolo and estado <> 'cerrada'
     for update;
  if not found then
    insert into public.posiciones (subcuenta_id, simbolo, cantidad, costo_promedio, costo_total, abierta_en)
    values (p_orden.subcuenta_id, p_orden.simbolo, p_cantidad, round(v_costo / p_cantidad, 6), v_costo, private.ahora())
    returning * into v_pos;
  else
    -- Costo promedio ponderado (docs/02 §6.2): 6 a 50,00 + 4 a 60,00 = 10 a 54,00.
    update public.posiciones set
      cantidad       = cantidad + p_cantidad,
      costo_total    = costo_total + v_costo,
      costo_promedio = round((costo_total + v_costo) / (cantidad + p_cantidad), 6),
      version        = version + 1
    where id = v_pos.id returning * into v_pos;
  end if;
  update public.ordenes set posicion_id = v_pos.id where id = p_orden.id;
end;
$$;
revoke all on function private.aplicar_compra(public.ordenes, numeric, numeric, numeric) from public, anon, authenticated, service_role;

-- Un llenado de venta: el costo vuelve a la subcuenta y la diferencia contra lo recibido va a `resultados`.
-- El reparto de la ganancia (RN-26) lo agrega HU-023.
create function private.aplicar_venta(
  p_orden        public.ordenes,
  p_cantidad     numeric,
  p_monto        numeric,
  p_comisiones   numeric
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_pos        public.posiciones;
  v_sub        public.subcuentas;
  v_costo      numeric(14,2);
  v_recibido   numeric(14,2) := p_monto - p_comisiones;
  v_resultado  numeric(14,2);
  v_resultados uuid;
  v_asientos   jsonb;
begin
  select * into v_sub from public.subcuentas where id = p_orden.subcuenta_id for update;
  select * into v_pos from public.posiciones
   where subcuenta_id = p_orden.subcuenta_id and simbolo = p_orden.simbolo and estado <> 'cerrada'
     for update;
  if not found or v_pos.cantidad < p_cantidad then
    raise exception 'POSICION_INSUFICIENTE' using detail = p_orden.simbolo;
  end if;

  -- RN-27 y RN-25: el costo de lo vendido vuelve completo; el costo promedio de lo que queda no cambia. Si se
  -- vende todo, se usa el costo que queda para no dejar centavos sueltos.
  v_costo := case when p_cantidad = v_pos.cantidad then v_pos.costo_total
                  else round(p_cantidad * v_pos.costo_promedio, 2) end;
  v_resultado := v_recibido - v_costo;                       -- docs/02 §7.1

  select s.id into v_resultados from public.subcuentas s where s.tipo = 'resultados';
  if v_resultados is null then
    raise exception 'NO_EXISTE' using detail = 'Falta la subcuenta resultados.';
  end if;

  v_asientos := '[]'::jsonb
    || case when v_recibido <> 0 then jsonb_build_array(
         jsonb_build_object('subcuenta_id', v_sub.id, 'concepto', 'efectivo', 'monto', v_recibido)) else '[]'::jsonb end
    || case when v_costo <> 0 then jsonb_build_array(
         jsonb_build_object('subcuenta_id', v_sub.id, 'concepto', 'invertido', 'monto', -v_costo)) else '[]'::jsonb end
    || case when v_resultado <> 0 then jsonb_build_array(
         jsonb_build_object('subcuenta_id', v_resultados, 'concepto', 'efectivo', 'monto', -v_resultado)) else '[]'::jsonb end;
  if jsonb_array_length(v_asientos) > 0 then
    perform private.registrar_movimiento(
      'venta', v_asientos,
      jsonb_build_object('tabla', 'ordenes', 'id', p_orden.id),
      'Venta de ' || p_orden.simbolo,
      jsonb_build_object('simbolo', p_orden.simbolo, 'cantidad', p_cantidad, 'costo', v_costo,
                         'recibido', v_recibido, 'resultado', v_resultado),
      null
    );
  end if;

  update public.posiciones set
    cantidad            = cantidad - p_cantidad,
    costo_total         = costo_total - v_costo,
    resultado_realizado = resultado_realizado + v_resultado,
    estado              = case when cantidad - p_cantidad = 0 then 'cerrada'::public.estado_posicion else estado end,
    cerrada_en          = case when cantidad - p_cantidad = 0 then private.ahora() else cerrada_en end,
    version             = version + 1
  where id = v_pos.id;
  update public.ordenes set posicion_id = v_pos.id where id = p_orden.id;
end;
$$;
revoke all on function private.aplicar_venta(public.ordenes, numeric, numeric, numeric) from public, anon, authenticated, service_role;

create function private.aplicar_llenado(
  p_orden_id        uuid,
  p_cantidad_total  numeric,
  p_precio_promedio numeric,
  p_estado_broker   text,
  p_comisiones      numeric default 0
)
returns public.ordenes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_orden       public.ordenes;
  v_nuevo       public.estado_orden;
  v_delta       numeric;
  v_monto_total numeric(14,2);
  v_ahora       timestamptz := private.ahora();
begin
  if p_cantidad_total is null or p_cantidad_total < 0 or p_comisiones is null or p_comisiones < 0
     or (p_cantidad_total > 0 and (p_precio_promedio is null or p_precio_promedio <= 0)) then
    raise exception 'Llenado inválido' using errcode = '22023';
  end if;

  select * into v_orden from public.ordenes where id = p_orden_id for update;
  if not found then
    raise exception 'NO_EXISTE';
  end if;

  -- Una orden terminada solo admite el mismo llenado que ya tiene (idempotencia).
  if v_orden.estado in ('llenada', 'cancelada', 'vencida', 'rechazada', 'error_envio') then
    if p_cantidad_total = v_orden.cantidad_llenada then
      return v_orden;
    end if;
    raise exception 'ESTADO_INVALIDO' using detail = v_orden.estado::text;
  end if;
  if v_orden.estado not in ('aceptada', 'parcialmente_llenada') then
    raise exception 'ESTADO_INVALIDO' using detail = v_orden.estado::text;
  end if;
  if p_cantidad_total < v_orden.cantidad_llenada or p_cantidad_total > v_orden.cantidad then
    raise exception 'La cantidad llenada no puede bajar ni superar la de la orden' using errcode = '22023';
  end if;

  v_delta := p_cantidad_total - v_orden.cantidad_llenada;
  if v_delta > 0 then
    v_monto_total := round(p_cantidad_total * p_precio_promedio, 2);
    if v_orden.lado = 'compra' then
      perform private.aplicar_compra(v_orden, v_delta, v_monto_total - v_orden.monto_llenado,
                                     greatest(p_comisiones - v_orden.comisiones, 0));
    else
      perform private.aplicar_venta(v_orden, v_delta, v_monto_total - v_orden.monto_llenado,
                                    greatest(p_comisiones - v_orden.comisiones, 0));
    end if;
  end if;

  -- Estado que sigue: lo llenado manda sobre lo que diga el broker (docs/08 §2.2).
  v_nuevo := coalesce(private.estado_desde_broker(p_estado_broker), v_orden.estado);
  if p_cantidad_total >= v_orden.cantidad then
    v_nuevo := 'llenada'::public.estado_orden;
  elsif v_nuevo in ('aceptada', 'parcialmente_llenada') then
    v_nuevo := case when p_cantidad_total > 0 then 'parcialmente_llenada'::public.estado_orden
                    else 'aceptada'::public.estado_orden end;
  end if;

  update public.ordenes set
    cantidad_llenada        = p_cantidad_total,
    monto_llenado           = case when v_delta > 0 then v_monto_total else monto_llenado end,
    precio_promedio_llenado = case when p_cantidad_total > 0 then p_precio_promedio else precio_promedio_llenado end,
    comisiones              = greatest(p_comisiones, comisiones),
    broker_estado           = coalesce(p_estado_broker, broker_estado),
    llenada_en              = case when v_nuevo = 'llenada' then v_ahora else llenada_en end
  where id = p_orden_id returning * into v_orden;

  if v_nuevo <> v_orden.estado or v_delta > 0 then
    v_orden := private.cambiar_estado_orden(
      p_orden_id, v_nuevo,
      jsonb_build_object('estado_broker', p_estado_broker),
      null, case when v_delta > 0 then p_cantidad_total end, case when v_delta > 0 then p_precio_promedio end
    );
  end if;
  return v_orden;
end;
$$;

comment on function private.aplicar_llenado(uuid, numeric, numeric, text, numeric) is
  'Aplica lo que el broker reporta de una orden: libro (compra o venta), posición, retención y estado; en una venta, el costo vuelve a la subcuenta y el resultado va a resultados. Recibe totales y aplica la diferencia: llamarla dos veces con lo mismo no cambia nada.';
revoke all on function private.aplicar_llenado(uuid, numeric, numeric, text, numeric) from public, anon, authenticated, service_role;

-- Órdenes que la sincronización debe mirar: vivas en el broker o en duda (docs/10 §7).
create function private.ordenes_para_sincronizar()
returns table (orden_id uuid, broker_order_id text, estado public.estado_orden)
language sql
stable
security definer
set search_path = ''
as $$
  select o.id, o.broker_order_id, o.estado
    from public.ordenes o
   where o.estado in ('aceptada', 'parcialmente_llenada', 'desconocida')
   order by o.creado_en
$$;

comment on function private.ordenes_para_sincronizar() is
  'Órdenes aceptadas, parcialmente llenadas o desconocidas: las que sincronizar-ordenes consulta al broker.';

-- Compras cuya entrada lleva más de `ejecucion.minutos_max_llenado` minutos sin llenarse del todo (CB-35). El
-- activo en halt (CB-39) cae aquí también. Lo ya llenado se conserva.
create function private.ordenes_por_cancelar_por_tiempo()
returns table (orden_id uuid, broker_order_id text)
language sql
stable
security definer
set search_path = ''
as $$
  select o.id, o.broker_order_id
    from public.ordenes o
   where o.lado = 'compra'
     and o.estado in ('aceptada', 'parcialmente_llenada')
     and o.broker_order_id is not null
     and o.enviada_en <= private.ahora() - make_interval(mins => private.parametro_numerico('ejecucion.minutos_max_llenado')::int)
$$;

comment on function private.ordenes_por_cancelar_por_tiempo() is
  'Compras aceptadas o parciales que superaron ejecucion.minutos_max_llenado: sincronizar-ordenes las cancela en el broker (CB-35, CB-39).';

create function private.hay_ordenes_vivas()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.ordenes o where o.estado in ('aceptada', 'parcialmente_llenada', 'desconocida')
  )
$$;

comment on function private.hay_ordenes_vivas() is
  'Verdadero si hay órdenes que sincronizar (condición del trabajo sincronizar_ordenes).';

revoke all on function private.ordenes_para_sincronizar() from public, anon, authenticated, service_role;
revoke all on function private.ordenes_por_cancelar_por_tiempo() from public, anon, authenticated, service_role;
revoke all on function private.hay_ordenes_vivas() from public, anon, authenticated, service_role;

-- Trabajo sincronizar_ordenes (docs/05 §7): cada 10 s, solo si existen órdenes vivas.
select cron.schedule(
  'sincronizar_ordenes',
  '10 seconds',
  $$select private.despertar_funcion('sincronizar-ordenes') where private.hay_ordenes_vivas()$$
);

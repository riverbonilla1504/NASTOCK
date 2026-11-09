-- HU-073 · private.tomar_orden_para_envio: bloquea la orden, la revalida y la marca `enviada`.
-- Fuentes: docs/06 §8, docs/08 §1 y §2, docs/10 §5 y §10, docs/02 RR-12 (banda de precio), docs/12 CB-33.
--
-- Revalidación (CA-1 y CA-4): el motor de políticas (`private.validar_operacion`, HU-037; cubre interruptor
-- RR-14, horario RR-07, salud del broker RR-21, cotización fresca RR-11, fondos RR-03, conciliación RR-22…)
-- más la banda de precio RR-12, que el motor no cubre. Si falla, la orden queda en error_envio con las reglas
-- como motivo y se libera su retención (docs/08 §2.2).
--
-- Resultados (jsonb, campo `resultado`):
--   enviar          la orden estaba `creada` y pasó la revalidación: ahora es `enviada`; el ejecutor la envía.
--   consultar       la orden ya estaba `enviada` o `desconocida` (un envío anterior no cerró): el ejecutor
--                   consulta al broker por client_order_id antes de volver a enviar (docs/08 §2.2).
--   fallida         no pasó la revalidación; `reglas` trae los códigos.
--   ya_resuelta     la orden ya no necesita envío (aceptada, llenada…); el ejecutor confirma el mensaje.
-- Solo avanza desde `creada`: dos ejecutores a la vez no envían dos veces (docs/08 §7).

create function private.tomar_orden_para_envio(p_orden_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_orden    public.ordenes;
  v_reglas   text[];
  v_monto    numeric;
  v_stop_pct numeric;
  v_ref      numeric;
  v_precio   numeric;
  v_banda    numeric;
  v_datos    jsonb;
begin
  select * into v_orden from public.ordenes where id = p_orden_id for update;
  if not found then
    raise exception 'NO_EXISTE';
  end if;

  v_datos := jsonb_build_object(
    'id', v_orden.id, 'estado', v_orden.estado, 'simbolo', v_orden.simbolo, 'lado', v_orden.lado, 'clase', v_orden.clase,
    'tif', v_orden.tif, 'cantidad', v_orden.cantidad, 'precio_limite', v_orden.precio_limite,
    'bracket_stop_precio', v_orden.bracket_stop_precio, 'bracket_objetivo_precio', v_orden.bracket_objetivo_precio
  );

  if v_orden.estado in ('enviada', 'desconocida') then
    update public.ordenes set intentos_envio = intentos_envio + 1 where id = p_orden_id;
    return jsonb_build_object('resultado', 'consultar', 'orden', v_datos);
  end if;
  if v_orden.estado <> 'creada' then
    return jsonb_build_object('resultado', 'ya_resuelta');
  end if;

  -- El MVP solo envía órdenes límite de acciones enteras (D-63, docs/10 §5).
  if v_orden.tipo <> 'limite' or v_orden.cantidad is null or v_orden.cantidad <> trunc(v_orden.cantidad)
     or v_orden.precio_limite is null then
    perform private.cambiar_estado_orden(p_orden_id, 'error_envio',
      jsonb_build_object('revalidacion', 'fuera_del_alcance_del_mvp'), 'ORDEN_NO_SOPORTADA');
    return jsonb_build_object('resultado', 'fallida', 'reglas', jsonb_build_array('ORDEN_NO_SOPORTADA'));
  end if;

  v_monto := v_orden.cantidad * v_orden.precio_limite;
  v_stop_pct := case
    when v_orden.lado = 'compra' and v_orden.bracket_stop_precio is not null
      then (v_orden.precio_limite - v_orden.bracket_stop_precio) / v_orden.precio_limite * 100
  end;

  -- La orden ya retiene su monto (RN-23): se descuenta mientras se revalida para que el motor no lo cuente
  -- dos veces contra el disponible (RR-03). Se restituye enseguida, dentro de la misma transacción.
  if v_orden.retencion > 0 then
    update public.subcuentas set retenido = retenido - v_orden.retencion where id = v_orden.subcuenta_id;
  end if;
  v_reglas := private.validar_operacion(
    v_orden.subcuenta_id, v_orden.simbolo, v_orden.lado::text, v_monto, v_orden.cantidad, v_stop_pct, null
  );
  if v_orden.retencion > 0 then
    update public.subcuentas set retenido = retenido + v_orden.retencion where id = v_orden.subcuenta_id;
  end if;

  -- RR-12 · banda de precio: el precio actual no se alejó más de X % del de referencia (compras).
  if v_orden.lado = 'compra' then
    v_ref := nullif(v_orden.parametros ->> 'precio_referencia', '')::numeric;
    select c.precio into v_precio from public.cotizaciones c where c.simbolo = v_orden.simbolo;
    v_banda := private.parametro_numerico('sugerencias.banda_precio_pct');
    if v_ref is null or v_ref <= 0 or v_precio is null
       or abs(v_precio - v_ref) / v_ref * 100 > v_banda then
      v_reglas := array_append(v_reglas, 'RR-12'::text);
    end if;
  end if;

  if coalesce(array_length(v_reglas, 1), 0) > 0 then
    perform private.cambiar_estado_orden(p_orden_id, 'error_envio',
      jsonb_build_object('revalidacion', to_jsonb(v_reglas)), array_to_string(v_reglas, ','));
    return jsonb_build_object('resultado', 'fallida', 'reglas', to_jsonb(v_reglas));
  end if;

  perform private.cambiar_estado_orden(p_orden_id, 'enviada');
  update public.ordenes set intentos_envio = intentos_envio + 1 where id = p_orden_id;
  return jsonb_build_object('resultado', 'enviar', 'orden', v_datos);
end;
$$;

comment on function private.tomar_orden_para_envio(uuid) is
  'Bloquea la orden y la revalida con private.validar_operacion y la banda RR-12. Devuelve {resultado: enviar|consultar|fallida|ya_resuelta, orden|reglas}. Solo avanza desde creada (docs/08 §7).';
revoke all on function private.tomar_orden_para_envio(uuid) from public, anon, authenticated, service_role;

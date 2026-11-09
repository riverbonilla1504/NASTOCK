-- HU-023 · Reparto de la ganancia realizada y absorción de pérdidas, dentro de private.aplicar_venta.
-- Fuentes: docs/02 §7.1 a §7.3 (RN-26 a RN-30, ejemplo del cupo de Ana), RN-09 (redondeo), docs/06 §4.2
-- (asientos de `venta` y `reparto_ganancia`), docs/12 CB-17, CB-18 y CB-19, docs/13 D-03, D-04 y D-19.
--
-- La venta ya devolvía el costo completo a la subcuenta y mandaba la diferencia a `resultados` (HU-074, RN-27).
-- Ahora, si hay ganancia realizada (> 0), la reparte en el mismo llenado con los porcentajes vigentes al llenarse
-- (CB-17), que quedan guardados en el movimiento `reparto_ganancia`:
--   · venta en un cupo:        50 % Reserva · 25 % Arriesgadas · 25 % se queda en el mismo cupo (D-04)
--   · venta en Arriesgadas:    50 % Reserva · 25 % se queda · 25 % a `usuarios_comun`
-- Las partes de Arriesgadas y de Usuarios se truncan a centavos y la Reserva recibe el resto (RN-30, CB-18).
-- Una pérdida la absorbe completa la subcuenta que vendió y no se reparte (RN-28). El reparto es por operación
-- cerrada, no neto por periodo (RN-29, D-19).
--
-- MVP corto (D-64): solo operan los cupos; la rama de Arriesgadas está porque la historia la pide (CA-2) y
-- porque cualquier venta de una subcuenta con ganancia debe tener destino, pero hoy nada la dispara.


-- Porcentajes vigentes del reparto (RN-26, RN-30). Devuelve reserva, arriesgadas y usuarios.
create function private.porcentajes_de_reparto()
returns table (pct_reserva numeric, pct_arriesgadas numeric, pct_usuarios numeric)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  pct_reserva := private.parametro_numerico('reparto.pct_reserva');
  pct_arriesgadas := private.parametro_numerico('reparto.pct_arriesgadas');
  pct_usuarios := private.parametro_numerico('reparto.pct_usuarios');
  if pct_reserva + pct_arriesgadas + pct_usuarios <> 100 then
    raise exception 'Los porcentajes de reparto no suman 100' using errcode = '22023';
  end if;
  return next;
end;
$$;
revoke all on function private.porcentajes_de_reparto() from public, anon, authenticated, service_role;

-- Un llenado de venta: el costo vuelve a la subcuenta, el resultado va a `resultados` y la ganancia se reparte
-- (RN-26). Reemplaza la versión de 20261110130005, que dejaba la ganancia entera en la subcuenta.
create or replace function private.aplicar_venta(
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
  v_reserva    uuid;
  v_arriesg    uuid;
  v_comun      uuid;
  v_pct        record;
  v_arr        numeric(14,2);
  v_usu        numeric(14,2);
  v_res        numeric(14,2);
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

  -- RN-26: toda ganancia realizada (> 0) se reparte en el momento de la venta con los porcentajes vigentes
  -- (CB-17), que quedan guardados en el movimiento. RN-28: una pérdida la absorbe la subcuenta, sin reparto.
  if v_resultado > 0 then
    select * into v_pct from private.porcentajes_de_reparto();
    -- RN-30 (igual que RN-09): las partes de arriesgadas y usuarios se truncan; la Reserva recibe el resto.
    v_arr := trunc(v_resultado * v_pct.pct_arriesgadas / 100, 2);
    v_usu := trunc(v_resultado * v_pct.pct_usuarios / 100, 2);
    v_res := v_resultado - v_arr - v_usu;
    select s.id into v_reserva from public.subcuentas s where s.tipo = 'reserva';
    select s.id into v_arriesg from public.subcuentas s where s.tipo = 'arriesgadas';
    select s.id into v_comun from public.subcuentas s where s.tipo = 'usuarios_comun';

    if v_sub.tipo = 'cupo' then
      -- Reserva y Arriesgadas reciben su parte; la del Usuario se queda en el mismo cupo.
      v_asientos := '[]'::jsonb
        || case when v_res + v_arr > 0 then jsonb_build_array(
             jsonb_build_object('subcuenta_id', v_sub.id, 'concepto', 'efectivo', 'monto', -(v_res + v_arr))) else '[]'::jsonb end
        || case when v_res > 0 then jsonb_build_array(
             jsonb_build_object('subcuenta_id', v_reserva, 'concepto', 'efectivo', 'monto', v_res)) else '[]'::jsonb end
        || case when v_arr > 0 then jsonb_build_array(
             jsonb_build_object('subcuenta_id', v_arriesg, 'concepto', 'efectivo', 'monto', v_arr)) else '[]'::jsonb end;
    elsif v_sub.tipo = 'arriesgadas' then
      -- La parte de Arriesgadas se queda; la de Usuarios va a usuarios_comun.
      v_asientos := '[]'::jsonb
        || case when v_res + v_usu > 0 then jsonb_build_array(
             jsonb_build_object('subcuenta_id', v_sub.id, 'concepto', 'efectivo', 'monto', -(v_res + v_usu))) else '[]'::jsonb end
        || case when v_res > 0 then jsonb_build_array(
             jsonb_build_object('subcuenta_id', v_reserva, 'concepto', 'efectivo', 'monto', v_res)) else '[]'::jsonb end
        || case when v_usu > 0 then jsonb_build_array(
             jsonb_build_object('subcuenta_id', v_comun, 'concepto', 'efectivo', 'monto', v_usu)) else '[]'::jsonb end;
    else
      raise exception 'Solo operan Arriesgadas y los cupos' using errcode = '22023';
    end if;

    if jsonb_array_length(v_asientos) > 0 then
      perform private.registrar_movimiento(
        'reparto_ganancia', v_asientos,
        jsonb_build_object('tabla', 'ordenes', 'id', p_orden.id),
        'Reparto de la ganancia de ' || p_orden.simbolo,
        jsonb_build_object('ganancia', v_resultado, 'reparto', jsonb_build_object(
          'pct_reserva', v_pct.pct_reserva, 'pct_arriesgadas', v_pct.pct_arriesgadas,
          'pct_usuarios', v_pct.pct_usuarios)),
        null
      );
    end if;
  end if;
end;
$$;
revoke all on function private.aplicar_venta(public.ordenes, numeric, numeric, numeric) from public, anon, authenticated, service_role;

comment on function private.porcentajes_de_reparto() is
  'Porcentajes vigentes del reparto (reserva, arriesgadas, usuarios) leídos de parametros; deben sumar 100 (RN-08, RN-26).';
comment on function private.aplicar_venta(public.ordenes, numeric, numeric, numeric) is
  'Un llenado de venta: el costo vuelve a la subcuenta (RN-27), el resultado va a resultados y la ganancia se reparte con los porcentajes vigentes (RN-26, RN-30); una pérdida la absorbe la subcuenta (RN-28).';
comment on function private.aplicar_llenado(uuid, numeric, numeric, text, numeric) is
  'Aplica lo que el broker reporta de una orden: libro (compra o venta), posición, retención y estado; en una venta con ganancia, reparte la ganancia (RN-26). Recibe totales y aplica la diferencia: llamarla dos veces con lo mismo no cambia nada.';

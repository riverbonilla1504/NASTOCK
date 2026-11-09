-- HU-075 · RPC crear_orden_manual: el Usuario compra o vende en su cupo.
-- Fuentes: docs/06 §8.1 (firma) y §9 (códigos de error), docs/08 §7.5 (orden manual) y §2 (estados), docs/10
-- §5 (órdenes que usamos: bracket límite gtc para comprar, límite day para vender; precios de stop y objetivo
-- sobre la referencia), docs/02 §6 (compras), RN-23 (retención), RN-24 (límite con banda), RR-03, RR-06,
-- RR-08, docs/03 PM-12, docs/11 §4 (acción `orden.manual_creada`), docs/14 §4.1 (D-60, D-61, D-63, D-64, D-65).
--
-- MVP corto: sin opinión de la IA (D-60, no hay `opinion_id`), solo acciones enteras (D-63), solo el cupo del
-- Usuario, cuyo bolsillo es Usuarios (D-64). La orden nace `creada` con origen `manual`; el trigger de la
-- migración de órdenes la pone en `ordenes_por_enviar` y el ejecutor (HU-073) la revalida y la envía.
--
-- Firma (precisa la de docs/06 §8.1): el id de la orden lo genera la app y es la clave de idempotencia (CA-3,
-- docs/08 §7.5). La cantidad es de acciones enteras; el monto lo calcula la función (cantidad × precio límite),
-- así que no se recibe.
--
-- Precios (docs/10 §5): referencia = última cotización. Compra: límite = referencia × (1 + banda) redondeado
-- hacia arriba al centavo; stop y objetivo = referencia × (1 − stop %) y × (1 + objetivo %), al centavo. Venta:
-- límite = referencia × (1 − banda) redondeado hacia abajo al centavo. La banda es `sugerencias.banda_precio_pct`.
-- Al validar, el stop se mide contra el límite, como lo hará `tomar_orden_para_envio` al enviar: así lo que pasa
-- aquí no falla en el envío por redondeos.
--
-- Códigos de error (docs/06 §9): SESION_INVALIDA, NO_AUTORIZADO, NO_EXISTE (sin cupo abierto),
-- PARAMETRO_FUERA_DE_RANGO (cantidad no entera o menor que 1, stop u objetivo inválido),
-- MERCADO_CERRADO (con la hora de apertura en DETAIL), FUERA_DE_VENTANA, TRADING_PAUSADO, INTEGRACION_CAIDA,
-- DATO_DESACTUALIZADO, FONDOS_INSUFICIENTES y REGLA_RR_xx para las demás reglas del motor de políticas.
-- DETAIL lleva todas las reglas violadas separadas por coma.

create function public.crear_orden_manual(
  p_id           uuid,
  p_simbolo      text,
  p_lado         text,
  p_cantidad     numeric,
  p_stop_pct     numeric default null,
  p_objetivo_pct numeric default null
)
returns public.ordenes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor    uuid := (select auth.uid());
  v_rol      public.rol_app := private.rol_actual();
  v_ahora    timestamptz := private.ahora();
  v_simbolo  text := upper(btrim(coalesce(p_simbolo, '')));
  v_compra   boolean := p_lado = 'compra';
  v_sub      public.subcuentas;
  v_previa   public.ordenes;
  v_orden    public.ordenes;
  v_ref      numeric;
  v_banda    numeric;
  v_limite   numeric(14,4);
  v_stop_pct numeric;
  v_obj_pct  numeric;
  v_stop_px  numeric(14,4);
  v_obj_px   numeric(14,4);
  v_stop_vs_limite numeric;
  v_monto    numeric(14,2);
  v_reglas   text[];
  v_tenida   numeric;
  v_apertura timestamptz;
  v_codigo   text;
begin
  -- (1) Sesión activa y rol (CA-6). rol_actual() es nulo si la cuenta no está activa.
  if v_rol is null then
    raise exception 'SESION_INVALIDA';
  end if;
  if v_rol <> 'usuario' then
    raise exception 'NO_AUTORIZADO';
  end if;

  -- Forma de los datos.
  if p_id is null then
    raise exception 'La orden necesita un id' using errcode = '22023';
  end if;
  if p_lado is null or p_lado not in ('compra', 'venta') then
    raise exception 'El lado debe ser compra o venta' using errcode = '22023';
  end if;
  if v_simbolo !~ '^[A-Z][A-Z.]{0,5}$' then
    raise exception 'El símbolo no es válido' using errcode = '22023';
  end if;
  if p_cantidad is null or p_cantidad < 1 or p_cantidad <> trunc(p_cantidad) then
    raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = 'La cantidad debe ser un número entero de acciones, de 1 en adelante.';
  end if;

  -- (2) El cupo de quien llama. Se bloquea: dos órdenes a la vez no gastan dos veces el mismo disponible, y un
  -- reintento con el mismo id espera a que termine el primero.
  select s.* into v_sub
    from public.subcuentas s
   where s.usuario_id = v_actor and s.tipo = 'cupo' and s.estado = 'abierta'
     for update;
  if not found then
    raise exception 'NO_EXISTE' using detail = 'La persona no tiene un cupo abierto.';
  end if;

  -- (3) Idempotencia (CA-3): el mismo id devuelve la misma orden, sin duplicarla ni retener otra vez. Un id que
  -- es de otro cupo no se revela.
  select o.* into v_previa from public.ordenes o where o.id = p_id;
  if found then
    if v_previa.subcuenta_id <> v_sub.id then
      raise exception 'NO_AUTORIZADO';
    end if;
    return v_previa;
  end if;

  -- (4) Precios. Sin cotización no hay referencia: el dato no está actualizado.
  select c.precio into v_ref from public.cotizaciones c where c.simbolo = v_simbolo;
  if v_ref is null or v_ref <= 0 then
    raise exception 'DATO_DESACTUALIZADO';
  end if;
  v_banda := private.parametro_numerico('sugerencias.banda_precio_pct');

  if v_compra then
    v_stop_pct := coalesce(p_stop_pct, private.parametro_numerico('riesgo.cupo.stop_defecto_pct'));
    v_obj_pct := coalesce(p_objetivo_pct, private.parametro_numerico('riesgo.cupo.objetivo_defecto_pct'));
    if v_obj_pct <= 0 or v_stop_pct <= 0 or v_stop_pct >= 100 then
      raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = 'El stop y el objetivo deben ser porcentajes positivos.';
    end if;
    v_limite := ceil(v_ref * (1 + v_banda / 100) * 100) / 100;
    v_stop_px := round(v_ref * (1 - v_stop_pct / 100), 2);
    v_obj_px := round(v_ref * (1 + v_obj_pct / 100), 2);
    if v_stop_px <= 0 then
      raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = 'El stop deja el precio en cero o menos.';
    end if;
    v_stop_vs_limite := (v_limite - v_stop_px) / v_limite * 100;
  else
    v_limite := floor(v_ref * (1 - v_banda / 100) * 100) / 100;
    if v_limite <= 0 then
      raise exception 'DATO_DESACTUALIZADO';
    end if;
  end if;
  v_monto := round(p_cantidad * v_limite, 2);

  -- (5) Motor de políticas (RN-38): el mismo que revalida al enviar.
  v_reglas := private.validar_operacion(v_sub.id, v_simbolo, p_lado, v_monto, p_cantidad, v_stop_vs_limite, null);

  -- Sin cortos (RR-15, docs/02 §9): no se vende más de lo que la posición tiene libre de otras ventas vivas.
  if not v_compra then
    select coalesce(sum(p.cantidad), 0) into v_tenida
      from public.posiciones p
     where p.subcuenta_id = v_sub.id and p.simbolo = v_simbolo and p.estado = 'abierta';
    v_tenida := v_tenida - coalesce((
      select sum(o.cantidad - o.cantidad_llenada)
        from public.ordenes o
       where o.subcuenta_id = v_sub.id and o.simbolo = v_simbolo and o.lado = 'venta'
         and o.estado in ('creada', 'enviada', 'desconocida', 'aceptada', 'parcialmente_llenada')
    ), 0);
    if p_cantidad > v_tenida and not ('RR-15' = any (v_reglas)) then
      v_reglas := array_append(v_reglas, 'RR-15'::text);
    end if;
  end if;

  if coalesce(array_length(v_reglas, 1), 0) > 0 then
    if 'RR-07' = any (v_reglas) then
      -- Cerrado (sin sesión ahora) o dentro de los márgenes de la ventana de compras.
      if not exists (
        select 1 from public.calendario_mercado c where v_ahora >= c.apertura and v_ahora < c.cierre
      ) then
        select min(c.apertura) into v_apertura from public.calendario_mercado c where c.apertura > v_ahora;
        raise exception 'MERCADO_CERRADO'
          using detail = coalesce(to_char(v_apertura at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'), '');
      end if;
      v_codigo := 'FUERA_DE_VENTANA';
    elsif 'RR-14' = any (v_reglas) then
      v_codigo := 'TRADING_PAUSADO';
    elsif 'RR-21' = any (v_reglas) then
      v_codigo := 'INTEGRACION_CAIDA';
    elsif 'RR-11' = any (v_reglas) then
      v_codigo := 'DATO_DESACTUALIZADO';
    elsif 'RR-03' = any (v_reglas) then
      v_codigo := 'FONDOS_INSUFICIENTES';
    else
      v_codigo := 'REGLA_' || replace(v_reglas[1], '-', '_');
    end if;
    raise exception '%', v_codigo using detail = array_to_string(v_reglas, ',');
  end if;

  -- (6) Escritura: la orden y la retención (RN-23, solo compras) en la misma transacción. Al insertar, el
  -- trigger la encola en ordenes_por_enviar.
  insert into public.ordenes (
    id, origen, subcuenta_id, creada_por, simbolo, lado, clase, tipo, tif, cantidad, precio_limite,
    bracket_stop_precio, bracket_objetivo_precio, retencion, parametros
  ) values (
    p_id, 'manual', v_sub.id, v_actor, v_simbolo, p_lado::public.lado,
    case when v_compra then 'bracket' else 'simple' end::public.clase_orden,
    'limite', case when v_compra then 'gtc' else 'day' end,
    p_cantidad, v_limite,
    case when v_compra then v_stop_px end, case when v_compra then v_obj_px end,
    case when v_compra then v_monto else 0 end,
    jsonb_build_object(
      'precio_referencia', v_ref,
      'banda_pct', v_banda,
      'stop_pct', v_stop_pct,
      'objetivo_pct', v_obj_pct,
      'monto_estimado', v_monto,
      'orden_minima_usd', private.parametro_numerico('riesgo.orden_minima_usd'),
      'stop_min_pct', private.parametro_numerico('riesgo.cupo.stop_min_pct'),
      'stop_max_pct', private.parametro_numerico('riesgo.cupo.stop_max_pct')
    )
  )
  returning * into v_orden;

  if v_compra then
    update public.subcuentas
       set retenido = retenido + v_monto, version = version + 1
     where id = v_sub.id;
  end if;

  perform private.auditar(
    v_actor,
    'orden.manual_creada',
    'ordenes',
    v_orden.id::text,
    p_detalle => jsonb_build_object(
      'simbolo', v_simbolo, 'lado', p_lado, 'cantidad', p_cantidad, 'precio_limite', v_limite,
      'monto_estimado', v_monto, 'stop_pct', v_stop_pct, 'objetivo_pct', v_obj_pct
    )
  );

  return v_orden;
end;
$$;

comment on function public.crear_orden_manual(uuid, text, text, numeric, numeric, numeric) is
  'El Usuario compra o vende acciones enteras en su cupo (PM-12). El id lo genera la app y es la clave de idempotencia. Valida con private.validar_operacion, retiene el monto de una compra (RN-23), crea la orden manual y la encola. Errores: SESION_INVALIDA, NO_AUTORIZADO, NO_EXISTE, PARAMETRO_FUERA_DE_RANGO, MERCADO_CERRADO, FUERA_DE_VENTANA, TRADING_PAUSADO, INTEGRACION_CAIDA, DATO_DESACTUALIZADO, FONDOS_INSUFICIENTES, REGLA_RR_xx. Audita orden.manual_creada.';

revoke all on function public.crear_orden_manual(uuid, text, text, numeric, numeric, numeric) from public, anon;
grant execute on function public.crear_orden_manual(uuid, text, text, numeric, numeric, numeric) to authenticated;

-- HU-037 · Motor de políticas: reglas de la propuesta (private.validar_operacion).
-- Fuentes: docs/02 §9 (RR-01 a RR-22, RN-38) y §10 (parámetros), docs/06 §8.2, docs/03 §4.4 (autorización
-- fuera: este motor es interno), docs/14 §4.1 (D-58 a D-65: MVP corto).
--
-- Un solo motor, en la base de datos (RN-38): la IA, la app y el ejecutor lo llaman y ninguno reimplementa
-- reglas. Devuelve la lista de reglas violadas, p. ej. {RR-03,RR-07}; vacía = la operación cumple. Quien lo
-- llama responde a la app con `REGLA_RR_xx` (docs/06 §9, la app tiene el texto de cada regla).
--
-- Aquí van RR-01 a RR-09, RR-11, RR-14, RR-17, RR-18, RR-21 y RR-22. Las que dependen de sugerencias,
-- órdenes y posiciones (RR-10, RR-15, RR-16, RR-19, RR-20), las excepciones de protecciones y liquidaciones
-- y los cuatro momentos de llamada son de HU-038. RR-12 y RR-13 se aplican al aprobar y al enviar
-- (HU-062, HU-065, HU-073).
--
-- Decisiones sin regla explícita en docs/ (a validar):
--  * `p_momento` es la hora en que se evalúa (por defecto private.ahora()): sirve para el horario (RR-07)
--    y la frescura de la cotización (RR-11) y deja controlar el reloj en las pruebas.
--  * RR-14: toda operación exige `trading_activo`; si trae `p_confianza` (es una sugerencia de la IA),
--    exige además `ia_activa`.
--  * RR-18: lado distinto de compra y venta, cantidad no positiva o un símbolo que no es una acción o ETF
--    (por ejemplo, un contrato de opciones). Sin margen: la compra no puede superar el disponible (RR-03).
--  * RR-22: hay un descuadre crítico de la conciliación sin marcar como revisado.
--  * Patrimonio de la subcuenta = efectivo + invertido (a costo) mientras no existan las posiciones
--    valoradas; el valor ya tenido en el símbolo (RR-05) es 0 hasta que existan (private.valor_en_simbolo).

-- Lee un parámetro numérico del catálogo. Falla si no existe o no es un número (no hay un límite que aplicar).
create function private.parametro_numerico(p_clave text)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_valor jsonb;
begin
  select p.valor into v_valor from public.parametros p where p.clave = p_clave;
  if v_valor is null or jsonb_typeof(v_valor) <> 'number' then
    raise exception 'NO_EXISTE' using detail = p_clave;
  end if;
  return (v_valor #>> '{}')::numeric;
end;
$$;
comment on function private.parametro_numerico(text) is
  'Valor numérico de un parámetro del catálogo (docs/02 §10). NO_EXISTE si falta o no es un número.';
revoke all on function private.parametro_numerico(text) from public, anon, authenticated, service_role;

-- Valor de mercado que la subcuenta ya tiene en un símbolo (RR-05). Hasta que existan las posiciones es 0;
-- las historias de posiciones (E-08) reemplazan este cuerpo.
create function private.valor_en_simbolo(p_subcuenta uuid, p_simbolo text)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$ select 0::numeric $$;
comment on function private.valor_en_simbolo(uuid, text) is
  'Valor que la subcuenta tiene en un símbolo, para la concentración de RR-05. Vale 0 mientras no existan las posiciones.';
revoke all on function private.valor_en_simbolo(uuid, text) from public, anon, authenticated, service_role;

create function private.validar_operacion(
  p_subcuenta  uuid,
  p_simbolo    text,
  p_lado       text,
  p_monto      numeric,
  p_cantidad   numeric,
  p_stop_pct   numeric,
  p_confianza  numeric,
  p_momento    timestamptz default null
)
returns text[]
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_reglas   text[] := array[]::text[];
  v_sub      public.subcuentas;
  v_simbolo  text := upper(btrim(coalesce(p_simbolo, '')));
  v_ahora    timestamptz := coalesce(p_momento, private.ahora());
  v_compra   boolean := p_lado = 'compra';
  v_lado_ok  boolean := p_lado in ('compra', 'venta');
  v_prefijo  text;
  v_patrim   numeric;
  v_fondo    public.fondos;
  v_min      numeric;
  v_max      numeric;
  v_tras     integer;
  v_antes    integer;
  v_umbral   numeric;
  v_cotiz    timestamptz;
begin
  if p_monto is null then
    raise exception 'El monto de la operación no puede ser nulo' using errcode = '22023';
  end if;
  select * into v_sub from public.subcuentas s where s.id = p_subcuenta;
  if not found then
    raise exception 'NO_EXISTE' using detail = 'La subcuenta no existe.';
  end if;

  -- RR-18 · sin margen, sin cortos, sin opciones, sin horario extendido.
  if not v_lado_ok or (p_cantidad is not null and p_cantidad <= 0) or v_simbolo !~ '^[A-Z][A-Z.]{0,5}$' then
    v_reglas := array_append(v_reglas, 'RR-18'::text);
  end if;

  -- RR-02 · ninguna orden usa la Reserva ni usuarios_comun (ni externa ni resultados): solo Arriesgadas y cupos.
  if v_sub.tipo not in ('arriesgadas', 'cupo') then
    v_reglas := array_append(v_reglas, 'RR-02'::text);
  end if;

  -- RR-17 · el destinatario del cupo está activo.
  if v_sub.tipo = 'cupo' and not exists (
    select 1 from public.perfiles p where p.id = v_sub.usuario_id and p.estado = 'activo'
  ) then
    v_reglas := array_append(v_reglas, 'RR-17'::text);
  end if;

  -- Parámetros por tipo de subcuenta (solo Arriesgadas y cupos los tienen).
  v_prefijo := case v_sub.tipo when 'cupo' then 'riesgo.cupo.' when 'arriesgadas' then 'riesgo.arriesgadas.' end;
  v_patrim := v_sub.efectivo + v_sub.invertido;

  -- RR-01 · el símbolo está en la lista blanca activa del bolsillo (compras).
  if v_compra and not exists (
    select 1 from public.lista_blanca l
     where l.bolsillo = v_sub.bolsillo and l.simbolo = v_simbolo and l.activo
  ) then
    v_reglas := array_append(v_reglas, 'RR-01'::text);
  end if;

  -- RR-03 · el monto no supera el disponible (compras). Esto es también «sin margen» (RR-18).
  if v_compra and p_monto > v_sub.efectivo - v_sub.retenido then
    v_reglas := array_append(v_reglas, 'RR-03'::text);
  end if;

  if v_compra and v_prefijo is not null then
    -- RR-04 · monto por operación ≤ % del patrimonio.
    if p_monto > private.parametro_numerico(v_prefijo || 'max_pct_operacion') / 100 * v_patrim then
      v_reglas := array_append(v_reglas, 'RR-04'::text);
    end if;
    -- RR-05 · concentración: valor en el símbolo tras la compra ≤ % del patrimonio.
    if private.valor_en_simbolo(p_subcuenta, v_simbolo) + p_monto
         > private.parametro_numerico(v_prefijo || 'max_pct_simbolo') / 100 * v_patrim then
      v_reglas := array_append(v_reglas, 'RR-05'::text);
    end if;
    -- RR-08 · stop-loss obligatorio y dentro del rango del bolsillo.
    v_min := private.parametro_numerico(v_prefijo || 'stop_min_pct');
    v_max := private.parametro_numerico(v_prefijo || 'stop_max_pct');
    if p_stop_pct is null or p_stop_pct < v_min or p_stop_pct > v_max then
      v_reglas := array_append(v_reglas, 'RR-08'::text);
    end if;
  elsif v_compra and (p_stop_pct is null or p_stop_pct <= 0) then
    -- Sin tipo operable no hay rango, pero la compra igual necesita un stop.
    v_reglas := array_append(v_reglas, 'RR-08'::text);
  end if;

  -- RR-06 · monto mínimo de orden (compras y ventas).
  if p_monto < private.parametro_numerico('riesgo.orden_minima_usd') then
    v_reglas := array_append(v_reglas, 'RR-06'::text);
  end if;

  -- RR-07 · horario regular; las compras, entre apertura + N min y cierre − M min.
  if v_lado_ok then
    v_tras := case when v_compra then (select m.tras_apertura from private.margenes_de_compra() m) else 0 end;
    v_antes := case when v_compra then (select m.antes_cierre from private.margenes_de_compra() m) else 0 end;
    if not exists (
      select 1 from public.calendario_mercado c
       where v_ahora >= c.apertura + make_interval(mins => v_tras)
         and v_ahora < c.cierre - make_interval(mins => v_antes)
    ) then
      v_reglas := array_append(v_reglas, 'RR-07'::text);
    end if;
  end if;

  -- RR-09 · confianza de JEV ≥ mínima (solo las sugerencias de la IA traen confianza).
  if p_confianza is not null and v_lado_ok then
    v_umbral := private.parametro_numerico(case when v_compra then 'jev.confianza_minima' else 'jev.confianza_venta' end);
    if p_confianza < v_umbral then
      v_reglas := array_append(v_reglas, 'RR-09'::text);
    end if;
  end if;

  -- RR-11 · cotización fresca.
  select c.momento into v_cotiz from public.cotizaciones c where c.simbolo = v_simbolo;
  if v_cotiz is null
     or v_ahora - v_cotiz > make_interval(secs => private.parametro_numerico('mercado.max_antiguedad_cotizacion_seg')) then
    v_reglas := array_append(v_reglas, 'RR-11'::text);
  end if;

  -- RR-14 · interruptores. Toda operación exige trading_activo; una sugerencia de la IA, además ia_activa.
  select * into v_fondo from public.fondos limit 1;
  if not found or not v_fondo.trading_activo or (p_confianza is not null and not v_fondo.ia_activa) then
    v_reglas := array_append(v_reglas, 'RR-14'::text);
  end if;

  -- RR-21 · broker y datos de mercado en ok o degradado (con caido no se opera).
  if exists (
    select 1 from public.salud_integraciones s
     where s.integracion in ('alpaca_trading', 'alpaca_datos') and s.estado = 'caido'
  ) then
    v_reglas := array_append(v_reglas, 'RR-21'::text);
  end if;

  -- RR-22 · sin descuadre crítico abierto en la conciliación (compras).
  if v_compra and exists (
    select 1 from public.conciliaciones k where k.resultado = 'descuadre_critico' and k.revisada_en is null
  ) then
    v_reglas := array_append(v_reglas, 'RR-22'::text);
  end if;

  return v_reglas;
end;
$$;

comment on function private.validar_operacion(uuid, text, text, numeric, numeric, numeric, numeric, timestamptz) is
  'Motor de políticas único (RN-38): devuelve las reglas de riesgo violadas por una operación, p. ej. {RR-03,RR-07}; vacía = cumple. RR-01 a RR-09, RR-11, RR-14, RR-17, RR-18, RR-21 y RR-22; el resto, en HU-038.';
revoke all on function private.validar_operacion(uuid, text, text, numeric, numeric, numeric, numeric, timestamptz)
  from public, anon, authenticated, service_role;

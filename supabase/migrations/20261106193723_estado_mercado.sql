-- HU-027 · Ventana de compras y estado del mercado.
-- Fuentes: docs/02 §10 y RR-07 (compras solo entre apertura + 5 min y cierre − 15 min), docs/08 §6
-- (estados del mercado, calculados y no guardados), docs/06 §6 (estado_mercado()), docs/09 §1
-- (la app corrige su reloj local con la hora del servidor), CB-49 a CB-51.
--
-- Los márgenes salen de private.margenes_de_compra(), que hoy devuelve los defectos de docs/02 §10
-- porque la tabla `parametros` todavía no existe (la crea HU-002 y HU-033 completa su catálogo).
-- La frescura de los datos (datos_actualizados_en) queda nula: su insumo, `cotizaciones`, es de
-- HU-028, y cómo se define la frescura está pendiente de decisión (specs/027-…/plan.md, punto 3).

-- Márgenes de la ventana de compras, en minutos (docs/02 §10: mercado.minutos_tras_apertura = 5 y
-- mercado.minutos_antes_cierre = 15). Hoy devuelve los defectos documentados; cuando exista la tabla
-- `parametros` (HU-002/HU-033), solo cambia el cuerpo de esta función para leerlos de ahí.
create function private.margenes_de_compra()
returns table (tras_apertura integer, antes_cierre integer)
language sql
stable
security definer
set search_path = ''
as $$
  select 5, 15
$$;

comment on function private.margenes_de_compra() is
  'Minutos tras la apertura y antes del cierre en que no se compra (RR-07). Defectos de docs/02 §10; HU-033 los leerá de parametros.';

revoke all on function private.margenes_de_compra() from public, anon, authenticated;

-- ¿Se puede comprar ahora? Entre apertura + tras_apertura y cierre − antes_cierre de un día de mercado.
-- En una media jornada se calcula con el cierre real de las 13:00 (CB-50).
create function private.ventana_compras_abierta()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.calendario_mercado c
     cross join private.margenes_de_compra() m
     where private.ahora() >= c.apertura + make_interval(mins => m.tras_apertura)
       and private.ahora() < c.cierre - make_interval(mins => m.antes_cierre)
  )
$$;

comment on function private.ventana_compras_abierta() is
  'Verdadero si ahora está entre apertura + minutos_tras_apertura y cierre − minutos_antes_cierre (RR-07).';

revoke all on function private.ventana_compras_abierta() from public, anon, authenticated;

-- Estado del mercado: lo calcula, no lo guarda (docs/08 §6).
--   cerrado → pre_apertura (10 min antes) → abierto_sin_compras (primeros minutos) → abierto →
--   cierre_proximo (últimos minutos, sin compras) → cerrado
-- Un feriado no tiene fila y el estado es `cerrado` todo el día (CB-49).
create function public.estado_mercado()
returns table (
  estado                  text,
  abierto                 boolean,
  ahora                   timestamptz,
  proxima_apertura        timestamptz,
  proximo_cierre          timestamptz,
  compras_desde           timestamptz,
  compras_hasta           timestamptz,
  ventana_compras_abierta boolean,
  sesion                  text,
  datos_actualizados_en   timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_ahora     timestamptz := private.ahora();
  v_dia       public.calendario_mercado;
  v_tras      integer;
  v_antes     integer;
  v_desde     timestamptz;
  v_hasta     timestamptz;
  v_estado    text;
begin
  -- Toda persona con la cuenta activa (docs/03 §4.3); private.rol_actual() es nulo si no lo está.
  if private.rol_actual() is null then
    raise exception 'NO_AUTORIZADO';
  end if;

  select m.tras_apertura, m.antes_cierre into v_tras, v_antes from private.margenes_de_compra() m;

  -- La sesión de referencia: la que está en curso o, si no hay, la siguiente.
  select c.* into v_dia
    from public.calendario_mercado c
   where c.cierre > v_ahora
   order by c.cierre
   limit 1;

  if v_dia.fecha is null then
    return query select 'cerrado'::text, false, v_ahora, null::timestamptz, null::timestamptz,
                        null::timestamptz, null::timestamptz, false, null::text, null::timestamptz;
    return;
  end if;

  v_desde := v_dia.apertura + make_interval(mins => v_tras);
  v_hasta := v_dia.cierre - make_interval(mins => v_antes);

  v_estado := case
    when v_ahora >= v_dia.apertura and v_ahora >= v_hasta then 'cierre_proximo'
    when v_ahora >= v_desde then 'abierto'
    when v_ahora >= v_dia.apertura then 'abierto_sin_compras'
    when v_ahora >= v_dia.apertura - interval '10 minutes' then 'pre_apertura'
    else 'cerrado'
  end;

  return query
    select v_estado,
           v_ahora >= v_dia.apertura and v_ahora < v_dia.cierre,
           v_ahora,
           (select min(c.apertura) from public.calendario_mercado c where c.apertura > v_ahora),
           (select min(c.cierre) from public.calendario_mercado c where c.cierre > v_ahora),
           v_desde,
           v_hasta,
           v_ahora >= v_desde and v_ahora < v_hasta,
           v_dia.sesion,
           -- Frescura de los datos: pendiente de HU-028 (cotizaciones) y de su definición en docs/.
           null::timestamptz;
end;
$$;

comment on function public.estado_mercado() is
  'Estado del mercado calculado desde calendario_mercado y private.ahora(): estado, próxima apertura y cierre, ventana de compras y frescura de los datos (docs/06 §6, docs/08 §6). Toda persona activa. datos_actualizados_en es nulo hasta que HU-028 (cotizaciones) la llene.';

revoke all on function public.estado_mercado() from public, anon;
grant execute on function public.estado_mercado() to authenticated;

-- HU-028 · `estado_mercado()` llena `datos_actualizados_en`.
-- Fuentes: docs/06 §6, docs/09 §2 (antigüedad de la última cotización), specs/027-…/plan.md punto 3
-- (aprobado: HU-028 la llena y HU-032 la usa para el aviso de dato desactualizado).
--
-- datos_actualizados_en = la hora en que se recibió la cotización más reciente (cotizaciones.recibido_en);
-- nula mientras no haya ninguna. Solo cambia esa columna: el resto es igual a la versión de HU-027.

create or replace function public.estado_mercado()
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
  v_frescura  timestamptz;
begin
  -- Toda persona con la cuenta activa (docs/03 §4.3); private.rol_actual() es nulo si no lo está.
  if private.rol_actual() is null then
    raise exception 'NO_AUTORIZADO';
  end if;

  select m.tras_apertura, m.antes_cierre into v_tras, v_antes from private.margenes_de_compra() m;
  select max(c.recibido_en) into v_frescura from public.cotizaciones c;

  -- La sesión de referencia: la que está en curso o, si no hay, la siguiente.
  select c.* into v_dia
    from public.calendario_mercado c
   where c.cierre > v_ahora
   order by c.cierre
   limit 1;

  if v_dia.fecha is null then
    return query select 'cerrado'::text, false, v_ahora, null::timestamptz, null::timestamptz,
                        null::timestamptz, null::timestamptz, false, null::text, v_frescura;
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
           v_frescura;
end;
$$;

comment on function public.estado_mercado() is
  'Estado del mercado calculado desde calendario_mercado y private.ahora(): estado, próxima apertura y cierre, ventana de compras y frescura de los datos (docs/06 §6, docs/08 §6). Toda persona activa. datos_actualizados_en es la hora de recepción de la última cotización (HU-028); nula si no hay ninguna.';

revoke all on function public.estado_mercado() from public, anon;
grant execute on function public.estado_mercado() to authenticated;

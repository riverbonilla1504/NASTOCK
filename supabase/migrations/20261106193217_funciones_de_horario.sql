-- HU-027 · Funciones de horario del mercado y sincronización diaria.
-- Fuentes: docs/06 §8.2 (mercado_abierto, mercado_en_ventana), docs/05 §7 (la ingesta pregunta a SQL
-- si le toca: "mercado abierto o hasta 10 min antes de abrir"), docs/08 §6, docs/10 §10 y §12
-- (atributos de los activos), D-66 (las Edge Functions solo ejecutan funciones de private).
--
-- Toda la lógica toma la hora de private.ahora() (docs/15 §3), nunca de now(): con
-- pruebas.fijar_reloj() se prueban feriados, medias jornadas y ventanas.
-- Ningún rol de la API puede ejecutarlas.

-- ¿Está abierto el mercado? Hay un día de mercado con apertura <= ahora < cierre.
create function private.mercado_abierto()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.calendario_mercado c
     where private.ahora() >= c.apertura
       and private.ahora() < c.cierre
  )
$$;

comment on function private.mercado_abierto() is
  'Verdadero si ahora (private.ahora()) cae entre la apertura y el cierre de un día de mercado. Un feriado no tiene fila: cerrado todo el día (CB-49).';

revoke all on function private.mercado_abierto() from public, anon, authenticated;

-- ¿Está el mercado abierto, o abre dentro de p_margen? Es la condición de la ingesta de precios
-- (`private.mercado_en_ventana(interval '10 minutes')`, docs/05 §7).
create function private.mercado_en_ventana(p_margen interval)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_margen is null or p_margen < interval '0' then
    raise exception 'mercado_en_ventana: el margen debe ser un intervalo no negativo';
  end if;

  return exists (
    select 1
      from public.calendario_mercado c
     where private.ahora() >= c.apertura - p_margen
       and private.ahora() < c.cierre
  );
end;
$$;

comment on function private.mercado_en_ventana(interval) is
  'Verdadero si el mercado está abierto o abre dentro de p_margen (docs/05 §7).';

revoke all on function private.mercado_en_ventana(interval) from public, anon, authenticated;

-- Sincroniza el calendario: recibe los días de mercado del broker entre p_desde y p_hasta
-- ([{fecha, apertura, cierre, sesion}, …], horas en UTC), inserta o actualiza cada uno y borra los
-- de ese rango que el broker ya no lista (un cierre no programado). Los días fuera del rango no se
-- tocan. Es idempotente: repetir la misma llamada no cambia nada.
--
-- Devuelve cuántas filas quedaron nuevas o cambiadas y cuántas se borraron.
--
-- Comprobaciones: la apertura debe caer en la fecha (en Nueva York), lo que atrapa una conversión de
-- horario de verano mal hecha (CB-51); la tabla exige cierre > apertura y una sesión válida.
create function private.sincronizar_calendario(p_desde date, p_hasta date, p_datos jsonb)
returns table (guardados integer, eliminados integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cambiados integer;
  v_borrados  integer;
begin
  if p_desde is null or p_hasta is null or p_desde > p_hasta then
    raise exception 'sincronizar_calendario: el rango de fechas no es válido';
  end if;
  if p_datos is null or jsonb_typeof(p_datos) <> 'array' then
    raise exception 'sincronizar_calendario: se esperaba un arreglo';
  end if;

  if exists (
    select 1
      from jsonb_to_recordset(p_datos) as d(fecha date, apertura timestamptz, cierre timestamptz, sesion text)
     where d.fecha is null or d.apertura is null or d.cierre is null or d.sesion is null
        or d.fecha < p_desde or d.fecha > p_hasta
  ) then
    raise exception 'sincronizar_calendario: un día viene incompleto o fuera del rango';
  end if;
  if (select count(*) <> count(distinct d.fecha)
        from jsonb_to_recordset(p_datos) as d(fecha date)) then
    raise exception 'sincronizar_calendario: hay fechas repetidas';
  end if;
  if exists (
    select 1
      from jsonb_to_recordset(p_datos) as d(fecha date, apertura timestamptz)
     where (d.apertura at time zone 'America/New_York')::date <> d.fecha
  ) then
    raise exception 'sincronizar_calendario: una apertura no cae en su día de mercado de Nueva York';
  end if;

  with recibidos as (
    select d.fecha, d.apertura, d.cierre, d.sesion
      from jsonb_to_recordset(p_datos) as d(fecha date, apertura timestamptz, cierre timestamptz, sesion text)
  ),
  borrados as (
    delete from public.calendario_mercado c
     where c.fecha between p_desde and p_hasta
       and not exists (select 1 from recibidos r where r.fecha = c.fecha)
    returning 1
  ),
  cambiados as (
    insert into public.calendario_mercado as c (fecha, apertura, cierre, sesion)
    select r.fecha, r.apertura, r.cierre, r.sesion from recibidos r
    on conflict (fecha) do update
       set apertura = excluded.apertura,
           cierre   = excluded.cierre,
           sesion   = excluded.sesion
     where (c.apertura, c.cierre, c.sesion) is distinct from (excluded.apertura, excluded.cierre, excluded.sesion)
    returning 1
  )
  select (select count(*) from cambiados)::integer, (select count(*) from borrados)::integer
    into v_cambiados, v_borrados;

  return query select v_cambiados, v_borrados;
end;
$$;

comment on function private.sincronizar_calendario(date, date, jsonb) is
  'Sincroniza el calendario del broker entre p_desde y p_hasta: inserta o actualiza los días recibidos y borra los del rango que ya no vienen. Idempotente (docs/05 §6, RN-41).';

revoke all on function private.sincronizar_calendario(date, date, jsonb) from public, anon, authenticated;

-- Sincroniza los atributos de los activos: recibe [{simbolo, negociable, fraccionable}, …] y los
-- guarda en todas las filas de lista_blanca de ese símbolo, con la hora de sincronización. Un
-- símbolo que deja de ser negociable queda desactivado (docs/10 §10 y §12); uno que vuelve a serlo
-- NO se reactiva solo: la lista blanca la mantiene el Administrador (HU-036).
--
-- Devuelve una fila por cada fila de lista_blanca actualizada, y si esa fila se desactivó ahora. La
-- alerta al Administrador es de HU-085.
create function private.sincronizar_activos(p_datos jsonb)
returns table (bolsillo public.bolsillo, simbolo text, desactivado boolean)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_datos is null or jsonb_typeof(p_datos) <> 'array' then
    raise exception 'sincronizar_activos: se esperaba un arreglo';
  end if;
  if exists (
    select 1
      from jsonb_to_recordset(p_datos) as d(simbolo text, negociable boolean, fraccionable boolean)
     where d.simbolo is null or d.negociable is null or d.fraccionable is null
  ) then
    raise exception 'sincronizar_activos: un activo viene incompleto';
  end if;
  if (select count(*) <> count(distinct d.simbolo)
        from jsonb_to_recordset(p_datos) as d(simbolo text)) then
    raise exception 'sincronizar_activos: hay símbolos repetidos';
  end if;

  return query
    with recibidos as (
      select d.simbolo, d.negociable, d.fraccionable
        from jsonb_to_recordset(p_datos) as d(simbolo text, negociable boolean, fraccionable boolean)
    ),
    antes as (
      select l0.bolsillo, l0.simbolo, l0.activo as estaba_activo, r.negociable, r.fraccionable
        from public.lista_blanca l0
        join recibidos r on r.simbolo = l0.simbolo
    ),
    actualizadas as (
      update public.lista_blanca l
         set negociable      = a.negociable,
             fraccionable    = a.fraccionable,
             activo          = l.activo and a.negociable,
             sincronizado_en = private.ahora(),
             actualizado_en  = private.ahora()
        from antes a
       where l.bolsillo = a.bolsillo
         and l.simbolo = a.simbolo
      returning l.bolsillo, l.simbolo, (a.estaba_activo and not l.activo) as se_desactivo
    )
    select x.bolsillo, x.simbolo, x.se_desactivo
      from actualizadas x
     order by x.simbolo, x.bolsillo;
end;
$$;

comment on function private.sincronizar_activos(jsonb) is
  'Guarda si cada símbolo es negociable y fraccionable según el broker y desactiva el que dejó de ser negociable; nunca reactiva (docs/10 §10, §12).';

revoke all on function private.sincronizar_activos(jsonb) from public, anon, authenticated;

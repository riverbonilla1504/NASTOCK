-- HU-029 · Condición del cierre diario y retención de las barras de minuto.
-- Fuentes: docs/05 §7 (trabajos `cierre_diario`: cada 10 min, "ya cerró el mercado hoy y no se ha
-- corrido"; `limpieza`: diario 08:00 UTC, SQL con la retención de 06 §10), docs/06 §5.2 y §10,
-- docs/10 §12, D-66 (las Edge Functions solo ejecutan funciones de private).
--
-- Toda la lógica toma la hora de private.ahora() (docs/15 §3). Ningún rol de la API puede
-- ejecutar estas funciones.

-- ¿Le toca correr al cierre diario? Dos condiciones:
--   1. El mercado ya cerró hoy: hay un día de mercado con la fecha de hoy en Nueva York y
--      ahora >= su cierre (en una media jornada, el cierre real de las 13:00; en un feriado o un
--      fin de semana no hay fila y nunca toca, CA-4).
--   2. No se ha corrido: algún símbolo del universo aún no tiene su barra de hoy. Cuando el
--      cierre diario guarda la de todos, deja de tocar (CA-2); si el proveedor falló, vuelve a
--      tocar en 10 minutos hasta que acabe el día.
create function private.cierre_diario_pendiente()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with hoy as (
    select (private.ahora() at time zone 'America/New_York')::date as fecha
  )
  select exists (
           select 1
             from public.calendario_mercado c, hoy
            where c.fecha = hoy.fecha
              and private.ahora() >= c.cierre
         )
     and exists (
           select 1
             from private.simbolos_del_universo() u, hoy
            where not exists (
                    select 1
                      from public.barras_diarias b
                     where b.simbolo = u.simbolo
                       and b.fecha = hoy.fecha
                  )
         )
$$;

comment on function private.cierre_diario_pendiente() is
  'Verdadero si el mercado ya cerró hoy (calendario, hora de Nueva York) y algún símbolo del universo no tiene su barra diaria de hoy: la condición del trabajo cierre_diario (docs/05 §7).';

revoke all on function private.cierre_diario_pendiente() from public, anon, authenticated;

-- Retención de barras_minuto (docs/06 §10): 5 días, y solo las de los ETF y las de los símbolos
-- con posiciones. Borra las de más de 5 días y las de cualquier símbolo que no sea ETF ni tenga
-- una posición sin cerrar. Devuelve cuántas filas borró.
--   · ETF: los de la lista blanca fuera del NASDAQ-100 (QQQ, QLD, TQQQ), más QQQ siempre.
--   · Posiciones: `public.posiciones` (docs/06 §5.5) la crea una historia posterior (E-07/E-08).
--     Mientras no exista no hay posiciones y solo cuentan los ETF; cuando exista, esta función
--     las incluye sin cambiarla (consulta dinámica: no falla al crearse sin la tabla).
create function private.limpiar_barras_minuto()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_borradas integer;
  v_tabla regclass := to_regclass('public.posiciones');
  v_con_posicion text[] := array[]::text[];
begin
  -- La tabla se nombra con %s sobre un regclass (no con texto fijo): así el linter de la base no
  -- intenta resolver una tabla que todavía no existe.
  if v_tabla is not null then
    execute format(
      'select coalesce(array_agg(distinct p.simbolo), ''{}'') from %s p where p.cerrada_en is null',
      v_tabla)
      into v_con_posicion;
  end if;

  delete from public.barras_minuto m
   where m.momento < private.ahora() - interval '5 days'
      or (m.simbolo <> 'QQQ'
          and m.simbolo <> all (v_con_posicion)
          and not exists (
                select 1 from public.lista_blanca l
                 where l.simbolo = m.simbolo and not l.en_nasdaq100));

  get diagnostics v_borradas = row_count;
  return v_borradas;
end;
$$;

comment on function private.limpiar_barras_minuto() is
  'Retención de barras_minuto: borra las de más de 5 días y las que no son de un ETF ni de un símbolo con posición abierta; devuelve las filas borradas (docs/06 §10).';

revoke all on function private.limpiar_barras_minuto() from public, anon, authenticated;

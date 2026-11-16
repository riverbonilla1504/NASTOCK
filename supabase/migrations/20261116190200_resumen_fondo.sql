-- HU-020 · Resumen agregado para cualquier cuenta activa (docs/06 §6).
create function public.resumen_fondo()
returns table (
  bolsillo public.bolsillo,
  efectivo numeric,
  valor_posiciones numeric,
  patrimonio numeric,
  peso_actual_pct numeric,
  peso_objetivo_pct numeric
)
language sql
stable
security definer
set search_path = ''
as $$
  with objetivos(bolsillo, parametro, orden) as (
    values ('reserva'::public.bolsillo, 'reparto.pct_reserva', 1),
           ('arriesgadas'::public.bolsillo, 'reparto.pct_arriesgadas', 2),
           ('usuarios'::public.bolsillo, 'reparto.pct_usuarios', 3)
  ), saldos as (
    select s.bolsillo, sum(s.efectivo) as efectivo
    from public.subcuentas s
    where s.estado = 'abierta' and s.bolsillo is not null
    group by s.bolsillo
  ), posiciones as (
    select s.bolsillo, sum(coalesce(p.valor_mercado, p.costo_total)) as valor
    from public.posiciones_valoradas p
    join public.subcuentas s on s.id = p.subcuenta_id
    where s.estado = 'abierta' and p.estado <> 'cerrada'
    group by s.bolsillo
  ), totales as (
    select o.*, coalesce(s.efectivo, 0) as efectivo, coalesce(p.valor, 0) as valor
    from objetivos o
    left join saldos s using (bolsillo)
    left join posiciones p using (bolsillo)
  )
  select t.bolsillo, t.efectivo, t.valor, t.efectivo + t.valor,
         coalesce(round(100 * (t.efectivo + t.valor) /
           nullif(sum(t.efectivo + t.valor) over (), 0), 2), 0),
         private.parametro_numerico(t.parametro)
  from totales t
  where (select private.rol_actual()) is not null
  order by t.orden;
$$;

revoke all on function public.resumen_fondo() from public, anon, authenticated, service_role;
grant execute on function public.resumen_fondo() to authenticated;

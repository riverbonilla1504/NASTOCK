-- HU-033 · private.margenes_de_compra() lee los márgenes de `parametros` (RR-07, docs/02 §10) en lugar
-- de los 5 y 15 minutos fijos de HU-027. Misma firma: ventana_compras_abierta y estado_mercado no cambian.
create or replace function private.margenes_de_compra()
returns table (tras_apertura integer, antes_cierre integer)
language sql
stable
security definer
set search_path = ''
as $$
  select (select (p.valor #>> '{}')::numeric::integer from public.parametros p
           where p.clave = 'mercado.minutos_tras_apertura'),
         (select (p.valor #>> '{}')::numeric::integer from public.parametros p
           where p.clave = 'mercado.minutos_antes_cierre')
$$;

comment on function private.margenes_de_compra() is
  'Minutos tras la apertura y antes del cierre en que no se compra (RR-07). Los lee de parametros (mercado.minutos_tras_apertura y mercado.minutos_antes_cierre; defectos 5 y 15).';

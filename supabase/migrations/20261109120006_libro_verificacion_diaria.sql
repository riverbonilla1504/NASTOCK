-- HU-013 · Verificación diaria del libro (L2, FR-042, CA-5).
-- Recalcula efectivo e invertido de cada subcuenta desde sus asientos y devuelve las que difieren del
-- saldo guardado. El trabajo diario la corre y deja un aviso en el registro de Postgres.
-- La alerta al Administrador (tipo `descuadre`, docs/06 §5.6) llega con HU-085, que crea la tabla
-- `alertas`: ahí se conecta esta función; hoy detecta y avisa por registro.

create function private.verificar_libro()
returns table (
  subcuenta_id uuid, tipo public.tipo_subcuenta,
  efectivo_guardado numeric, efectivo_calculado numeric,
  invertido_guardado numeric, invertido_calculado numeric
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_n int;
begin
  return query
  with calc as (
    select a.subcuenta_id,
           coalesce(sum(a.monto) filter (where a.concepto = 'efectivo'), 0)  as efectivo,
           coalesce(sum(a.monto) filter (where a.concepto = 'invertido'), 0) as invertido
    from public.asientos a group by a.subcuenta_id
  )
  select s.id, s.tipo, s.efectivo, coalesce(c.efectivo, 0), s.invertido, coalesce(c.invertido, 0)
  from public.subcuentas s
  left join calc c on c.subcuenta_id = s.id
  where s.efectivo <> coalesce(c.efectivo, 0) or s.invertido <> coalesce(c.invertido, 0);
  get diagnostics v_n = row_count;
  if v_n > 0 then
    raise warning 'libro: % subcuenta(s) con saldo distinto de la suma de sus asientos', v_n;
  end if;
end;
$$;

comment on function private.verificar_libro() is
  'Recalcula los saldos desde asientos y devuelve las subcuentas que difieren del saldo guardado (docs/06 §4.1, L2). La llama el trabajo verificar_libro.';
revoke all on function private.verificar_libro() from public, anon, authenticated, service_role;

-- Diario a las 07:00 UTC (docs/05 §7). Sustituye al trabajo del mismo nombre si ya existe.
select cron.schedule('verificar_libro', '0 7 * * *', $$select * from private.verificar_libro()$$);

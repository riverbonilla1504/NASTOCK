-- HU-013 · registrar_movimiento sin tabla temporal.
-- plpgsql_check (supabase db lint --level warning) analiza la función de forma estática y marcaba error
-- 42P01 en `delete from pg_temp.asientos_nuevos` (EC-025). Misma lógica y misma firma: los asientos se
-- leen con jsonb_to_recordset del propio parámetro.

create or replace function private.registrar_movimiento(
  p_tipo         public.tipo_movimiento,
  p_asientos     jsonb,
  p_referencia   jsonb,
  p_descripcion  text,
  p_parametros   jsonb default null,
  p_creado_por   uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_fondo uuid;
  v_id uuid;
  v_n int;
  v_suma numeric;
  v_mal int;
  v_distintas int;
  v_libres int;
begin
  if p_descripcion is null or length(btrim(p_descripcion)) = 0 then
    raise exception 'El movimiento necesita una descripción' using errcode = '22023';
  end if;
  if p_asientos is null or jsonb_typeof(p_asientos) <> 'array' then
    raise exception 'Los asientos deben ser un arreglo' using errcode = '22023';
  end if;

  -- Valida el JSON una sola vez: cada asiento lleva subcuenta_id, concepto y monto. No usa tabla
  -- temporal: plpgsql_check (supabase db lint) no ve las que se crean en tiempo de ejecución.
  begin
    if exists (
      select 1 from jsonb_to_recordset(p_asientos)
        as x (subcuenta_id uuid, concepto public.concepto_asiento, monto numeric)
      where x.subcuenta_id is null or x.concepto is null or x.monto is null
    ) then
      raise exception 'incompleto';
    end if;
  exception when others then
    raise exception 'Asientos mal formados: cada uno lleva subcuenta_id, concepto (efectivo o invertido) y monto' using errcode = '22023';
  end;

  select count(*), coalesce(sum(monto), 0), count(*) filter (where monto is null or monto = 0 or monto <> round(monto, 2)),
         count(distinct subcuenta_id)
    into v_n, v_suma, v_mal, v_distintas
  from jsonb_to_recordset(p_asientos)
    as x (subcuenta_id uuid, concepto public.concepto_asiento, monto numeric);
  if v_n < 2 or v_mal > 0 then
    raise exception 'LIBRO_DESCUADRADO' using errcode = '23514',
      detail = 'Un movimiento necesita al menos dos asientos, con montos distintos de cero y a dos decimales.';
  end if;
  if v_suma <> 0 then
    raise exception 'LIBRO_DESCUADRADO' using errcode = '23514',
      detail = format('Los asientos suman %s; deben sumar 0 (RN-04).', v_suma);
  end if;

  select f.id into v_fondo from public.fondos f;
  if v_fondo is null then
    raise exception 'NO_EXISTE' using detail = 'No hay fondo.';
  end if;

  -- Bloquea las subcuentas en orden fijo (sin interbloqueos) y exige que existan, sean del fondo y estén abiertas.
  select count(*) into v_libres from (
    select s.id from public.subcuentas s
    where s.id in (select y.subcuenta_id from jsonb_to_recordset(p_asientos) as y (subcuenta_id uuid))
      and s.fondo_id = v_fondo and s.estado = 'abierta'
    order by s.id for update
  ) l;
  if v_libres <> v_distintas then
    raise exception 'NO_EXISTE' using detail = 'Alguna subcuenta no existe, no es del fondo o está cerrada.';
  end if;

  insert into public.movimientos (fondo_id, tipo, referencia_tabla, referencia_id, descripcion, parametros, creado_por)
  values (v_fondo, p_tipo, p_referencia->>'tabla', (p_referencia->>'id')::uuid, btrim(p_descripcion), p_parametros, p_creado_por)
  returning id into v_id;

  insert into public.asientos (movimiento_id, subcuenta_id, concepto, monto)
  select v_id, x.subcuenta_id, x.concepto, x.monto
    from jsonb_to_recordset(p_asientos) as x (subcuenta_id uuid, concepto public.concepto_asiento, monto numeric);

  update public.subcuentas s
     set efectivo  = s.efectivo  + n.efectivo,
         invertido = s.invertido + n.invertido,
         version   = s.version + 1
    from (
      select subcuenta_id,
             coalesce(sum(monto) filter (where concepto = 'efectivo'), 0)  as efectivo,
             coalesce(sum(monto) filter (where concepto = 'invertido'), 0) as invertido
      from jsonb_to_recordset(p_asientos) as x (subcuenta_id uuid, concepto public.concepto_asiento, monto numeric)
      group by subcuenta_id
    ) n
   where s.id = n.subcuenta_id;

  return v_id;
end;
$$;

comment on function private.registrar_movimiento(public.tipo_movimiento, jsonb, jsonb, text, jsonb, uuid) is
  'Única escritura del libro (docs/06 §4.1, L1 y L2): valida suma cero, inserta movimiento y asientos y actualiza efectivo e invertido en la misma transacción. Un saldo negativo lo rechaza el CHECK de subcuentas (RN-05).';

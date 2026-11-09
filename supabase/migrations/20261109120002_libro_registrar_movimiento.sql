-- HU-013 · private.registrar_movimiento(), verificación diferida de suma cero (L1) e inmutabilidad (L3).
-- Fuentes: docs/06 §4.1 (L1 a L5), §8.2, docs/02 RN-04 y RN-05, docs/11 §4.3.

-- L1 (segunda línea): al confirmar la transacción, los asientos de cada movimiento suman exactamente 0
-- y son al menos dos. Rechaza también un insert directo que se salte registrar_movimiento().
create function private.verificar_suma_cero()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_n int;
  v_suma numeric;
begin
  if tg_table_name = 'movimientos' then
    v_id := new.id;
  else
    v_id := new.movimiento_id;
  end if;
  select count(*), coalesce(sum(a.monto), 0) into v_n, v_suma
  from public.asientos a where a.movimiento_id = v_id;
  if v_n < 2 or v_suma <> 0 then
    raise exception 'LIBRO_DESCUADRADO' using
      errcode = '23514',
      detail = format('El movimiento %s tiene %s asientos que suman %s; deben ser al menos dos y sumar 0.', v_id, v_n, v_suma);
  end if;
  return null;
end;
$$;
revoke all on function private.verificar_suma_cero() from public, anon, authenticated, service_role;

create constraint trigger movimientos_suma_cero
after insert on public.movimientos
deferrable initially deferred
for each row execute function private.verificar_suma_cero();

create constraint trigger asientos_suma_cero
after insert on public.asientos
deferrable initially deferred
for each row execute function private.verificar_suma_cero();

-- L3: ningún UPDATE, DELETE ni TRUNCATE, ni siquiera del dueño o de service_role. Por sentencia, como
-- en la bitácora (HU-107). Las correcciones son movimientos nuevos de tipo 'ajuste'.
create function private.rechazar_cambio_libro()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'libro: % es inmutable (% no permitido); corrige con un movimiento de ajuste', tg_table_name, tg_op;
end;
$$;
revoke all on function private.rechazar_cambio_libro() from public, anon, authenticated, service_role;

create trigger asientos_inmutable
before update or delete or truncate on public.asientos
for each statement execute function private.rechazar_cambio_libro();

create trigger movimientos_inmutable
before update or delete or truncate on public.movimientos
for each statement execute function private.rechazar_cambio_libro();

-- Única escritura del libro. p_asientos: [{subcuenta_id, concepto, monto}, …].
-- p_referencia (opcional): {"tabla": "ordenes", "id": "<uuid>"}.
-- p_creado_por: quien lo origina; NULL = el sistema (las Edge Functions no tienen auth.uid()).
-- Actualiza efectivo, invertido y version de las subcuentas en la misma transacción (L2); si el
-- resultado deja un efectivo o invertido negativo, o un retenido sobre el efectivo, los CHECK de
-- subcuentas lo rechazan (RN-05, SQLSTATE 23514).
create function private.registrar_movimiento(
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

  if to_regclass('pg_temp.asientos_nuevos') is null then
    create temp table asientos_nuevos (
      subcuenta_id uuid not null, concepto public.concepto_asiento not null, monto numeric not null
    ) on commit drop;
  else
    delete from pg_temp.asientos_nuevos;
  end if;

  begin
    insert into pg_temp.asientos_nuevos (subcuenta_id, concepto, monto)
    select (e->>'subcuenta_id')::uuid, (e->>'concepto')::public.concepto_asiento, (e->>'monto')::numeric
    from jsonb_array_elements(p_asientos) e;
  exception when others then
    raise exception 'Asientos mal formados: cada uno lleva subcuenta_id, concepto (efectivo o invertido) y monto' using errcode = '22023';
  end;

  select count(*), coalesce(sum(monto), 0), count(*) filter (where monto = 0 or monto <> round(monto, 2)),
         count(distinct subcuenta_id)
    into v_n, v_suma, v_mal, v_distintas
  from pg_temp.asientos_nuevos;
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
    where s.id in (select subcuenta_id from pg_temp.asientos_nuevos)
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
  select v_id, subcuenta_id, concepto, monto from pg_temp.asientos_nuevos;

  update public.subcuentas s
     set efectivo  = s.efectivo  + n.efectivo,
         invertido = s.invertido + n.invertido,
         version   = s.version + 1
    from (
      select subcuenta_id,
             coalesce(sum(monto) filter (where concepto = 'efectivo'), 0)  as efectivo,
             coalesce(sum(monto) filter (where concepto = 'invertido'), 0) as invertido
      from pg_temp.asientos_nuevos group by subcuenta_id
    ) n
   where s.id = n.subcuenta_id;

  return v_id;
end;
$$;

comment on function private.registrar_movimiento(public.tipo_movimiento, jsonb, jsonb, text, jsonb, uuid) is
  'Única escritura del libro (docs/06 §4.1, L1 y L2): valida suma cero, inserta movimiento y asientos y actualiza efectivo e invertido en la misma transacción. Un saldo negativo lo rechaza el CHECK de subcuentas (RN-05).';
revoke all on function private.registrar_movimiento(public.tipo_movimiento, jsonb, jsonb, text, jsonb, uuid)
  from public, anon, authenticated, service_role;

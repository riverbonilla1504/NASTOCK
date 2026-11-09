-- HU-015 · Confirmación del aporte (reparto 50/25/25) y conciliación del efectivo.
-- Fuentes: docs/02 RN-07 a RN-09 y §3.1, docs/08 §4 y §7.6, docs/10 §4.1 y §8, docs/06 §8.2
-- (registrar_conciliacion), docs/11 §4.1 (capital.aporte_confirmado), docs/12 CB-11 y CB-12, D-03.
--
-- Solo el sistema confirma: estas funciones viven en `private` y las llama la Edge Function
-- `conciliacion` por conexión directa. Ninguna persona puede confirmar un aporte (RN-07).

-- Confirma un aporte registrado: lo reparte entre reserva, arriesgadas y usuarios_comun con los
-- porcentajes vigentes (RN-08), truncando a centavos arriesgadas y usuarios y dejando el resto en la
-- reserva (RN-09, CB-12). Los porcentajes quedan en `movimientos.parametros`.
create function private.confirmar_aporte(p_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_aporte    public.movimientos_capital;
  v_pct_res   numeric;
  v_pct_arr   numeric;
  v_pct_usu   numeric;
  v_arr       numeric(14,2);
  v_usu       numeric(14,2);
  v_res       numeric(14,2);
  v_externa   uuid;
  v_reserva   uuid;
  v_arriesg   uuid;
  v_usuarios  uuid;
  v_asientos  jsonb;
  v_mov       uuid;
  v_ahora     timestamptz := private.ahora();
begin
  select m.* into v_aporte
    from public.movimientos_capital m
   where m.id = p_id and m.tipo = 'aporte'
     for update;
  if not found then
    raise exception 'NO_EXISTE';
  end if;
  if v_aporte.estado <> 'registrado' then
    raise exception 'ESTADO_INVALIDO';
  end if;

  select (p.valor #>> '{}')::numeric into v_pct_res from public.parametros p where p.clave = 'reparto.pct_reserva';
  select (p.valor #>> '{}')::numeric into v_pct_arr from public.parametros p where p.clave = 'reparto.pct_arriesgadas';
  select (p.valor #>> '{}')::numeric into v_pct_usu from public.parametros p where p.clave = 'reparto.pct_usuarios';
  if v_pct_res is null or v_pct_arr is null or v_pct_usu is null or v_pct_res + v_pct_arr + v_pct_usu <> 100 then
    raise exception 'Los porcentajes de reparto no suman 100' using errcode = '22023';
  end if;

  select s.id into v_externa  from public.subcuentas s where s.tipo = 'externa';
  select s.id into v_reserva  from public.subcuentas s where s.tipo = 'reserva';
  select s.id into v_arriesg  from public.subcuentas s where s.tipo = 'arriesgadas';
  select s.id into v_usuarios from public.subcuentas s where s.tipo = 'usuarios_comun';
  if v_externa is null or v_reserva is null or v_arriesg is null or v_usuarios is null then
    raise exception 'NO_EXISTE' using detail = 'Faltan subcuentas fijas del fondo.';
  end if;

  -- RN-09: arriesgadas y usuarios se truncan a centavos; la reserva recibe el resto.
  v_arr := trunc(v_aporte.monto * v_pct_arr / 100, 2);
  v_usu := trunc(v_aporte.monto * v_pct_usu / 100, 2);
  v_res := v_aporte.monto - v_arr - v_usu;

  -- Un asiento no puede ser de monto cero: las partes en cero (por ejemplo, con un 0 % o con un aporte
  -- de pocos centavos) no generan asiento.
  v_asientos := jsonb_build_array(
    jsonb_build_object('subcuenta_id', v_externa, 'concepto', 'efectivo', 'monto', -v_aporte.monto)
  )
  || case when v_res > 0 then jsonb_build_array(
       jsonb_build_object('subcuenta_id', v_reserva, 'concepto', 'efectivo', 'monto', v_res)) else '[]'::jsonb end
  || case when v_arr > 0 then jsonb_build_array(
       jsonb_build_object('subcuenta_id', v_arriesg, 'concepto', 'efectivo', 'monto', v_arr)) else '[]'::jsonb end
  || case when v_usu > 0 then jsonb_build_array(
       jsonb_build_object('subcuenta_id', v_usuarios, 'concepto', 'efectivo', 'monto', v_usu)) else '[]'::jsonb end;

  v_mov := private.registrar_movimiento(
    'aporte',
    v_asientos,
    jsonb_build_object('tabla', 'movimientos_capital', 'id', v_aporte.id),
    'Aporte confirmado y repartido',
    jsonb_build_object('reparto', jsonb_build_object(
      'pct_reserva', v_pct_res, 'pct_arriesgadas', v_pct_arr, 'pct_usuarios', v_pct_usu)),
    null
  );

  update public.movimientos_capital
     set estado = 'confirmado', confirmado_en = v_ahora, movimiento_id = v_mov
   where id = v_aporte.id;

  perform private.auditar(
    null,
    'capital.aporte_confirmado',
    'movimientos_capital',
    v_aporte.id::text,
    p_detalle => jsonb_build_object('movimiento_id', v_mov, 'monto', v_aporte.monto),
    p_antes => jsonb_build_object('estado', 'registrado'),
    p_despues => jsonb_build_object('estado', 'confirmado'),
    p_origen => 'sistema'
  );

  -- El evento `capital` (admin) lo publica el trigger de la tabla. Aquí avisa al canal `fondo`:
  -- cambió un agregado por bolsillo. Solo identificadores, nunca montos (D-32).
  perform private.publicar_evento(
    'fondo',
    'resumen_cambio',
    private.carga_evento('movimientos', v_mov::text, null, null)
  );

  return v_mov;
end;
$$;

comment on function private.confirmar_aporte(uuid) is
  'Confirma un aporte registrado y lo reparte con los porcentajes vigentes (RN-07 a RN-09). Solo el sistema, desde la conciliación. Errores: NO_EXISTE, ESTADO_INVALIDO.';

-- Aportes registrados que llevan más de `p_antiguedad` sin confirmarse (CB-11). La alerta al
-- Administrador la entrega HU-085; mientras tanto registrar_conciliacion los cuenta.
create function private.aportes_sin_confirmar(p_antiguedad interval default interval '1 hour')
returns setof public.movimientos_capital
language sql
stable
security definer
set search_path = ''
as $$
  select m.*
    from public.movimientos_capital m
   where m.tipo = 'aporte' and m.estado = 'registrado'
     and m.registrado_en <= private.ahora() - p_antiguedad
   order by m.registrado_en
$$;

comment on function private.aportes_sin_confirmar(interval) is
  'Aportes registrados sin confirmar desde hace más de p_antiguedad (por defecto una hora; CB-11). Base de la alerta de HU-085.';

-- Conciliación del efectivo (docs/10 §8): compara el `cash` del broker con el efectivo del libro,
-- registra el resultado y confirma los aportes registrados que el efectivo ya cubre.
--   ok                el broker cubre el libro (un excedente es «no asignado» y no se usa; docs/10 §4.1)
--   diferencia_menor  al broker le faltan hasta `conciliacion.tolerancia_usd`
--   descuadre_critico al broker le falta más que la tolerancia
-- Solo con resultado ok se confirman aportes. Cada aporte, del más antiguo al más nuevo, necesita que
-- el efectivo sobrante cubra su monto; al confirmarse, el libro crece y el siguiente se compara con eso.
-- La pausa automática ante un descuadre crítico y las posiciones llegan con HU-080.
create function private.registrar_conciliacion(
  p_efectivo_broker     numeric,
  p_detalle_posiciones  jsonb default null
)
returns public.conciliaciones
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tolerancia  numeric;
  v_libro       numeric(14,2);
  v_dif         numeric(14,2);
  v_resultado   public.resultado_conciliacion;
  v_confirmados int := 0;
  v_pendientes  int;
  v_aporte      record;
  v_fila        public.conciliaciones;
  v_nota        text;
begin
  if p_efectivo_broker is null or p_efectivo_broker < 0 then
    raise exception 'El efectivo del broker debe ser un número no negativo' using errcode = '22023';
  end if;

  -- Una conciliación a la vez: bloquea el fondo.
  perform 1 from public.fondos f for update;

  select coalesce((p.valor #>> '{}')::numeric, 1) into v_tolerancia
    from public.parametros p where p.clave = 'conciliacion.tolerancia_usd';
  v_tolerancia := coalesce(v_tolerancia, 1);

  v_libro := private.efectivo_del_libro();
  v_dif := round(p_efectivo_broker, 2) - v_libro;
  v_resultado := case
    when v_dif >= 0 then 'ok'
    when -v_dif <= v_tolerancia then 'diferencia_menor'
    else 'descuadre_critico'
  end;

  if v_resultado = 'ok' then
    for v_aporte in
      select m.id, m.monto from public.movimientos_capital m
       where m.tipo = 'aporte' and m.estado = 'registrado'
       order by m.registrado_en, m.id
         for update
    loop
      exit when round(p_efectivo_broker, 2) - private.efectivo_del_libro() < v_aporte.monto;
      perform private.confirmar_aporte(v_aporte.id);
      v_confirmados := v_confirmados + 1;
    end loop;
  end if;

  select count(*) into v_pendientes from private.aportes_sin_confirmar();
  if v_pendientes > 0 then
    v_nota := format('%s aporte(s) registrado(s) sin confirmar desde hace más de una hora', v_pendientes);
    raise warning 'conciliacion: %', v_nota;
  end if;

  insert into public.conciliaciones (
    ejecutada_en, resultado, efectivo_broker, efectivo_libro, diferencia_efectivo,
    detalle_posiciones, accion_tomada, nota
  )
  values (
    private.ahora(), v_resultado, round(p_efectivo_broker, 2), v_libro, v_dif,
    p_detalle_posiciones,
    case when v_confirmados > 0 then 'aporte_confirmado' else 'ninguna' end,
    v_nota
  )
  returning * into v_fila;

  return v_fila;
end;
$$;

comment on function private.registrar_conciliacion(numeric, jsonb) is
  'Compara el efectivo del broker con el del libro, registra el resultado y confirma los aportes que el efectivo cubre (docs/10 §8, RN-07). Solo el sistema.';

revoke all on function private.confirmar_aporte(uuid) from public, anon, authenticated, service_role;
revoke all on function private.aportes_sin_confirmar(interval) from public, anon, authenticated, service_role;
revoke all on function private.registrar_conciliacion(numeric, jsonb) from public, anon, authenticated, service_role;

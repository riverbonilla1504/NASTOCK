-- HU-014 · RPC registrar_aporte y anular_aporte.
-- Fuentes: docs/06 §8.1 (firmas) y §9 (códigos de error), docs/03 §4.4 (orden de las validaciones:
-- sesión y rol, estado, escritura, auditoría, todo en una transacción), docs/02 RN-07 y RN-10,
-- docs/11 §4.1 (acciones capital.aporte_registrado y capital.aporte_anulado), PM-40.
--
-- Registrar no toca el libro (RN-07): solo anota el aporte. El libro se mueve al confirmarlo (HU-015).
-- El monto no positivo lo rechaza el CHECK de la tabla (CA-4, SQLSTATE 23514); aquí se valida antes
-- para devolver un mensaje claro.

create function public.registrar_aporte(
  p_monto      numeric,
  p_referencia text default null,
  p_nota       text default null
)
returns public.movimientos_capital
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_rol   public.rol_app := private.rol_actual();
  v_mov   public.movimientos_capital;
begin
  -- (1) Sesión activa y rol (CA-5).
  if v_rol is null then
    raise exception 'SESION_INVALIDA';
  end if;
  if v_rol <> 'administrador' then
    raise exception 'NO_AUTORIZADO';
  end if;

  if p_monto is null or p_monto <= 0 or p_monto <> round(p_monto, 2) then
    raise exception 'El monto del aporte debe ser positivo y tener a lo sumo dos decimales'
      using errcode = '23514';
  end if;

  -- (5) Escritura y auditoría. El libro no cambia (RN-07).
  insert into public.movimientos_capital (tipo, monto, referencia_externa, nota, registrado_por)
  values ('aporte', p_monto, nullif(btrim(p_referencia), ''), nullif(btrim(p_nota), ''), v_actor)
  returning * into v_mov;

  perform private.auditar(
    v_actor,
    'capital.aporte_registrado',
    'movimientos_capital',
    v_mov.id::text,
    p_detalle => jsonb_build_object('monto', v_mov.monto, 'referencia', v_mov.referencia_externa),
    p_despues => jsonb_build_object('estado', v_mov.estado)
  );

  return v_mov;
end;
$$;

comment on function public.registrar_aporte(numeric, text, text) is
  'Registra un aporte de capital en estado registrado, sin mover el libro (RN-07). Solo el Administrador activo (PM-40). Errores: SESION_INVALIDA, NO_AUTORIZADO; monto no positivo: 23514. Audita capital.aporte_registrado.';

create function public.anular_aporte(p_id uuid, p_motivo text)
returns public.movimientos_capital
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_rol   public.rol_app := private.rol_actual();
  v_mov   public.movimientos_capital;
begin
  -- (1) Sesión activa y rol (CA-5).
  if v_rol is null then
    raise exception 'SESION_INVALIDA';
  end if;
  if v_rol <> 'administrador' then
    raise exception 'NO_AUTORIZADO';
  end if;

  if p_motivo is null or length(btrim(p_motivo)) = 0 then
    raise exception 'La anulación necesita un motivo' using errcode = '22023';
  end if;

  select m.* into v_mov
    from public.movimientos_capital m
   where m.id = p_id and m.tipo = 'aporte'
     for update;
  if not found then
    raise exception 'NO_EXISTE';
  end if;

  -- (3) Estado: solo se anula un aporte registrado. Uno confirmado se corrige con un retiro (RN-10, CA-3);
  -- uno ya anulado tampoco se anula de nuevo.
  if v_mov.estado <> 'registrado' then
    raise exception 'ESTADO_INVALIDO';
  end if;

  -- (5) Escritura y auditoría.
  update public.movimientos_capital
     set estado = 'anulado',
         anulado_por = v_actor,
         anulado_en = private.ahora(),
         motivo_anulacion = btrim(p_motivo)
   where id = v_mov.id
  returning * into v_mov;

  perform private.auditar(
    v_actor,
    'capital.aporte_anulado',
    'movimientos_capital',
    v_mov.id::text,
    p_detalle => jsonb_build_object('motivo', v_mov.motivo_anulacion),
    p_antes => jsonb_build_object('estado', 'registrado'),
    p_despues => jsonb_build_object('estado', 'anulado')
  );

  return v_mov;
end;
$$;

comment on function public.anular_aporte(uuid, text) is
  'Anula un aporte registrado y no confirmado, con motivo (RN-10). Solo el Administrador activo (PM-40). Errores: SESION_INVALIDA, NO_AUTORIZADO, NO_EXISTE, ESTADO_INVALIDO (docs/06 §9). Audita capital.aporte_anulado.';

revoke all on function public.registrar_aporte(numeric, text, text) from public, anon;
revoke all on function public.anular_aporte(uuid, text) from public, anon;
grant execute on function public.registrar_aporte(numeric, text, text) to authenticated;
grant execute on function public.anular_aporte(uuid, text) to authenticated;

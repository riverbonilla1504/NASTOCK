-- HU-018 · Asignar y reducir cupos.
-- Fuentes: docs/02 RN-16, RN-17, RN-19 y §5; docs/03 PM-42 y §4.4 (orden de las validaciones); docs/06 §8.1
-- y §9 (códigos); docs/09 §3 y §4 (eventos `cupo` en el canal del Usuario y `resumen_cambio` en `fondo`:
-- avisan, no informan montos); docs/11 §4.1 (cupo.asignado, cupo.reducido); docs/12 CB-14 y CB-16.
-- Reducir un cupo no vende posiciones: solo mueve el disponible (efectivo − retenido) a usuarios_comun.

-- Eventos de Realtime: cada cambio de saldo de una subcuenta (sube su version en registrar_movimiento)
-- avisa con tabla, id, versión y estado, nunca montos (D-32). Un cupo avisa además a su dueño.
create function private.publicar_evento_subcuenta()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_carga jsonb := private.carga_evento('subcuentas', new.id::text, new.version, new.estado::text);
begin
  if new.tipo = 'cupo' then
    perform private.publicar_evento('usuario:' || new.usuario_id::text, 'cupo', v_carga);
  end if;
  perform private.publicar_evento('fondo', 'resumen_cambio', v_carga);
  return null;
end;
$$;

comment on function private.publicar_evento_subcuenta() is
  'Trigger de subcuentas: tras cada cambio de saldo publica resumen_cambio en fondo y, si es un cupo, cupo en el canal de su dueño; sin montos (docs/09 §3 y §4).';
revoke all on function private.publicar_evento_subcuenta() from public, anon, authenticated, service_role;

create trigger subcuentas_publicar_evento
after update of version on public.subcuentas
for each row execute function private.publicar_evento_subcuenta();

-- Núcleo común. p_sentido: 1 asigna (usuarios_comun → cupo), -1 reduce (cupo → usuarios_comun).
create function private.mover_cupo(p_usuario uuid, p_monto numeric, p_sentido int)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor  uuid := (select auth.uid());
  v_rol    public.rol_app := private.rol_actual();
  v_cupo   public.subcuentas;
  v_comun  public.subcuentas;
  v_max    jsonb;
  v_mov    uuid;
  v_asig   boolean := p_sentido = 1;
begin
  -- Sesión activa y rol (docs/03 §4.4; PM-42: solo el Administrador).
  if v_rol is null then
    raise exception 'SESION_INVALIDA';
  end if;
  if v_rol <> 'administrador' then
    raise exception 'NO_AUTORIZADO';
  end if;
  if p_usuario is null or p_monto is null or p_monto <= 0 or p_monto <> round(p_monto, 2) then
    raise exception 'El monto debe ser mayor que cero y tener a lo sumo dos decimales' using errcode = '22023';
  end if;

  -- Bloquea primero la bolsa común y luego el cupo, siempre en ese orden.
  select * into v_comun from public.subcuentas s where s.tipo = 'usuarios_comun' for update;
  select * into v_cupo from public.subcuentas s
   where s.tipo = 'cupo' and s.usuario_id = p_usuario and s.estado = 'abierta' for update;
  if not found then
    raise exception 'NO_EXISTE' using detail = 'La persona no tiene un cupo abierto.';
  end if;

  if v_asig then
    -- RN-16 / CB-14: no más que el disponible de usuarios_comun.
    if p_monto > v_comun.efectivo - v_comun.retenido then
      raise exception 'FONDOS_INSUFICIENTES';
    end if;
    -- RN-19: el cupo (efectivo + invertido) no puede quedar sobre cupos.maximo_usd; JSON null = sin límite.
    select p.valor into v_max from public.parametros p where p.clave = 'cupos.maximo_usd';
    if v_max is not null and jsonb_typeof(v_max) = 'number'
       and v_cupo.efectivo + v_cupo.invertido + p_monto > (v_max #>> '{}')::numeric then
      raise exception 'CUPO_SUPERA_MAXIMO';
    end if;
  else
    -- RN-17 / CB-16: solo hasta el disponible del cupo.
    if p_monto > v_cupo.efectivo - v_cupo.retenido then
      raise exception 'FONDOS_INSUFICIENTES';
    end if;
  end if;

  v_mov := private.registrar_movimiento(
    case when v_asig then 'asignacion_cupo' else 'reduccion_cupo' end::public.tipo_movimiento,
    jsonb_build_array(
      jsonb_build_object('subcuenta_id', v_comun.id, 'concepto', 'efectivo', 'monto', -p_sentido * p_monto),
      jsonb_build_object('subcuenta_id', v_cupo.id,  'concepto', 'efectivo', 'monto',  p_sentido * p_monto)),
    jsonb_build_object('tabla', 'subcuentas', 'id', v_cupo.id),
    case when v_asig then 'Asignación de cupo' else 'Reducción de cupo' end,
    null, v_actor);

  perform private.auditar(v_actor, case when v_asig then 'cupo.asignado' else 'cupo.reducido' end,
                          'subcuentas', v_cupo.id::text,
                          jsonb_build_object('usuario_id', p_usuario, 'monto', p_monto, 'movimiento_id', v_mov));
  return v_mov;
end;
$$;
revoke all on function private.mover_cupo(uuid, numeric, int) from public, anon, authenticated, service_role;

create function public.asignar_cupo(p_usuario_id uuid, p_monto numeric)
returns uuid
language sql
security definer
set search_path = ''
as $$ select private.mover_cupo(p_usuario_id, p_monto, 1) $$;

create function public.reducir_cupo(p_usuario_id uuid, p_monto numeric)
returns uuid
language sql
security definer
set search_path = ''
as $$ select private.mover_cupo(p_usuario_id, p_monto, -1) $$;

comment on function public.asignar_cupo(uuid, numeric) is
  'Administrador: mueve dinero de usuarios_comun al cupo de una persona (RN-16, PM-42). Devuelve el id del movimiento. FONDOS_INSUFICIENTES, CUPO_SUPERA_MAXIMO, NO_EXISTE.';
comment on function public.reducir_cupo(uuid, numeric) is
  'Administrador: mueve dinero del cupo a usuarios_comun hasta su disponible (RN-17, PM-42). Devuelve el id del movimiento. FONDOS_INSUFICIENTES, NO_EXISTE.';

revoke all on function public.asignar_cupo(uuid, numeric) from public, anon;
revoke all on function public.reducir_cupo(uuid, numeric) from public, anon;
grant execute on function public.asignar_cupo(uuid, numeric) to authenticated;
grant execute on function public.reducir_cupo(uuid, numeric) to authenticated;

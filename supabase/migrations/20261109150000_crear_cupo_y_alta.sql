-- HU-017 · Cupo al aceptar la invitación.
-- Fuentes: docs/02 RN-18 y RN-20, docs/04 §6, docs/06 §4 y §8.2, docs/12 CB-15, docs/11 §4.1 (cupo.asignado).
-- El índice único de un cupo abierto por persona ya lo creó HU-013 (subcuentas_cupo_abierto_unico).

-- Crea la subcuenta de cupo de un Usuario y, si usuarios_comun alcanza, le asigna el monto con un
-- movimiento asignacion_cupo. Si no alcanza, el cupo queda en 0 y NO falla (CB-15, docs/04 §6): el
-- ingreso no puede depender de la bolsa común. Idempotente: si la persona ya tiene un cupo abierto,
-- lo devuelve sin tocar nada. Devuelve el id de la subcuenta de cupo.
--
-- La alerta `cupo_inicial_no_asignado` al Administrador (docs/06 §5.6) es de HU-085, que crea la tabla
-- `alertas` y aún no está en main: hoy el caso deja un aviso (WARNING) en el registro de Postgres.
create function private.crear_cupo(p_usuario uuid, p_monto numeric default 0)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_fondo uuid;
  v_comun public.subcuentas;
  v_cupo uuid;
  v_monto numeric(14,2) := coalesce(p_monto, 0);
begin
  if v_monto < 0 or v_monto <> round(v_monto, 2) then
    raise exception 'El monto del cupo no puede ser negativo ni tener más de dos decimales' using errcode = '22023';
  end if;
  if not exists (select 1 from public.perfiles p where p.id = p_usuario) then
    raise exception 'NO_EXISTE' using detail = 'La persona no tiene perfil.';
  end if;

  select s.id into v_cupo from public.subcuentas s
   where s.tipo = 'cupo' and s.usuario_id = p_usuario and s.estado = 'abierta';
  if found then
    return v_cupo;
  end if;

  select f.id into v_fondo from public.fondos f;
  insert into public.subcuentas (fondo_id, tipo, bolsillo, usuario_id)
  values (v_fondo, 'cupo', 'usuarios', p_usuario)
  returning id into v_cupo;

  if v_monto > 0 then
    -- Bloquea la bolsa común para decidir y asignar sin que otro movimiento la vacíe en medio.
    select * into v_comun from public.subcuentas s
     where s.fondo_id = v_fondo and s.tipo = 'usuarios_comun' for update;

    if v_comun.efectivo - v_comun.retenido >= v_monto then
      perform private.registrar_movimiento(
        'asignacion_cupo',
        jsonb_build_array(
          jsonb_build_object('subcuenta_id', v_comun.id, 'concepto', 'efectivo', 'monto', -v_monto),
          jsonb_build_object('subcuenta_id', v_cupo, 'concepto', 'efectivo', 'monto', v_monto)),
        jsonb_build_object('tabla', 'subcuentas', 'id', v_cupo),
        'Cupo inicial al aceptar la invitación',
        jsonb_build_object('origen', 'invitacion'));
      perform private.auditar(null, 'cupo.asignado', 'subcuentas', v_cupo::text,
                              jsonb_build_object('usuario_id', p_usuario, 'monto', v_monto, 'origen', 'invitacion'),
                              p_origen => 'auth');
    else
      raise warning 'cupo_inicial_no_asignado: usuarios_comun no cubre % para la persona %', v_monto, p_usuario;
    end if;
  end if;

  return v_cupo;
end;
$$;

comment on function private.crear_cupo(uuid, numeric) is
  'Crea la subcuenta de cupo de un Usuario y le asigna el monto inicial si usuarios_comun lo cubre; si no, queda en 0 y no falla (RN-18, CB-15). Idempotente. La alerta cupo_inicial_no_asignado llega con HU-085.';
revoke all on function private.crear_cupo(uuid, numeric) from public, anon, authenticated, service_role;

-- El trigger de alta de HU-002 ahora crea el cupo cuando el rol es Usuario (docs/04 §6).
create or replace function private.al_crear_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_inv public.invitaciones;
begin
  select * into v_inv from public.invitaciones i
  where lower(i.email) = lower(new.email) and i.estado = 'pendiente'
  for update;

  if not found then
    -- El hook ya lo habría rechazado; esto protege las altas que no pasan por él.
    raise exception 'No hay una invitación pendiente para %', new.email
      using errcode = 'P0001';
  end if;

  insert into public.perfiles (id, email, nombre, rol, estado, invitacion_id)
  values (new.id, lower(new.email),
          coalesce(nullif(new.raw_user_meta_data->>'full_name', ''), new.email),
          v_inv.rol, 'activo', v_inv.id);

  update public.invitaciones
     set estado = 'aceptada', aceptada_en = private.ahora(), usuario_id = new.id
   where id = v_inv.id;

  if v_inv.rol = 'usuario' then
    perform private.crear_cupo(new.id, v_inv.cupo_inicial);  -- RN-18
  end if;

  perform private.auditar(new.id, 'cuenta.activada', 'perfiles', new.id::text,
                          jsonb_build_object('rol', v_inv.rol), p_origen => 'auth');
  return new;
end;
$$;

comment on function private.al_crear_usuario() is
  'Trigger de auth.users: crea el perfil activo con el rol de la invitación, la acepta, crea el cupo si es Usuario (RN-18) y audita cuenta.activada (docs/04 §6).';

-- CA-4: los Usuarios que ya existían antes del libro reciben su cupo en 0 (no tenían cupo inicial que honrar).
select private.crear_cupo(p.id, 0)
from public.perfiles p
where p.rol = 'usuario' and p.estado <> 'baja';

-- HU-003 · RPC invitar_usuario y revocar_invitacion.
-- Fuentes: docs/06 §8.1 (firmas) y §9 (códigos de error), docs/03 §4.4 (orden de las validaciones:
-- sesión y rol, estado, escritura, auditoría, todo en una transacción), docs/04 §4.1 (el sistema no
-- envía correos), docs/08 §5 (una invitación está vigente mientras sea pendiente y no haya pasado su
-- fecha; invitar de nuevo pasa a vencida la pendiente ya pasada), docs/11 §4.1 (acciones de la
-- bitácora), PM-50, CB-02, CB-03, CB-04.
--
-- La bitácora es inmutable y se guarda para siempre (docs/06 §10): el correo, que es un dato personal
-- (docs/11 §1), no va en su detalle, como en cuenta.invitada del primer administrador (HU-004). Quien
-- quiera saber a quién se invitó cruza `entidad_id` con `invitaciones.id`.
--
-- La tabla `invitaciones` no admite escrituras de la API (HU-002): solo estas funciones y el trigger de
-- alta la escriben. El evento `invitacion` lo publica el trigger de la migración anterior.

create function public.invitar_usuario(
  p_email        text,
  p_rol          public.rol_app,
  p_cupo_inicial numeric
)
returns public.invitaciones
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor  uuid := (select auth.uid());
  v_rol    public.rol_app := private.rol_actual();
  v_ahora  timestamptz := private.ahora();
  v_email  text := lower(btrim(coalesce(p_email, '')));
  v_previa public.invitaciones;
  v_nueva  public.invitaciones;
begin
  -- (1) Sesión activa y rol. rol_actual() es nulo si la cuenta no está activa (CA-7).
  if v_rol is null then
    raise exception 'SESION_INVALIDA';
  end if;
  if v_rol <> 'administrador' then
    raise exception 'NO_AUTORIZADO';
  end if;

  -- Forma de los datos. Sin código propio en docs/06 §9: la app lo evita en el formulario y, si
  -- llegara, muestra el mensaje genérico.
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'El correo no tiene la forma de un correo' using errcode = '22023';
  end if;
  if p_rol is null then
    raise exception 'La invitación necesita un rol' using errcode = '22023';
  end if;
  if p_cupo_inicial is null or p_cupo_inicial < 0 then
    raise exception 'El cupo inicial no puede ser nulo ni negativo' using errcode = '22023';
  end if;

  -- (3) Estado: el correo ya tiene cuenta (CB-03) o ya tiene una invitación vigente (CB-04).
  if exists (select 1 from public.perfiles p where p.email = v_email) then
    raise exception 'CORREO_YA_REGISTRADO';
  end if;

  select i.* into v_previa
    from public.invitaciones i
   where lower(i.email) = v_email and i.estado = 'pendiente'
     for update;
  if found then
    if v_previa.expira_en > v_ahora then
      raise exception 'INVITACION_DUPLICADA';
    end if;
    -- CB-02: la pendiente ya pasó su fecha; se da por vencida y se crea la nueva.
    update public.invitaciones set estado = 'vencida' where id = v_previa.id;
  end if;

  -- (5) Escritura. Si otra llamada creó la pendiente entre la lectura y este insert, el índice único
  -- de una pendiente por correo la rechaza.
  begin
    insert into public.invitaciones (email, rol, cupo_inicial, expira_en, creada_por, creado_en)
    values (v_email, p_rol, p_cupo_inicial, v_ahora + interval '7 days', v_actor, v_ahora)
    returning * into v_nueva;
  exception when unique_violation then
    raise exception 'INVITACION_DUPLICADA';
  end;

  perform private.auditar(
    v_actor,
    'cuenta.invitada',
    'invitaciones',
    v_nueva.id::text,
    p_detalle => jsonb_build_object(
                   'rol', v_nueva.rol,
                   'cupo_inicial', v_nueva.cupo_inicial,
                   'expira_en', v_nueva.expira_en
                 )
                 || case when v_previa.id is null then '{}'::jsonb
                         else jsonb_build_object('reemplaza', v_previa.id) end
  );

  return v_nueva;
end;
$$;

comment on function public.invitar_usuario(text, public.rol_app, numeric) is
  'Invita a una persona con su correo, su rol y su cupo inicial; vence en 7 días. Solo el Administrador activo (PM-50). Errores: SESION_INVALIDA, NO_AUTORIZADO, CORREO_YA_REGISTRADO, INVITACION_DUPLICADA (docs/06 §9). Audita cuenta.invitada.';

create function public.revocar_invitacion(p_id uuid)
returns public.invitaciones
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_rol   public.rol_app := private.rol_actual();
  v_inv   public.invitaciones;
begin
  -- (1) Sesión activa y rol (CA-5, CA-7).
  if v_rol is null then
    raise exception 'SESION_INVALIDA';
  end if;
  if v_rol <> 'administrador' then
    raise exception 'NO_AUTORIZADO';
  end if;

  select i.* into v_inv from public.invitaciones i where i.id = p_id for update;
  if not found then
    raise exception 'NO_EXISTE';
  end if;

  -- (3) Estado: solo se revoca una pendiente (docs/08 §5). Una pendiente con la fecha pasada sigue
  -- siendo pendiente y se puede revocar.
  if v_inv.estado <> 'pendiente' then
    raise exception 'ESTADO_INVALIDO';
  end if;

  -- (5) Escritura y auditoría.
  update public.invitaciones
     set estado = 'revocada', revocada_en = private.ahora()
   where id = v_inv.id
  returning * into v_inv;

  perform private.auditar(
    v_actor,
    'cuenta.invitacion_revocada',
    'invitaciones',
    v_inv.id::text,
    p_detalle => jsonb_build_object('rol', v_inv.rol),
    p_antes => jsonb_build_object('estado', 'pendiente'),
    p_despues => jsonb_build_object('estado', 'revocada')
  );

  return v_inv;
end;
$$;

comment on function public.revocar_invitacion(uuid) is
  'Revoca una invitación pendiente: ese correo ya no puede ingresar. Solo el Administrador activo (PM-50). Errores: SESION_INVALIDA, NO_AUTORIZADO, NO_EXISTE, ESTADO_INVALIDO (docs/06 §9). Audita cuenta.invitacion_revocada.';

revoke all on function public.invitar_usuario(text, public.rol_app, numeric) from public, anon;
revoke all on function public.revocar_invitacion(uuid) from public, anon;
grant execute on function public.invitar_usuario(text, public.rol_app, numeric) to authenticated;
grant execute on function public.revocar_invitacion(uuid) to authenticated;

-- HU-011 · PM-51; RN-50, RN-51, RN-54, RN-55; docs/04 §8 y docs/09 §7.
-- HU-098 consume esta RPC. RN-56 corresponde a HU-065 (fuera del MVP corto).
create function public.cambiar_rol(p_usuario_id uuid, p_rol public.rol_app)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_rol public.rol_app := private.rol_actual();
  v_destino public.perfiles;
  v_comun public.subcuentas;
  v_cupo public.subcuentas;
begin
  if v_rol is null then raise exception 'SESION_INVALIDA'; end if;
  if v_rol <> 'administrador' then raise exception 'NO_AUTORIZADO'; end if;
  if p_usuario_id is null or p_rol is null then
    raise exception 'La cuenta y el rol son obligatorios' using errcode = '22023';
  end if;

  -- Serializa cambios de perfiles, también frente a otras RPC de administración.
  -- Releer el actor después de esperar: sus permisos pudieron haber cambiado.
  lock table public.perfiles in share row exclusive mode;
  v_rol := private.rol_actual();
  if v_rol is null then raise exception 'SESION_INVALIDA'; end if;
  if v_rol <> 'administrador' then raise exception 'NO_AUTORIZADO'; end if;
  select * into v_destino from public.perfiles where id = p_usuario_id for update;
  if not found then raise exception 'NO_EXISTE'; end if;
  if v_destino.rol = 'administrador' and v_destino.estado = 'activo'
     and p_rol <> 'administrador'
     and (select count(*) from public.perfiles where rol = 'administrador' and estado = 'activo') = 1 then
    raise exception 'ULTIMO_ADMIN';
  end if;
  if p_usuario_id = v_actor then raise exception 'AUTO_ACCION'; end if;
  if v_destino.rol = p_rol then return; end if;

  if v_destino.rol = 'usuario' then
    -- El orden coincide con mover_cupo: común primero, cupo después.
    select * into v_comun from public.subcuentas where tipo = 'usuarios_comun' for update;
    select * into v_cupo from public.subcuentas
      where tipo = 'cupo' and usuario_id = p_usuario_id and estado = 'abierta' for update;
    if found then
      if v_cupo.retenido <> 0 or v_cupo.invertido <> 0
         or exists (select 1 from public.posiciones where subcuenta_id = v_cupo.id and estado <> 'cerrada')
         or exists (select 1 from public.ordenes where subcuenta_id = v_cupo.id
           and estado in ('creada', 'enviada', 'aceptada', 'parcialmente_llenada', 'desconocida')) then
        raise exception 'CUPO_CON_POSICIONES';
      end if;
      if v_cupo.efectivo > 0 then
        perform private.registrar_movimiento('cierre_cupo', jsonb_build_array(
          jsonb_build_object('subcuenta_id', v_cupo.id, 'concepto', 'efectivo', 'monto', -v_cupo.efectivo),
          jsonb_build_object('subcuenta_id', v_comun.id, 'concepto', 'efectivo', 'monto', v_cupo.efectivo)),
          jsonb_build_object('tabla', 'perfiles', 'id', p_usuario_id),
          'Cierre de cupo por cambio de rol', null, v_actor);
      end if;
      update public.subcuentas set estado = 'cerrada', version = version + 1 where id = v_cupo.id;
    end if;
  end if;

  update public.perfiles set rol = p_rol, actualizado_en = now(), version = version + 1
    where id = p_usuario_id;
  if p_rol = 'usuario' then perform private.crear_cupo(p_usuario_id, 0); end if;
  perform private.auditar(v_actor, 'cuenta.rol_cambiado', 'perfiles', p_usuario_id::text,
    jsonb_build_object('rol_anterior', v_destino.rol, 'rol', p_rol));
  perform private.publicar_evento('usuario:' || p_usuario_id::text, 'perfil_actualizado',
    private.carga_evento('perfiles', p_usuario_id::text, v_destino.version + 1, v_destino.estado::text));
end;
$$;
revoke all on function public.cambiar_rol(uuid, public.rol_app) from public, anon, authenticated, service_role;
grant execute on function public.cambiar_rol(uuid, public.rol_app) to authenticated;
comment on function public.cambiar_rol(uuid, public.rol_app) is
  'HU-011: cambio de rol por Administrador, cupo y auditoría atómicos, evento privado. RN-50/51/54/55. Parámetros p_usuario_id y p_rol; pantalla en HU-098.';

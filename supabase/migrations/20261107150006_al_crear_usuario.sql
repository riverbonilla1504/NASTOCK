-- HU-002 · Trigger al crear el usuario, y sincronización del correo.
-- Fuentes: docs/04 §6, docs/08 §5, docs/11 §4.1, docs/12 CB-05, RN-58.
-- El cupo inicial lo agrega HU-017 a esta función.

create function private.al_crear_usuario()
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

  perform private.auditar(new.id, 'cuenta.activada', 'perfiles', new.id::text,
                          jsonb_build_object('rol', v_inv.rol), p_origen => 'auth');
  return new;
end;
$$;

comment on function private.al_crear_usuario() is
  'Trigger de auth.users: crea el perfil activo con el rol de la invitación, la acepta y audita cuenta.activada (docs/04 §6).';

create trigger al_crear_usuario
after insert on auth.users
for each row execute function private.al_crear_usuario();

-- CB-05: Workspace cambió el correo. La identidad es el id de Google, no el correo (RN-58).
create function private.al_cambiar_correo()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_anterior text;
begin
  select p.email into v_anterior from public.perfiles p where p.id = new.id for update;
  if not found or v_anterior = lower(new.email) then
    return new;
  end if;

  update public.perfiles set email = lower(new.email), actualizado_en = private.ahora()
   where id = new.id;

  perform private.auditar(new.id, 'cuenta.correo_cambiado', 'perfiles', new.id::text,
                          p_antes => jsonb_build_object('email', v_anterior),
                          p_despues => jsonb_build_object('email', lower(new.email)),
                          p_origen => 'auth');
  return new;
end;
$$;

comment on function private.al_cambiar_correo() is
  'Trigger de auth.users: sincroniza perfiles.email cuando cambia y lo audita (docs/12 CB-05, RN-58).';

create trigger al_cambiar_correo
after update of email on auth.users
for each row when (new.email is not null and new.email is distinct from old.email)
execute function private.al_cambiar_correo();

revoke all on function private.al_crear_usuario() from public, anon, authenticated;
revoke all on function private.al_cambiar_correo() from public, anon, authenticated;

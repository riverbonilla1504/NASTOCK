-- HU-003 · Evento `invitacion` en el canal `admin`.
-- Fuentes: docs/09 §3 (el canal `admin` lleva `invitacion`) y §4 (los eventos avisan, no informan: solo
-- tabla, id, versión y estado, nunca montos ni correos; D-32), docs/06 §8.2 (publicar_evento y
-- carga_evento), docs/17 M-13 (un trigger por entidad).
--
-- Un trigger sobre la tabla, y no cada RPC, para que el evento salga en todos los cambios de estado:
-- invitar (insert), revocar y vencer (update) y también la aceptación que hace el trigger de alta de
-- HU-002. Así la lista de invitaciones de HU-098 se actualiza en todos los casos.
-- `invitaciones` no tiene columna `version` (docs/06 §5.1): la carga la manda nula, como prevé
-- private.carga_evento para una tabla sin versión.

create function private.publicar_evento_invitacion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.publicar_evento(
    'admin',
    'invitacion',
    private.carga_evento('invitaciones', new.id::text, null, new.estado::text)
  );
  return null;
end;
$$;

comment on function private.publicar_evento_invitacion() is
  'Trigger de invitaciones: publica el evento invitacion en el canal admin con tabla, id y estado, sin correos ni montos (docs/09 §3 y §4).';

create trigger invitaciones_publicar_evento
after insert or update of estado on public.invitaciones
for each row execute function private.publicar_evento_invitacion();

revoke all on function private.publicar_evento_invitacion() from public, anon, authenticated;

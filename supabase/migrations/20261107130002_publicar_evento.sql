-- HU-083 · private.publicar_evento y private.carga_evento.
-- Fuente: docs/09 §3 (canales) y §4 (los eventos avisan, no informan; D-32).
--
-- publicar_evento es la única puerta por la que las demás historias publican: envuelve
-- realtime.send siempre con canal privado. carga_evento arma la carga de un evento de entidad:
-- solo tabla, id, versión y estado, nunca montos. Los precios del canal mercado son la excepción
-- y viajan con su propia carga (docs/09 §4).

create function private.carga_evento(p_tabla text, p_id uuid, p_version integer, p_estado text)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select jsonb_build_object('tabla', p_tabla, 'id', p_id, 'version', p_version, 'estado', p_estado)
$$;

comment on function private.carga_evento(text, uuid, integer, text) is
  'Carga de un evento de entidad: solo tabla, id, versión y estado, sin montos (docs/09 §4, D-32).';

create function private.publicar_evento(p_topico text, p_evento text, p_carga jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_topico is null
     or not (p_topico in ('mercado', 'fondo', 'supervision', 'admin')
             or p_topico ~ '^usuario:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') then
    raise exception 'Canal de tiempo real desconocido: %', p_topico using errcode = '22023';
  end if;
  if p_evento is null or p_evento = '' then
    raise exception 'El evento necesita un nombre' using errcode = '22023';
  end if;
  -- El último argumento (true) hace el mensaje privado: lo filtra la política canales_permitidos.
  perform realtime.send(p_carga, p_evento, p_topico, true);
end;
$$;

comment on function private.publicar_evento(text, text, jsonb) is
  'Publica un evento en un canal privado de docs/09 §3. Solo la base de datos publica; envuelve realtime.send.';

revoke all on function private.carga_evento(text, uuid, integer, text) from public, anon, authenticated;
revoke all on function private.publicar_evento(text, text, jsonb) from public, anon, authenticated;

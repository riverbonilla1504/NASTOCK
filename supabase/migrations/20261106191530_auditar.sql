-- HU-107 · private.hash_auditoria() y private.auditar(): la única puerta de escritura de la bitácora.
-- Fuentes: docs/06 §8.2 (auditar), docs/11 §4.1 (qué se registra) y §4.3 (cadena de hash y bloqueo),
-- docs/04 §6 (la llamada del alta), CA-1, CA-2 y CA-4.
--
-- Las llaman otras funciones security definer, triggers y las Edge Functions por conexión directa
-- (D-66). Ningún rol de la API puede ejecutarlas.

-- El hash de un registro: sha256(hash_anterior ‖ momento ‖ actor ‖ actor_rol ‖ acción ‖ entidad ‖ id ‖ antes ‖
-- después ‖ detalle ‖ origen): todos los campos que guarda el registro, para que alterar cualquiera rompa la cadena.
-- Vive en una función aparte para que private.auditar() y la verificación de la cadena (HU-108) usen
-- exactamente la misma fórmula. Para que se pueda reproducir desde cualquier sesión:
--   · los campos se unen con el carácter de control U+001F (separador de unidad), así no se puede
--     mover un carácter de un campo al vecino sin cambiar el hash;
--   · el momento se escribe en UTC con un formato fijo, sin depender de la zona horaria de la sesión;
--   · antes, después y detalle se escriben con el texto canónico de jsonb (claves ordenadas);
--   · un campo nulo se escribe vacío.
create function private.hash_auditoria(
  p_hash_anterior  text,
  p_momento        timestamptz,
  p_actor          uuid,
  p_actor_rol      public.rol_app,
  p_accion         text,
  p_entidad        text,
  p_entidad_id     text,
  p_antes          jsonb,
  p_despues        jsonb,
  p_detalle        jsonb,
  p_origen         text
)
returns text
language sql
stable
set search_path = ''
as $$
  select encode(
    sha256(convert_to(
      concat_ws(chr(31),
        coalesce(p_hash_anterior, ''),
        coalesce(to_char(p_momento at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'), ''),
        coalesce(p_actor::text, ''),
        coalesce(p_actor_rol::text, ''),
        coalesce(p_accion, ''),
        coalesce(p_entidad, ''),
        coalesce(p_entidad_id, ''),
        coalesce(p_antes::text, ''),
        coalesce(p_despues::text, ''),
        coalesce(p_detalle::text, ''),
        coalesce(p_origen, '')
      ),
      'UTF8')),
    'hex')
$$;

comment on function private.hash_auditoria(text, timestamptz, uuid, public.rol_app, text, text, text, jsonb, jsonb, jsonb, text) is
  'sha256 en hexadecimal de hash_anterior, momento (UTC), actor, actor_rol, acción, entidad, id, antes, después, detalle y origen, unidos con U+001F (docs/11 §4.3). Lo usan auditar() y la verificación de la cadena.';

-- Agrega un registro a la bitácora encadenándolo con el anterior. Devuelve su id.
--   p_actor      quién actúa; NULL = el sistema. Su rol se lee de perfiles (no se puede declarar).
--   p_accion     una del catálogo de docs/11 §4.1.
--   p_entidad_id texto: sirve para uuid (con ::text), símbolos, claves de parámetros…
--   p_antes, p_despues  valor anterior y nuevo (CA-1).
--   p_origen     app, sistema, cron o auth. Si no se pasa: sistema sin actor y app con actor.
-- Toma un bloqueo para que dos inserciones simultáneas no usen el mismo hash_anterior (docs/11 §4.3).
-- Solo guarda lo que recibe: no lee el token ni las cabeceras de la sesión. Quien la llama no pasa
-- llaves, tokens ni respuestas de Google (docs/11 §4.1, CA-4).
-- Si la transacción de quien la llama se revierte, el registro también (docs/11 §4.2, EC-012).
create function private.auditar(
  p_actor       uuid,
  p_accion      text,
  p_entidad     text,
  p_entidad_id  text,
  p_detalle     jsonb default null,
  p_antes       jsonb default null,
  p_despues     jsonb default null,
  p_origen      text default null
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_anterior  text;
  v_momento   timestamptz;
  v_rol       public.rol_app;
  v_origen    text;
  v_id        bigint;
begin
  if p_accion is null or btrim(p_accion) = '' then
    raise exception 'auditar: la acción es obligatoria';
  end if;
  if p_entidad is null or btrim(p_entidad) = '' then
    raise exception 'auditar: la entidad es obligatoria';
  end if;

  -- share row exclusive choca consigo mismo: las escrituras de la bitácora hacen fila, una detrás de
  -- otra, y quien llega después lee el último hash ya confirmado. No bloquea las lecturas.
  lock table public.auditoria in share row exclusive mode;

  select a.hash into v_anterior from public.auditoria a order by a.id desc limit 1;
  v_anterior := coalesce(v_anterior, repeat('0', 64));

  v_momento := private.ahora();

  select p.rol into v_rol from public.perfiles p where p.id = p_actor;

  v_origen := coalesce(p_origen, case when p_actor is null then 'sistema' else 'app' end);

  insert into public.auditoria (
    momento, actor_id, actor_rol, accion, entidad, entidad_id,
    antes, despues, detalle, origen, hash_anterior, hash
  )
  values (
    v_momento, p_actor, v_rol, p_accion, p_entidad, p_entidad_id,
    p_antes, p_despues, p_detalle, v_origen, v_anterior,
    private.hash_auditoria(v_anterior, v_momento, p_actor, v_rol, p_accion, p_entidad, p_entidad_id,
                           p_antes, p_despues, p_detalle, v_origen)
  )
  returning id into v_id;

  return v_id;
end;
$$;

comment on function private.auditar(uuid, text, text, text, jsonb, jsonb, jsonb, text) is
  'Única puerta de escritura de la bitácora: agrega un registro encadenando el hash, con un bloqueo de tabla (docs/06 §8.2, docs/11 §4.3). Devuelve el id.';

revoke all on function private.hash_auditoria(text, timestamptz, uuid, public.rol_app, text, text, text, jsonb, jsonb, jsonb, text)
  from public, anon, authenticated, service_role;
revoke all on function private.auditar(uuid, text, text, text, jsonb, jsonb, jsonb, text)
  from public, anon, authenticated, service_role;

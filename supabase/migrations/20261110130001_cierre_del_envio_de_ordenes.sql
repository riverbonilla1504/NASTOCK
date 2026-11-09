-- HU-073 · Lo que el ejecutor hace con la cola y con el resultado de cada envío.
-- Fuentes: docs/08 §2 (estados y reglas), docs/05 §8 (la cola reaparece tras 60 s y tras 5 lecturas se
-- archiva), docs/10 §10 (errores del broker), docs/12 CB-33, CB-36 y CB-68, docs/06 §8.
--
-- Todas son funciones de `private`: las ejecuta el ejecutor por conexión directa (D-66); la API no las ve.
-- La alerta al Administrador por un descuadre o una cola agotada es de HU-085 (aún sin tabla `alertas`):
-- hoy deja la auditoría y un aviso (WARNING) en el registro de Postgres, como la salud de HU-035.

-- Lee hasta p_cantidad mensajes de la cola. Un mensaje leído queda invisible 60 s: si el ejecutor no lo
-- confirma, reaparece. Al quinto intento se archiva y la orden queda en error_envio (CB-68).
create function private.leer_ordenes_por_enviar(p_cantidad int default 10)
returns table (mensaje_id bigint, orden_id uuid, lecturas int)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_mensaje record;
  v_orden   uuid;
begin
  if p_cantidad is null or p_cantidad < 1 or p_cantidad > 100 then
    raise exception 'La cantidad debe estar entre 1 y 100' using errcode = '22023';
  end if;

  for v_mensaje in select * from pgmq.read('ordenes_por_enviar', 60, p_cantidad) loop
    v_orden := (v_mensaje.message ->> 'orden_id')::uuid;
    if v_mensaje.read_ct > 5 then
      perform pgmq.archive('ordenes_por_enviar', v_mensaje.msg_id);
      if exists (
        select 1 from public.ordenes o
        where o.id = v_orden and o.estado in ('creada', 'enviada', 'desconocida')
      ) then
        perform private.cambiar_estado_orden(
          v_orden, 'error_envio', jsonb_build_object('cola', 'agotada', 'lecturas', v_mensaje.read_ct), 'COLA_AGOTADA'
        );
        perform private.auditar(null, 'orden.cola_agotada', 'ordenes', v_orden::text,
                                jsonb_build_object('lecturas', v_mensaje.read_ct), p_origen => 'sistema');
        raise warning 'orden_cola_agotada: la orden % agotó sus lecturas en la cola', v_orden;
      end if;
    else
      mensaje_id := v_mensaje.msg_id;
      orden_id := v_orden;
      lecturas := v_mensaje.read_ct;
      return next;
    end if;
  end loop;
end;
$$;

comment on function private.leer_ordenes_por_enviar(int) is
  'Lee mensajes de ordenes_por_enviar (invisibles 60 s). Al quinto intento archiva el mensaje y deja la orden en error_envio con COLA_AGOTADA (CB-68); esos no se devuelven.';

-- Confirma un mensaje como hecho (lo archiva).
create function private.confirmar_orden_por_enviar(p_mensaje_id bigint)
returns boolean
language sql
security definer
set search_path = ''
as $$ select pgmq.archive('ordenes_por_enviar', p_mensaje_id) $$;

comment on function private.confirmar_orden_por_enviar(bigint) is
  'Archiva un mensaje de ordenes_por_enviar: el trabajo quedó hecho.';

-- ¿Hay algo en la cola? Es la condición del trabajo barrer_ejecutor.
create function private.hay_ordenes_por_enviar()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$ select exists (select 1 from pgmq.q_ordenes_por_enviar) $$;

comment on function private.hay_ordenes_por_enviar() is
  'Verdadero si la cola ordenes_por_enviar tiene mensajes pendientes o en lectura (condición de barrer_ejecutor).';

-- El broker aceptó la orden. El estado de la orden pasa a `aceptada` (docs/08 §2); lo que siga (llenados)
-- lo sincroniza HU-074. p_broker_estado es el estado crudo de Alpaca (docs/08 §2.1) y p_detalle la respuesta
-- ya validada y sin llaves.
create function private.registrar_respuesta_envio(
  p_orden_id        uuid,
  p_broker_order_id text,
  p_estado          public.estado_orden default 'aceptada',
  p_broker_estado   text default null,
  p_detalle         jsonb default null
)
returns public.ordenes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_orden public.ordenes;
begin
  if p_estado <> 'aceptada' then
    -- Los llenados que reporte el broker los aplica la sincronización (HU-074), no el envío.
    raise exception 'El envío solo deja la orden en aceptada' using errcode = '22023';
  end if;
  if p_broker_order_id is null or btrim(p_broker_order_id) = '' then
    raise exception 'Falta el id de la orden en el broker' using errcode = '22023';
  end if;
  select * into v_orden from public.ordenes where id = p_orden_id for update;
  if not found then
    raise exception 'NO_EXISTE';
  end if;
  if v_orden.estado not in ('enviada', 'desconocida') then
    raise exception 'ESTADO_INVALIDO' using detail = v_orden.estado::text;
  end if;

  perform private.cambiar_estado_orden(p_orden_id, 'aceptada', p_detalle);
  update public.ordenes set broker_order_id = p_broker_order_id, broker_estado = p_broker_estado
   where id = p_orden_id returning * into v_orden;
  return v_orden;
end;
$$;

comment on function private.registrar_respuesta_envio(uuid, text, public.estado_orden, text, jsonb) is
  'El broker aceptó la orden: enviada o desconocida pasa a aceptada y guarda el id del broker. Repetirla sobre una ya aceptada falla con ESTADO_INVALIDO.';

-- El envío no terminó bien. p_estado: `rechazada` (el broker la rechazó), `error_envio` (nunca llegó o no
-- existe) o `desconocida` (sin respuesta: se consulta por client_order_id antes de reintentar, CB-33).
-- `rechazada` y `error_envio` son finales y liberan la retención.
create function private.registrar_error_envio(
  p_orden_id uuid,
  p_estado   public.estado_orden,
  p_motivo   text,
  p_detalle  jsonb default null
)
returns public.ordenes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_orden public.ordenes;
begin
  if p_estado not in ('rechazada', 'error_envio', 'desconocida') then
    raise exception 'Estado de error inválido: %', p_estado using errcode = '22023';
  end if;
  if p_motivo is null or btrim(p_motivo) = '' then
    raise exception 'Falta el motivo' using errcode = '22023';
  end if;
  select * into v_orden from public.ordenes where id = p_orden_id for update;
  if not found then
    raise exception 'NO_EXISTE';
  end if;
  if v_orden.estado not in ('creada', 'enviada', 'desconocida') then
    raise exception 'ESTADO_INVALIDO' using detail = v_orden.estado::text;
  end if;

  v_orden := private.cambiar_estado_orden(p_orden_id, p_estado, p_detalle, left(btrim(p_motivo), 200));

  -- CB-36: el broker no debería rechazar por fondos porque retenemos antes; si lo hace, es un descuadre.
  if p_estado = 'rechazada' and p_motivo = 'FONDOS_INSUFICIENTES' then
    perform private.auditar(null, 'orden.rechazada_por_fondos', 'ordenes', p_orden_id::text,
                            jsonb_build_object('motivo', p_motivo), p_origen => 'sistema');
    raise warning 'orden_rechazada_por_fondos: posible descuadre en la orden %', p_orden_id;
  end if;
  return v_orden;
end;
$$;

comment on function private.registrar_error_envio(uuid, public.estado_orden, text, jsonb) is
  'Cierra un envío fallido: rechazada, error_envio (finales, liberan la retención) o desconocida (sin respuesta, CB-33). Rechazo por FONDOS_INSUFICIENTES audita y avisa de un posible descuadre (CB-36).';

revoke all on function private.leer_ordenes_por_enviar(int) from public, anon, authenticated, service_role;
revoke all on function private.confirmar_orden_por_enviar(bigint) from public, anon, authenticated, service_role;
revoke all on function private.hay_ordenes_por_enviar() from public, anon, authenticated, service_role;
revoke all on function private.registrar_respuesta_envio(uuid, text, public.estado_orden, text, jsonb) from public, anon, authenticated, service_role;
revoke all on function private.registrar_error_envio(uuid, public.estado_orden, text, jsonb) from public, anon, authenticated, service_role;

-- Trabajo barrer_ejecutor (docs/05 §7): cada 10 s, solo si la cola tiene mensajes.
select cron.schedule(
  'barrer_ejecutor',
  '10 seconds',
  $$select private.despertar_funcion('ejecutor-ordenes') where private.hay_ordenes_por_enviar()$$
);

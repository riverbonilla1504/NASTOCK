-- HU-073 · Tablas de órdenes, su cola y el cierre de un envío.
-- Fuentes: docs/06 §3 (tipos) y §5.4 (ordenes, ordenes_eventos), §7 (RLS), §8; docs/08 §2 (estados de la
-- orden y reglas); docs/05 §8 (cola `ordenes_por_enviar`); docs/09 §3 (evento `orden`); docs/10 §10.
--
-- MVP corto (D-65): no existen `sugerencias`, `posiciones`, `protecciones` ni `opiniones_ia`, así que
-- `sugerencia_id`, `posicion_id`, `proteccion_id` y `opinion_id` existen sin llave foránea; la migración que
-- cree esas tablas la agrega (las migraciones van solo hacia adelante). Toda orden del MVP es `manual`.
--
-- Quién escribe: nadie por la API. La orden la crea `crear_orden_manual` (HU-075); este archivo trae lo que
-- la lleva al broker y lo que cierra un envío. Lo que revalida antes de enviar
-- (`private.tomar_orden_para_envio`) está en la migración siguiente.

create type public.lado as enum ('compra', 'venta');
create type public.origen_orden as enum ('sugerencia', 'manual', 'proteccion', 'liquidacion');
create type public.clase_orden as enum ('simple', 'bracket');
create type public.tipo_orden as enum ('limite', 'mercado', 'stop');
create type public.estado_orden as enum (
  'creada', 'enviada', 'aceptada', 'parcialmente_llenada', 'llenada',
  'cancelada', 'vencida', 'rechazada', 'error_envio', 'desconocida'
);

create table public.ordenes (
  id                       uuid primary key default gen_random_uuid(),  -- se envía como client_order_id (idempotencia)
  origen                   public.origen_orden not null,
  sugerencia_id            uuid,
  posicion_id              uuid,
  proteccion_id            uuid,
  opinion_id               uuid,
  subcuenta_id             uuid not null references public.subcuentas (id),
  creada_por               uuid references public.perfiles (id),
  simbolo                  text not null check (simbolo <> ''),
  lado                     public.lado not null,
  clase                    public.clase_orden not null,
  tipo                     public.tipo_orden not null,
  tif                      text not null check (tif in ('day', 'gtc')),
  cantidad                 numeric(18,9) check (cantidad > 0),
  monto_nocional           numeric(14,2) check (monto_nocional > 0),
  precio_limite            numeric(14,4) check (precio_limite > 0),
  precio_stop              numeric(14,4) check (precio_stop > 0),
  bracket_stop_precio      numeric(14,4) check (bracket_stop_precio > 0),
  bracket_objetivo_precio  numeric(14,4) check (bracket_objetivo_precio > 0),
  retencion                numeric(14,2) not null default 0 check (retencion >= 0),
  estado                   public.estado_orden not null default 'creada',
  broker_order_id          text unique,
  broker_estado            text,
  cantidad_llenada         numeric(18,9) not null default 0 check (cantidad_llenada >= 0),
  monto_llenado            numeric(14,2) not null default 0,
  precio_promedio_llenado  numeric(14,4),
  comisiones               numeric(14,2) not null default 0,
  motivo_rechazo           text,
  intentos_envio           int not null default 0 check (intentos_envio >= 0),
  parametros               jsonb not null,
  creado_en                timestamptz not null default now(),
  enviada_en               timestamptz,
  llenada_en               timestamptz,
  terminada_en             timestamptz,
  version                  int not null default 1,
  constraint ordenes_cantidad_o_monto check ((cantidad is null) <> (monto_nocional is null)),
  -- Un bracket lleva stop y objetivo (docs/10 §5).
  constraint ordenes_bracket_con_patas check (
    clase <> 'bracket' or (bracket_stop_precio is not null and bracket_objetivo_precio is not null)
  )
);

comment on table public.ordenes is
  'Órdenes hacia el broker (docs/06 §5.4). El id se envía como client_order_id. Solo las escriben funciones de la base; la app no escribe aquí.';
comment on column public.ordenes.parametros is
  'Con qué se creó la orden: precio de referencia, banda y lo que el motor de políticas necesite para revalidar al enviar (docs/10 §5). Sin llaves.';
comment on column public.ordenes.retencion is
  'Lo que la orden sigue reteniendo en su subcuenta. Al terminar la orden se libera (docs/08 §2.2) y queda en 0.';
comment on column public.ordenes.motivo_rechazo is
  'Código del motivo cuando la orden no llegó al broker o este la rechazó (por ejemplo MERCADO_CERRADO, FUERA_DE_BANDA, FONDOS_INSUFICIENTES).';

create index ordenes_por_subcuenta on public.ordenes (subcuenta_id, creado_en desc);
create index ordenes_vivas on public.ordenes (estado)
  where estado in ('creada', 'enviada', 'desconocida', 'aceptada', 'parcialmente_llenada');

create table public.ordenes_eventos (
  id                bigint generated always as identity primary key,
  orden_id          uuid not null references public.ordenes (id),
  estado_anterior   public.estado_orden,
  estado_nuevo      public.estado_orden not null,
  cantidad_llenada  numeric(18,9),
  precio            numeric(14,4),
  detalle           jsonb,
  creado_en         timestamptz not null default now()
);

comment on table public.ordenes_eventos is
  'Historia de cada orden (docs/06 §5.4). `detalle` guarda lo que respondió el broker, ya validado y sin llaves.';

create index ordenes_eventos_por_orden on public.ordenes_eventos (orden_id, id);

-- RLS (docs/06 §7): escrituras solo por funciones. Lectura: supervisión, todas; el Usuario, las de su cupo.
alter table public.ordenes enable row level security;
alter table public.ordenes_eventos enable row level security;
revoke all on table public.ordenes from public, anon, authenticated, service_role;
revoke all on table public.ordenes_eventos from public, anon, authenticated, service_role;
grant select on table public.ordenes to authenticated;
grant select on table public.ordenes_eventos to authenticated;

create policy ordenes_lectura on public.ordenes
for select to authenticated
using (
  (select private.es_supervisor())
  or (
    (select private.rol_actual()) is not null
    and subcuenta_id in (select s.id from public.subcuentas s where s.usuario_id = (select auth.uid()))
  )
);

create policy ordenes_eventos_lectura on public.ordenes_eventos
for select to authenticated
using (
  (select private.es_supervisor())
  or (
    (select private.rol_actual()) is not null
    and orden_id in (
      select o.id from public.ordenes o
      join public.subcuentas s on s.id = o.subcuenta_id
      where s.usuario_id = (select auth.uid())
    )
  )
);

comment on policy ordenes_lectura on public.ordenes is
  'Analista y administrador: todas. Usuario: las de su cupo (docs/03 §4.3).';

-- Evento `orden` (docs/09 §3): al dueño de la subcuenta, si tiene, y a supervisión. Solo tabla, id,
-- versión y estado, nunca montos (docs/09 §4).
create function private.publicar_evento_orden()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid;
  v_carga   jsonb := private.carga_evento('ordenes', new.id::text, new.version, new.estado::text);
begin
  select s.usuario_id into v_usuario from public.subcuentas s where s.id = new.subcuenta_id;
  if v_usuario is not null then
    perform private.publicar_evento('usuario:' || v_usuario::text, 'orden', v_carga);
  end if;
  perform private.publicar_evento('supervision', 'orden', v_carga);
  return null;
end;
$$;

comment on function private.publicar_evento_orden() is
  'Trigger de ordenes: publica orden en el canal del dueño y en supervision con tabla, id, versión y estado, sin montos (docs/09 §3 y §4).';
revoke all on function private.publicar_evento_orden() from public, anon, authenticated, service_role;

create trigger ordenes_publicar_evento
after insert or update of estado on public.ordenes
for each row execute function private.publicar_evento_orden();

-- Cola de envío (docs/05 §8). Reaparece tras 60 s si nadie la confirma; tras 5 lecturas se archiva.
select pgmq.create('ordenes_por_enviar');

-- Toda orden nueva en `creada` entra a la cola. El trabajo `barrer_ejecutor` (cron, cada 10 s) despierta
-- al ejecutor mientras la cola tenga mensajes.
create function private.encolar_orden_nueva()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform pgmq.send('ordenes_por_enviar', jsonb_build_object('orden_id', new.id));
  return null;
end;
$$;

comment on function private.encolar_orden_nueva() is
  'Trigger de ordenes: pone en la cola ordenes_por_enviar toda orden que nace en creada (docs/05 §8).';
revoke all on function private.encolar_orden_nueva() from public, anon, authenticated, service_role;

create trigger ordenes_encolar
after insert on public.ordenes
for each row when (new.estado = 'creada')
execute function private.encolar_orden_nueva();

-- Pasa una orden a otro estado y deja el evento. Núcleo de las funciones que cierran un envío. Si la orden
-- termina (o nunca llegó al broker) libera lo que retenía su subcuenta (docs/08 §2.2).
create function private.cambiar_estado_orden(
  p_orden_id uuid,
  p_estado   public.estado_orden,
  p_detalle  jsonb default null,
  p_motivo   text default null
)
returns public.ordenes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_orden public.ordenes;
  v_antes public.estado_orden;
  v_ahora timestamptz := private.ahora();
  v_final boolean := p_estado in ('llenada', 'cancelada', 'vencida', 'rechazada', 'error_envio');
  v_retenida numeric(14,2);
begin
  select * into v_orden from public.ordenes where id = p_orden_id for update;
  if not found then
    raise exception 'NO_EXISTE';
  end if;
  v_antes := v_orden.estado;
  v_retenida := v_orden.retencion;
  -- Una orden terminada no vuelve a cambiar.
  if v_antes in ('llenada', 'cancelada', 'vencida', 'rechazada', 'error_envio') then
    raise exception 'ESTADO_INVALIDO' using detail = v_antes::text;
  end if;

  update public.ordenes set
    estado         = p_estado,
    motivo_rechazo = coalesce(p_motivo, motivo_rechazo),
    enviada_en     = case when p_estado = 'enviada' then v_ahora else enviada_en end,
    terminada_en   = case when v_final then v_ahora else terminada_en end,
    retencion      = case when v_final then 0 else retencion end,
    version        = version + 1
  where id = p_orden_id returning * into v_orden;

  if v_final and v_retenida > 0 then
    -- La retención no es del libro (L5): se libera sin tocar efectivo ni invertido.
    update public.subcuentas set
      retenido = greatest(retenido - v_retenida, 0),
      version  = version + 1
    where id = v_orden.subcuenta_id;
  end if;

  insert into public.ordenes_eventos (orden_id, estado_anterior, estado_nuevo, detalle)
  values (p_orden_id, v_antes, p_estado, p_detalle);
  return v_orden;
end;
$$;
revoke all on function private.cambiar_estado_orden(uuid, public.estado_orden, jsonb, text) from public, anon, authenticated, service_role;

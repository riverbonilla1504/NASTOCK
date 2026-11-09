-- HU-074 · Tablas de posiciones y protecciones, y la vista de posiciones valoradas.
-- Fuentes: docs/06 §3 (tipos) y §5.4 (posiciones, protecciones), §7 (RLS), docs/08 §3, docs/09 §3 (evento
-- `posicion`), docs/02 §6.2.
--
-- MVP corto (D-63): todas las protecciones son nativas; `tipo_proteccion` se crea con sus dos valores pero solo
-- se usa `nativa`. La tabla `protecciones` la llena HU-077; aquí solo se crea (la historia lo pide).
-- Escrituras: ninguna por la API; las hace `private.aplicar_llenado`.

create type public.estado_posicion as enum ('abierta', 'cerrando', 'cerrada');
create type public.tipo_proteccion as enum ('nativa', 'virtual');
create type public.estado_proteccion as enum ('pendiente', 'activa', 'disparada', 'cancelada', 'reemplazada');

create table public.posiciones (
  id                   uuid primary key default gen_random_uuid(),
  subcuenta_id         uuid not null references public.subcuentas (id),
  simbolo              text not null check (simbolo <> ''),
  cantidad             numeric(18,9) not null check (cantidad >= 0),
  costo_promedio       numeric(14,6) not null check (costo_promedio >= 0),
  costo_total          numeric(14,2) not null check (costo_total >= 0),
  resultado_realizado  numeric(14,2) not null default 0,
  estado               public.estado_posicion not null default 'abierta',
  abierta_en           timestamptz not null default now(),
  cerrada_en           timestamptz,
  version              int not null default 1
);

-- Una posición no cerrada por (subcuenta, símbolo).
create unique index posiciones_unica_abierta on public.posiciones (subcuenta_id, simbolo) where estado <> 'cerrada';
create index posiciones_por_subcuenta on public.posiciones (subcuenta_id);

comment on table public.posiciones is
  'Lo que tiene cada subcuenta en cada símbolo, a costo promedio ponderado (docs/02 §6.2). La escribe private.aplicar_llenado.';
comment on column public.posiciones.costo_total is
  'Costo de lo que queda: la suma de las posiciones abiertas de una subcuenta es su `invertido` en el libro.';

create table public.protecciones (
  id                  uuid primary key default gen_random_uuid(),
  posicion_id         uuid not null references public.posiciones (id),
  tipo                public.tipo_proteccion not null,
  cantidad            numeric(18,9) not null check (cantidad > 0),
  stop_precio         numeric(14,4) not null check (stop_precio > 0),
  objetivo_precio     numeric(14,4) check (objetivo_precio > 0),
  estado              public.estado_proteccion not null default 'pendiente',
  orden_entrada_id    uuid references public.ordenes (id),
  broker_stop_id      text,
  broker_objetivo_id  text,
  disparo             text check (disparo in ('stop', 'objetivo')),
  disparada_en        timestamptz,
  orden_venta_id      uuid references public.ordenes (id),
  actualizado_por     uuid references public.perfiles (id),
  creado_en           timestamptz not null default now(),
  version             int not null default 1
);

create index protecciones_por_posicion on public.protecciones (posicion_id);

comment on table public.protecciones is
  'Stop-loss y take-profit de una posición (docs/06 §5.4). En el MVP solo nativas (D-63); las crea y mueve HU-077.';

-- Las órdenes ya pueden apuntar a su posición y a su protección.
alter table public.ordenes
  add constraint ordenes_posicion_fk foreign key (posicion_id) references public.posiciones (id),
  add constraint ordenes_proteccion_fk foreign key (proteccion_id) references public.protecciones (id);

-- RLS (docs/06 §7): escrituras solo por funciones. Lectura: supervisión, todas; el Usuario, las de su cupo.
alter table public.posiciones enable row level security;
alter table public.protecciones enable row level security;
revoke all on table public.posiciones from public, anon, authenticated, service_role;
revoke all on table public.protecciones from public, anon, authenticated, service_role;
grant select on table public.posiciones to authenticated;
grant select on table public.protecciones to authenticated;

create policy posiciones_lectura on public.posiciones
for select to authenticated
using (
  (select private.es_supervisor())
  or (
    (select private.rol_actual()) is not null
    and subcuenta_id in (select s.id from public.subcuentas s where s.usuario_id = (select auth.uid()))
  )
);

create policy protecciones_lectura on public.protecciones
for select to authenticated
using (
  (select private.es_supervisor())
  or (
    (select private.rol_actual()) is not null
    and posicion_id in (
      select p.id from public.posiciones p
      join public.subcuentas s on s.id = p.subcuenta_id
      where s.usuario_id = (select auth.uid())
    )
  )
);

-- Posiciones con su valor de mercado y su ganancia no realizada (RN-06: se calcula al vuelo, no es contable).
-- security_invoker: la vista respeta la RLS de quien la consulta.
create view public.posiciones_valoradas with (security_invoker = true) as
select
  p.id, p.subcuenta_id, p.simbolo, p.cantidad, p.costo_promedio, p.costo_total, p.resultado_realizado,
  p.estado, p.abierta_en, p.cerrada_en, p.version,
  c.precio                                   as precio_actual,
  round(p.cantidad * c.precio, 2)            as valor_mercado,
  round(p.cantidad * c.precio, 2) - p.costo_total as no_realizado
from public.posiciones p
left join public.cotizaciones c on c.simbolo = p.simbolo;

comment on view public.posiciones_valoradas is
  'Posiciones con precio actual, valor de mercado y ganancia no realizada. Sin cotización, esas tres columnas son nulas.';
grant select on public.posiciones_valoradas to authenticated;

-- Evento `posicion` (docs/09 §3): al dueño del cupo y a supervisión. Solo tabla, id, versión y estado.
create function private.publicar_evento_posicion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid;
  v_carga   jsonb := private.carga_evento('posiciones', new.id::text, new.version, new.estado::text);
begin
  select s.usuario_id into v_usuario from public.subcuentas s where s.id = new.subcuenta_id;
  if v_usuario is not null then
    perform private.publicar_evento('usuario:' || v_usuario::text, 'posicion', v_carga);
  end if;
  perform private.publicar_evento('supervision', 'posicion', v_carga);
  return null;
end;
$$;

comment on function private.publicar_evento_posicion() is
  'Trigger de posiciones: publica posicion en el canal del dueño y en supervision con tabla, id, versión y estado, sin montos (docs/09 §3 y §4).';
revoke all on function private.publicar_evento_posicion() from public, anon, authenticated, service_role;

create trigger posiciones_publicar_evento
after insert or update on public.posiciones
for each row execute function private.publicar_evento_posicion();

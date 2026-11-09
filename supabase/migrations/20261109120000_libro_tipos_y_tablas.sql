-- (El tipo bolsillo ya existe: lo creó la lista blanca.)
-- HU-013 · Libro contable: tipos y tablas fondos, subcuentas, movimientos y asientos.
-- Fuentes: docs/06 §3 (enumeraciones) y §4 (libro e invariantes), docs/03 §4.3 (lecturas), docs/06 §7
-- (RLS, sin escritura por la API). Las tablas solo las escribe private.registrar_movimiento() (L1, L2);
-- el fondo y sus subcuentas fijas nacen en la migración de datos iniciales.

create type public.tipo_subcuenta as enum ('reserva', 'arriesgadas', 'usuarios_comun', 'cupo', 'externa', 'resultados');
create type public.estado_subcuenta as enum ('abierta', 'cerrada');
create type public.concepto_asiento as enum ('efectivo', 'invertido');
create type public.tipo_movimiento as enum (
  'aporte', 'retiro', 'asignacion_cupo', 'reduccion_cupo', 'cierre_cupo',
  'compra', 'venta', 'reparto_ganancia', 'rebalanceo', 'ajuste'
);

create table public.fondos (
  id              uuid primary key default gen_random_uuid(),
  nombre          text not null,
  moneda          char(3) not null default 'USD',
  ia_activa       boolean not null default false,
  trading_activo  boolean not null default false,
  motivo_pausa    text,
  pausado_por     uuid references public.perfiles (id),
  pausado_en      timestamptz,
  creado_en       timestamptz not null default now()
);

-- Un solo fondo (RN-01): índice único sobre una constante.
create unique index fondos_unico on public.fondos ((true));

create table public.subcuentas (
  id          uuid primary key default gen_random_uuid(),
  fondo_id    uuid not null references public.fondos (id),
  tipo        public.tipo_subcuenta not null,
  bolsillo    public.bolsillo,
  usuario_id  uuid references public.perfiles (id),
  efectivo    numeric(14,2) not null default 0,
  invertido   numeric(14,2) not null default 0,
  retenido    numeric(14,2) not null default 0,
  estado      public.estado_subcuenta not null default 'abierta',
  version     int not null default 1,
  creado_en   timestamptz not null default now(),
  constraint subcuentas_cupo_con_usuario check ((tipo = 'cupo') = (usuario_id is not null)),
  -- El bolsillo de cada tipo es fijo; externa y resultados no tienen (docs/06 §4).
  constraint subcuentas_bolsillo_del_tipo check (
    bolsillo is not distinct from case tipo
      when 'reserva' then 'reserva'::public.bolsillo
      when 'arriesgadas' then 'arriesgadas'::public.bolsillo
      when 'usuarios_comun' then 'usuarios'::public.bolsillo
      when 'cupo' then 'usuarios'::public.bolsillo
      else null
    end
  ),
  -- RN-05: ni efectivo ni invertido negativos en bolsillos y cupos; externa y resultados sí pueden.
  constraint subcuentas_no_negativas check (tipo in ('externa', 'resultados') or (efectivo >= 0 and invertido >= 0)),
  constraint subcuentas_retenido check (retenido >= 0 and retenido <= greatest(efectivo, 0))
);

-- Único por fondo para todos los tipos salvo 'cupo'.
create unique index subcuentas_tipo_unico on public.subcuentas (fondo_id, tipo) where tipo <> 'cupo';
-- Una persona tiene a lo sumo un cupo abierto (una reincorporada tiene uno cerrado y uno abierto).
create unique index subcuentas_cupo_abierto_unico on public.subcuentas (usuario_id) where tipo = 'cupo' and estado = 'abierta';
create index subcuentas_usuario on public.subcuentas (usuario_id) where usuario_id is not null;

create table public.movimientos (
  id                uuid primary key default gen_random_uuid(),
  fondo_id          uuid not null references public.fondos (id),
  tipo              public.tipo_movimiento not null,
  referencia_tabla  text,
  referencia_id     uuid,
  descripcion       text not null check (length(btrim(descripcion)) > 0),
  parametros        jsonb,
  creado_por        uuid references public.perfiles (id),
  creado_en         timestamptz not null default now()
);
create index movimientos_creado_en on public.movimientos (creado_en desc);
create index movimientos_referencia on public.movimientos (referencia_tabla, referencia_id) where referencia_id is not null;

create table public.asientos (
  id             bigint generated always as identity primary key,
  movimiento_id  uuid not null references public.movimientos (id),
  subcuenta_id   uuid not null references public.subcuentas (id),
  concepto       public.concepto_asiento not null,
  monto          numeric(14,2) not null check (monto <> 0)
);
create index asientos_movimiento on public.asientos (movimiento_id);
create index asientos_subcuenta on public.asientos (subcuenta_id);

comment on table public.fondos is 'El único fondo de RiTech (RN-01), en USD, con los interruptores de IA y trading (docs/06 §4).';
comment on column public.fondos.ia_activa is 'Interruptor de la IA (RR-14). Nace apagado: el administrador lo enciende tras el primer aporte (RN-11).';
comment on column public.fondos.trading_activo is 'Interruptor del trading (RR-14). Nace apagado.';
comment on table public.subcuentas is 'Dónde está el dinero del fondo: reserva, arriesgadas, usuarios_comun, un cupo por Usuario, externa y resultados (docs/06 §4). Solo private.registrar_movimiento() cambia efectivo e invertido.';
comment on column public.subcuentas.efectivo is 'Suma de sus asientos de concepto efectivo (L2).';
comment on column public.subcuentas.invertido is 'Suma de sus asientos de concepto invertido (L2).';
comment on column public.subcuentas.retenido is 'Apartado operativo del efectivo; no forma parte del libro (L5). Lo mueven las funciones de aprobación y llenado.';
comment on column public.subcuentas.version is 'Crece con cada cambio de saldo; la usan los eventos de Realtime en lugar de montos (docs/09 §4).';
comment on table public.movimientos is 'Cabecera de un cambio del libro. Inmutable (L3). Solo la escribe private.registrar_movimiento().';
comment on table public.asientos is 'Líneas de un movimiento; las de cada movimiento suman exactamente 0 (L1). Inmutable (L3).';

-- Sin escritura para nadie por la API (docs/06 §7, regla 1). Supabase concede por defecto todo a
-- authenticated y service_role en las tablas nuevas de public; se revoca de forma explícita para que un
-- INSERT, UPDATE o DELETE falle con 42501 en vez de rechazarse en silencio por RLS (CA-4).
alter table public.fondos enable row level security;
alter table public.subcuentas enable row level security;
alter table public.movimientos enable row level security;
alter table public.asientos enable row level security;
revoke all on table public.fondos, public.subcuentas, public.movimientos, public.asientos from public, anon, authenticated, service_role;
revoke all on sequence public.asientos_id_seq from public, anon, authenticated, service_role;
grant select on table public.fondos, public.subcuentas, public.movimientos, public.asientos to authenticated;

-- Lecturas (docs/03 §4.3). Cuenta no activa: rol_actual() es NULL y todas niegan.
create policy fondos_lectura on public.fondos
for select to authenticated
using ((select private.es_supervisor()));

create policy subcuentas_lectura on public.subcuentas
for select to authenticated
using (
  (select private.es_supervisor())
  or (
    (select private.rol_actual()) is not null
    and tipo = 'cupo'
    and usuario_id = (select auth.uid())
  )
);

create policy asientos_lectura on public.asientos
for select to authenticated
using (
  (select private.es_supervisor())
  or (
    (select private.rol_actual()) is not null
    and subcuenta_id in (select s.id from public.subcuentas s where s.usuario_id = (select auth.uid()))
  )
);

create policy movimientos_lectura on public.movimientos
for select to authenticated
using (
  (select private.es_supervisor())
  or (
    (select private.rol_actual()) is not null
    and exists (
      select 1
      from public.asientos a
      join public.subcuentas s on s.id = a.subcuenta_id
      where a.movimiento_id = movimientos.id
        and s.usuario_id = (select auth.uid())
    )
  )
);

comment on policy fondos_lectura on public.fondos is 'Solo analista y administrador. La matriz de docs/03 §4.3 no lista fondos para el Usuario, que ve el resumen por función.';
comment on policy subcuentas_lectura on public.subcuentas is 'Usuario: su cupo. Analista y administrador: todas (docs/03 §4.3).';
comment on policy asientos_lectura on public.asientos is 'Usuario: los asientos de su cupo. Analista y administrador: todos (docs/03 §4.3).';
comment on policy movimientos_lectura on public.movimientos is 'Usuario: los movimientos que tocan su cupo. Analista y administrador: todos (docs/03 §4.3).';

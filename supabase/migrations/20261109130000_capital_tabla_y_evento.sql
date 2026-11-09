-- HU-014 · Tabla movimientos_capital, su lectura y el evento `capital` en el canal `admin`.
-- Fuentes: docs/06 §4.3 (tabla), docs/03 §4.3 (lectura: Analista y Administrador, el Usuario no la ve),
-- docs/09 §3 y §4 (el canal `admin` lleva `capital`; solo tabla, id, versión y estado, nunca montos; D-32).
--
-- La tabla no admite escrituras de la API: solo las RPC registrar_aporte y anular_aporte (esta historia)
-- y la confirmación de HU-015 la escriben. `movimientos_capital` no tiene columna `version` (docs/06
-- §4.3): la carga del evento la manda nula, como prevé private.carga_evento.

create type public.estado_mov_capital as enum ('registrado', 'confirmado', 'anulado');

create table public.movimientos_capital (
  id                   uuid primary key default gen_random_uuid(),
  tipo                 text not null check (tipo in ('aporte', 'retiro')),
  monto                numeric(14,2) not null check (monto > 0),
  subcuenta_origen_id  uuid references public.subcuentas (id),
  estado               public.estado_mov_capital not null default 'registrado',
  referencia_externa   text,
  nota                 text,
  registrado_por       uuid not null references public.perfiles (id),
  registrado_en        timestamptz not null default now(),
  confirmado_en        timestamptz,
  anulado_por          uuid references public.perfiles (id),
  anulado_en           timestamptz,
  motivo_anulacion     text,
  movimiento_id        uuid references public.movimientos (id),
  -- Un estado y sus marcas siempre van juntos.
  constraint movimientos_capital_anulacion_coherente check (
    (estado = 'anulado') = (anulado_por is not null and anulado_en is not null and motivo_anulacion is not null)
  ),
  constraint movimientos_capital_confirmacion_coherente check (
    (estado = 'confirmado') = (confirmado_en is not null)
  )
);

comment on table public.movimientos_capital is
  'Aportes y retiros de capital (docs/06 §4.3). Un aporte nace registrado y no mueve el libro (RN-07); su confirmación lo reparte (HU-015). Solo se escribe por RPC.';

create index movimientos_capital_estado_idx on public.movimientos_capital (estado, registrado_en desc);

alter table public.movimientos_capital enable row level security;
revoke all on table public.movimientos_capital from public, anon, authenticated, service_role;
grant select on table public.movimientos_capital to authenticated;

create policy movimientos_capital_lectura on public.movimientos_capital
for select to authenticated
using ((select private.es_supervisor()));

comment on policy movimientos_capital_lectura on public.movimientos_capital is
  'Analista y administrador (docs/03 §4.3). El Usuario no ve el capital del fondo. Cuenta no activa: ninguna.';

-- Evento `capital` en el canal `admin`: en cada alta y cada cambio de estado (registrar, anular y, en
-- HU-015, confirmar), para que la pantalla de capital (HU-099) se actualice en todos los casos.
create function private.publicar_evento_capital()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.publicar_evento(
    'admin',
    'capital',
    private.carga_evento('movimientos_capital', new.id::text, null, new.estado::text)
  );
  return null;
end;
$$;

comment on function private.publicar_evento_capital() is
  'Trigger de movimientos_capital: publica el evento capital en el canal admin con tabla, id y estado, sin montos (docs/09 §3 y §4).';

create trigger movimientos_capital_publicar_evento
after insert or update of estado on public.movimientos_capital
for each row execute function private.publicar_evento_capital();

revoke all on function private.publicar_evento_capital() from public, anon, authenticated;

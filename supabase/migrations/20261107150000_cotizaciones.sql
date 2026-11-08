-- HU-028 · Tabla `cotizaciones`: la última cotización de cada símbolo.
-- Fuentes: docs/06 §5.2 (columnas), §7 (RLS: escrituras solo por funciones) y §10 (solo la última
-- por símbolo), docs/03 §4.3 (lectura para toda persona activa), docs/09 §2.
--
-- Escritura: ninguna directa. La llena private.publicar_cotizaciones (siguiente migración).
-- Lectura: toda persona con la cuenta activa (private.rol_actual() es nulo si no lo está).

create table public.cotizaciones (
  simbolo            text primary key,
  precio             numeric(14,4) not null check (precio > 0),
  bid                numeric(14,4),
  ask                numeric(14,4),
  cierre_anterior    numeric(14,4),
  variacion_dia_pct  numeric(7,2),
  volumen_dia        bigint,
  fuente             text not null,                    -- 'alpaca-iex' o 'simulado'
  momento            timestamptz not null,             -- hora del dato según el proveedor
  recibido_en        timestamptz not null default now()
);

comment on table public.cotizaciones is
  'Último precio conocido de cada símbolo del universo y los ETF (docs/06 §5.2). Solo la última por símbolo; la llena private.publicar_cotizaciones (HU-028).';
comment on column public.cotizaciones.momento is
  'Hora del dato según el proveedor.';
comment on column public.cotizaciones.recibido_en is
  'Hora en que la ingesta lo recibió (private.ahora()). Con ella se mide la antigüedad del dato (docs/09 §2).';

alter table public.cotizaciones enable row level security;

revoke all on table public.cotizaciones from public, anon, authenticated;
grant select on table public.cotizaciones to authenticated;

create policy cotizaciones_lectura on public.cotizaciones
  for select to authenticated
  using ((select private.rol_actual()) is not null);

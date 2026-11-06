-- HU-001 · Tipos rol_app y estado_cuenta, y tabla perfiles.
-- Fuentes: docs/06 §3 (enumeraciones) y §5.1 (identidad), docs/03 §4.3 y §4.4, docs/06 §7.

create type public.rol_app as enum ('usuario', 'analista', 'administrador');
create type public.estado_cuenta as enum ('activo', 'suspendido', 'baja');

comment on type public.rol_app is
  'Rol de una persona en la plataforma. Un solo rol por persona (D-01, docs/03 §1).';
comment on type public.estado_cuenta is
  'Estado de una cuenta. Solo una cuenta activa recibe datos (docs/03 §4.2).';

create table public.perfiles (
  id                  uuid primary key references auth.users (id),
  email               text not null unique check (email = lower(email)),
  nombre              text not null,
  rol                 public.rol_app not null,
  estado              public.estado_cuenta not null default 'activo',
  recibe_sugerencias  boolean not null default true,
  preferencias_push   jsonb not null default '{}',
  -- Sin llave foránea: invitaciones (y su llave a perfiles) las crea HU-002, que agrega
  -- la restricción perfiles.invitacion_id -> invitaciones.id (docs/06 §5.1).
  invitacion_id       uuid,
  suspendido_en       timestamptz,
  baja_en             timestamptz,
  creado_en           timestamptz not null default now(),
  actualizado_en      timestamptz not null default now(),
  version             int not null default 1
);

comment on table public.perfiles is
  'La persona dentro de la plataforma: su rol y su estado deciden qué puede leer. Fuente de verdad de la autorización (docs/03 §4.2). Se escribe solo desde funciones security definer.';
comment on column public.perfiles.email is
  'En minúsculas. No se edita desde la app (RN-58).';
comment on column public.perfiles.recibe_sugerencias is
  'PM-15.';
comment on column public.perfiles.preferencias_push is
  'Preferencias de notificaciones push (docs/09 §5.3).';
comment on column public.perfiles.invitacion_id is
  'Invitación que originó la cuenta. La llave foránea la agrega HU-002 al crear invitaciones.';
comment on column public.perfiles.version is
  'Sube en cada cambio de estado o de rol; los eventos de tiempo real la llevan (docs/06 §1).';

-- RLS activo. La política de lectura llega en otra migración (necesita private.es_supervisor()).
alter table public.perfiles enable row level security;

-- Escrituras solo por funciones security definer (docs/03 §4.4, docs/06 §7, regla 1):
-- ningún rol de la API recibe insert, update ni delete, y tampoco hay políticas de escritura.
-- Sin el privilegio, un UPDATE o DELETE falla con 42501; con solo RLS afectaría cero filas sin error.
revoke all on table public.perfiles from public, anon, authenticated;
grant select on table public.perfiles to authenticated;

-- HU-002 · Tipo estado_invitacion y tabla invitaciones.
-- Fuentes: docs/06 §3 (enumeraciones) y §5.1 (identidad), docs/04 §5 (el hook la lee), docs/03 §4.3.
-- La escritura (invitar, revocar, aceptar) la hacen funciones security definer: HU-003 las RPC y
-- private.al_crear_usuario el alta. Ningún rol de la API escribe la tabla (docs/03 §4.4).

create type public.estado_invitacion as enum ('pendiente', 'aceptada', 'revocada', 'vencida');

comment on type public.estado_invitacion is
  'Estado de una invitación (docs/06 §3). Solo una pendiente por correo.';

create table public.invitaciones (
  id            uuid primary key default gen_random_uuid(),
  email         text not null check (email = lower(email)),
  rol           public.rol_app not null,
  cupo_inicial  numeric(14,2) not null default 0 check (cupo_inicial >= 0),
  estado        public.estado_invitacion not null default 'pendiente',
  expira_en     timestamptz not null default (now() + interval '7 days'),
  creada_por    uuid references public.perfiles (id),
  usuario_id    uuid references public.perfiles (id),
  creado_en     timestamptz not null default now(),
  aceptada_en   timestamptz,
  revocada_en   timestamptz
);

comment on table public.invitaciones is
  'Registro previo sin el cual nadie entra (docs/04 §1). Vence a los 7 días. Solo la lee el Administrador; se escribe desde funciones security definer.';
comment on column public.invitaciones.creada_por is
  'Quién invitó; nulo solo para el administrador inicial (docs/04 §9).';
comment on column public.invitaciones.expira_en is
  'Por defecto, 7 días después de crearse (CB-02).';

-- Una sola invitación pendiente por correo (docs/06 §5.1).
create unique index invitaciones_una_pendiente_por_correo
  on public.invitaciones (lower(email)) where estado = 'pendiente';

-- perfiles.invitacion_id nació sin llave foránea (HU-001): se agrega ahora.
alter table public.perfiles
  add constraint perfiles_invitacion_id_fkey foreign key (invitacion_id) references public.invitaciones (id);
comment on column public.perfiles.invitacion_id is
  'Invitación que originó la cuenta (docs/06 §5.1).';

alter table public.invitaciones enable row level security;

revoke all on table public.invitaciones from public, anon, authenticated;
grant select on table public.invitaciones to authenticated, supabase_auth_admin;

-- Solo el Administrador activo lee las invitaciones (docs/03 §4.3).
create policy invitaciones_lectura on public.invitaciones
for select to authenticated
using ((select private.rol_actual()) = 'administrador');

-- El servicio de Auth (hook de alta) las lee para decidir (docs/04 §5, EC-009).
create policy invitaciones_lectura_auth on public.invitaciones
for select to supabase_auth_admin
using (true);

comment on policy invitaciones_lectura on public.invitaciones is
  'Solo el administrador activo (docs/03 §4.3).';

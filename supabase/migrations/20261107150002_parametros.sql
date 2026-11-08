-- HU-002 · Tabla parametros con las claves del hook de alta.
-- Fuentes: docs/06 §5.6, docs/02 §13 (tabla de parámetros), docs/03 §4.3 (todos los roles activos leen).
-- El resto de parámetros, el historial y su edición llegan con HU-033. La escritura la hace una
-- función security definer, no la API.

create table public.parametros (
  clave            text primary key,
  valor            jsonb not null,
  tipo             text not null check (tipo in ('numero', 'texto', 'lista', 'booleano')),
  minimo           numeric,
  maximo           numeric,
  descripcion      text not null,
  actualizado_por  uuid references public.perfiles (id),
  actualizado_en   timestamptz not null default now(),
  version          int not null default 1
);

comment on table public.parametros is
  'Configuración que cambia el Administrador (docs/06 §5.6, docs/02 §13). La leen todos los roles activos; se escribe desde funciones security definer.';

alter table public.parametros enable row level security;

revoke all on table public.parametros from public, anon, authenticated;
grant select on table public.parametros to authenticated, supabase_auth_admin;

-- Cualquier cuenta activa la lee; una suspendida, de baja o sin perfil, no (docs/03 §4.2).
create policy parametros_lectura on public.parametros
for select to authenticated
using ((select private.rol_actual()) is not null);

create policy parametros_lectura_auth on public.parametros
for select to supabase_auth_admin
using (true);

-- Dominios: se desconoce el de RiTech (Q-08), así que nace vacío y en la nube nadie entra hasta
-- cargarlo. Proveedores: solo Google. La migración NUNCA agrega 'email': solo seed.sql, que no se
-- aplica en la nube (docs/04 §5, docs/15 §3, D-48).
insert into public.parametros (clave, valor, tipo, descripcion) values
  ('auth.dominios_permitidos', '[]'::jsonb, 'lista',
   'Dominios de correo que pueden darse de alta. Vacío hasta cargar el de RiTech (docs/02 §13).'),
  ('auth.proveedores_permitidos', '["google"]'::jsonb, 'lista',
   'Proveedores de ingreso permitidos en el alta. En la nube solo google (docs/04 §5).');

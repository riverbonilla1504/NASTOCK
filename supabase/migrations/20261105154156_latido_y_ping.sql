-- TT-03 · Latido del proyecto y public.ping().
-- Fuentes: docs/06 §5.6 (tabla latido, D-57) y §7 (anon solo ejecuta ping()), FR-008.

-- Una sola fila con la hora del último ping(). Solo la actualiza public.ping().
create table public.latido (
  id         boolean primary key default true check (id),  -- solo puede existir la fila true
  ultimo_en  timestamptz not null default now()             -- hora del último ping() que llegó
);

comment on table public.latido is
  'Una sola fila con la hora del último ping(). Solo la actualiza public.ping() (docs/06 §5.6, D-57).';

-- RLS activo y sin políticas: nadie la lee ni la escribe por la API.
alter table public.latido enable row level security;
revoke all on table public.latido from anon, authenticated;

-- La fila se crea aquí, para que el primer ping() tenga dónde escribir (también en la nube).
insert into public.latido default values;

-- Actualiza el latido y devuelve la hora del servidor. Lo llama a diario mantenimiento.yml.
create function public.ping()
returns timestamptz
language sql
security definer
set search_path = ''
as $$
  insert into public.latido (id, ultimo_en)
  values (true, now())
  on conflict (id) do update set ultimo_en = excluded.ultimo_en
  returning ultimo_en;
$$;

comment on function public.ping() is
  'Actualiza la fila de latido y devuelve la hora del servidor. Es lo único que anon puede ejecutar (docs/06 §7).';

revoke all on function public.ping() from public, anon, authenticated;
grant execute on function public.ping() to anon;

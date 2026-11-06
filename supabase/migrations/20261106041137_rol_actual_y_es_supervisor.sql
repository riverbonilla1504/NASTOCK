-- HU-001 · private.rol_actual() y private.es_supervisor().
-- Fuente: docs/03 §4.2. La autorización lee perfiles, nunca los claims del token (CA-6).

-- Rol de quien llama, SOLO si su cuenta está activa. Si está suspendida, de baja, no tiene
-- perfil o no hay sesión, devuelve NULL y todas las políticas niegan.
create function private.rol_actual()
returns public.rol_app
language sql
stable
security definer
set search_path = ''
as $$
  select p.rol
  from public.perfiles p
  where p.id = (select auth.uid())
    and p.estado = 'activo'
$$;

comment on function private.rol_actual() is
  'Rol de quien llama si su cuenta está activa; NULL si está suspendida, de baja o no existe (docs/03 §4.2). Lee perfiles, no los claims del token.';

create function private.es_supervisor()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(private.rol_actual() in ('analista', 'administrador'), false)
$$;

comment on function private.es_supervisor() is
  'Verdadero si quien llama es un analista o un administrador con la cuenta activa (docs/03 §4.2).';

-- Las políticas de RLS las ejecutan con el rol authenticated, que necesita execute. El esquema
-- private sigue sin usage para la API: Postgres comprueba usage al resolver el nombre al crear
-- la política, no al evaluarla.
revoke all on function private.rol_actual() from public, anon;
revoke all on function private.es_supervisor() from public, anon;
grant execute on function private.rol_actual() to authenticated;
grant execute on function private.es_supervisor() to authenticated;

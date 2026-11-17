-- HU-109 · Aislamiento por catálogo: reglas que cumple cada objeto de public, sin importar cuál.
-- Criterios: CA-1 (ningún rol escribe directo) y CA-3 (una tabla nueva sin RLS hace fallar la
-- verificación) (backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-109-*.md).
-- Reglas: docs/03 §4.3–§4.4, docs/06 §7, docs/11 §9; EC-010 (search_path) y EC-011 (vistas).
--
-- Estas pruebas recorren pg_catalog, así que cubren solas cada tabla, vista, secuencia o función
-- nueva. La matriz de lectura por tabla está en 29_aislamiento_lectura_por_tabla y la de cada RPC en
-- 30_aislamiento_por_funcion.
begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

-- Objetos de public que crea el proyecto (no los de una extensión).
create function pg_temp.objetos(p_tipos "char"[]) returns setof pg_class
language sql stable as $$
  select c.* from pg_class c
   where c.relnamespace = 'public'::regnamespace and c.relkind = any(p_tipos)
     and not exists (select 1 from pg_depend d where d.objid = c.oid and d.deptype = 'e')
$$;

-- Tablas de public sin RLS activo: la consulta que CA-3 exige que falle.
create function pg_temp.tablas_sin_rls() returns text[]
language sql stable as $$
  select coalesce(array_agg(relname::text order by relname), '{}') from pg_temp.objetos(array['r', 'p']::"char"[])
   where not relrowsecurity
$$;

-- RLS en cada tabla (CA-3) -------------------------------------------------------------------------
select is(pg_temp.tablas_sin_rls(), '{}'::text[], 'todas las tablas de public tienen RLS activo');

create table public.hu109_tabla_sin_rls (id int);
select is(pg_temp.tablas_sin_rls(), array['hu109_tabla_sin_rls'],
          'CA-3: una tabla nueva de public sin RLS hace fallar la verificación');
alter table public.hu109_tabla_sin_rls enable row level security;
select is(pg_temp.tablas_sin_rls(), '{}'::text[], 'y deja de fallar en cuanto se activa su RLS');
drop table public.hu109_tabla_sin_rls;

-- Políticas: solo de lectura y nunca para anon (06 §7, reglas 1 y 2) -------------------------------
select is(
  array(select tablename || '.' || policyname from pg_policies
         where schemaname = 'public' and cmd <> 'SELECT' order by 1),
  '{}'::text[],
  'ninguna política de public permite insert, update, delete ni all');
select is(
  array(select tablename || '.' || policyname from pg_policies
         where schemaname = 'public' and roles && array['anon', 'public']::name[] order by 1),
  '{}'::text[],
  'ninguna política de public es para anon ni para public');

-- Privilegios: ningún rol de la API escribe en tablas ni vistas (CA-1) ------------------------------
select is(
  array(select r.rol || ' · ' || o.relname || ' · ' || p.privilegio
          from pg_temp.objetos(array['r', 'p', 'v', 'm', 'f']::"char"[]) o
          cross join (values ('anon'), ('authenticated')) r (rol)
          cross join (values ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) p (privilegio)
         where has_table_privilege(r.rol, o.oid, p.privilegio)
            or (p.privilegio in ('INSERT', 'UPDATE', 'REFERENCES') and has_any_column_privilege(r.rol, o.oid, p.privilegio))
         order by 1),
  '{}'::text[],
  'anon y authenticated no tienen ningún privilegio de escritura en tablas ni vistas de public');
select is(
  array(select o.relname::text from pg_temp.objetos(array['r', 'p', 'v', 'm', 'f']::"char"[]) o
         where has_table_privilege('anon', o.oid, 'SELECT') or has_any_column_privilege('anon', o.oid, 'SELECT')
         order by 1),
  '{}'::text[],
  'anon no puede leer ninguna tabla ni vista de public');
select is(
  array(select r.rol || ' · ' || o.relname from pg_temp.objetos(array['S']::"char"[]) o
          cross join (values ('anon'), ('authenticated')) r (rol)
         where has_sequence_privilege(r.rol, o.oid, 'USAGE') or has_sequence_privilege(r.rol, o.oid, 'UPDATE')
         order by 1),
  '{}'::text[],
  'anon y authenticated no pueden usar ni avanzar las secuencias de public');

-- Vistas: respetan la RLS de quien consulta (EC-011) -----------------------------------------------
select is(
  array(select relname::text from pg_temp.objetos(array['v']::"char"[])
         where not coalesce('security_invoker=true' = any(reloptions) or 'security_invoker=on' = any(reloptions), false)
         order by 1),
  '{}'::text[],
  'toda vista de public es security_invoker');

-- Funciones: security definer con search_path vacío y anon solo ejecuta ping() --------------------
select is(
  array(select p.proname::text from pg_proc p
         where p.pronamespace = 'public'::regnamespace and p.prosecdef
           and not coalesce('search_path=""' = any(p.proconfig), false)
         order by 1),
  '{}'::text[],
  'toda función security definer de public fija search_path = '''' (EC-010)');
select is(
  array(select p.proname::text from pg_proc p
         where p.pronamespace = 'public'::regnamespace
           and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')
           and has_function_privilege('anon', p.oid, 'EXECUTE')
         order by 1),
  array['ping'],
  'anon solo puede ejecutar public.ping() (06 §7, regla 2)');

-- Esquemas internos: la API no los alcanza ----------------------------------------------------------
select ok(not has_schema_privilege('authenticated', 'private', 'USAGE') and not has_schema_privilege('anon', 'private', 'USAGE'),
          'anon y authenticated no pueden usar el esquema private');
select ok(not has_schema_privilege('authenticated', 'pruebas', 'USAGE') and not has_schema_privilege('anon', 'pruebas', 'USAGE'),
          'anon y authenticated no pueden usar el esquema pruebas');

-- Extensiones fuera de public (asesor de seguridad, lint 0014) -------------------------------------
select is(
  array(select extname::text from pg_extension where extnamespace = 'public'::regnamespace order by 1),
  '{}'::text[],
  'ninguna extensión está instalada en public');

select * from finish();
rollback;

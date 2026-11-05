-- TT-03 · Base de Supabase: esquema private, extensiones, latido, ping() y despertar_funcion.
-- Criterios de terminado de backlog/E-01-cimientos-y-calidad-continua/TT-03-*.md.
begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

-- Esquema private: existe y ningún rol de la API lo puede usar ---------------------------
select has_schema('private', 'existe el esquema private');
select ok(not has_schema_privilege('anon', 'private', 'usage'), 'anon no puede usar el esquema private');
select ok(not has_schema_privilege('authenticated', 'private', 'usage'), 'authenticated no puede usar el esquema private');

-- Extensiones ------------------------------------------------------------------------------
select has_extension('pg_cron', 'pg_cron está instalada');
select has_extension('pg_net', 'pg_net está instalada');
select has_extension('pgmq', 'pgmq está instalada');

-- Tabla latido (06 §5.6) --------------------------------------------------------------------
select has_table('public', 'latido', 'existe la tabla latido');
select ok((select relrowsecurity from pg_class where oid = 'public.latido'::regclass), 'latido tiene RLS activo');
select is((select count(*)::int from pg_policies where schemaname = 'public' and tablename = 'latido'), 0,
          'latido no tiene políticas');
select is((select count(*)::int from public.latido), 1, 'latido tiene exactamente una fila');
select throws_ok($$insert into public.latido (id) values (false)$$, '23514', null,
                 'latido no admite otra fila que la true');

-- anon solo puede ejecutar ping() (06 §7, regla 2) -----------------------------------------
select ok(has_function_privilege('anon', 'public.ping()', 'execute'), 'anon puede ejecutar ping()');
select is(
  (select count(*)::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname <> 'ping'
      and has_function_privilege('anon', p.oid, 'execute')),
  0, 'anon no puede ejecutar ninguna otra función de public');
select is(
  (select count(*)::int from information_schema.role_table_grants
    where grantee = 'anon' and table_schema = 'public'),
  0, 'anon no tiene permisos sobre ninguna tabla de public');
select ok(not has_function_privilege('anon', 'private.despertar_funcion(text)', 'execute'),
          'anon no puede ejecutar despertar_funcion');
select ok(not has_function_privilege('authenticated', 'private.despertar_funcion(text)', 'execute'),
          'authenticated no puede ejecutar despertar_funcion');

-- ping() actualiza el latido y devuelve la hora del servidor --------------------------------
update public.latido set ultimo_en = '2000-01-01 00:00:00+00';
set local role anon;
select isnt(public.ping(), null, 'ping() devuelve la hora del servidor');
reset role;
select ok((select ultimo_en from public.latido) > '2000-01-01 00:00:00+00', 'ping() actualizó latido.ultimo_en');

-- anon no lee ni escribe latido directamente -----------------------------------------------
set local role anon;
select throws_ok($$select * from public.latido$$, '42501', null, 'anon no puede leer latido');
select throws_ok($$update public.latido set ultimo_en = now()$$, '42501', null, 'anon no puede escribir latido');
select throws_ok($$select private.despertar_funcion('ingesta-mercado')$$, '42501', null,
                 'anon no puede despertar funciones');
reset role;

-- despertar_funcion: POST con la URL y el secreto de Vault (05 §7) -------------------------
select lives_ok($$select private.despertar_funcion('ingesta-mercado')$$, 'despertar_funcion encola el POST');
select is(
  (select q.url from net.http_request_queue q order by q.id desc limit 1),
  (select rtrim(decrypted_secret, '/') from vault.decrypted_secrets where name = 'url_funciones') || '/ingesta-mercado',
  'el POST va a la URL de Vault más el nombre de la función');
select is(
  (select q.headers ->> 'x-secreto-interno' from net.http_request_queue q order by q.id desc limit 1),
  (select decrypted_secret from vault.decrypted_secrets where name = 'secreto_interno'),
  'el POST lleva el secreto interno de Vault');

select * from finish();
rollback;

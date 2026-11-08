-- HU-004 · Primer administrador por configuración de despliegue.
-- Criterios: CA-1 a CA-3 (backlog/E-02-identidad-y-acceso/HU-004-*.md). Reglas: docs/04 §9. CA-4 (sin
-- credenciales en el repositorio) lo revisa scripts/verificar.sh.
-- La migración corre una sola vez: "aplicarla otra vez" (CA-2) se prueba llamando a la función.
begin;
create extension if not exists pgtap with schema extensions;
select plan(36);

-- Punto de partida como en la nube al desplegar: sin administradores, sin correo en Vault y con el dominio
-- que dejó el arranque. Todo se deshace al final (rollback).
update public.perfiles set rol = 'usuario' where rol = 'administrador';
delete from vault.secrets where name = 'admin_inicial_email';
update public.parametros set valor = '["gmail.com"]'::jsonb where clave = 'auth.dominios_permitidos';
update public.parametros set valor = '["google"]'::jsonb where clave = 'auth.proveedores_permitidos';

-- Permisos: solo el dueño ejecuta el arranque -------------------------------------------------------
select ok(not has_function_privilege('anon', 'private.crear_invitacion_inicial()', 'execute')
          and not has_function_privilege('authenticated', 'private.crear_invitacion_inicial()', 'execute')
          and not has_function_privilege('supabase_auth_admin', 'private.crear_invitacion_inicial()', 'execute'),
          'ningún rol de la API ni el servicio de Auth ejecutan crear_invitacion_inicial');
select ok(not has_function_privilege('anon', 'private.cargar_dominio_inicial()', 'execute')
          and not has_function_privilege('authenticated', 'private.cargar_dominio_inicial()', 'execute')
          and not has_function_privilege('supabase_auth_admin', 'private.cargar_dominio_inicial()', 'execute'),
          'ningún rol de la API ni el servicio de Auth ejecutan cargar_dominio_inicial');
select ok((select prosecdef from pg_proc where oid = 'private.crear_invitacion_inicial()'::regprocedure)
          and (select prosecdef from pg_proc where oid = 'private.cargar_dominio_inicial()'::regprocedure),
          'las dos son security definer');
select is((select proconfig from pg_proc where oid = 'private.crear_invitacion_inicial()'::regprocedure),
          array['search_path=""'], 'con search_path vacío');

-- Sin correo en Vault no hace nada (local y CI) -----------------------------------------------------
select is(private.crear_invitacion_inicial(), null, 'sin admin_inicial_email en Vault no crea nada');
select is((select count(*)::int from public.invitaciones where rol = 'administrador' and estado = 'pendiente'), 0,
          'y no hay invitaciones pendientes de Administrador');
select vault.create_secret('   ', 'admin_inicial_email');
select is(private.crear_invitacion_inicial(), null, 'un correo en blanco tampoco crea nada');
select vault.update_secret((select id from vault.secrets where name = 'admin_inicial_email'), ' Primer.Admin@Gmail.com ');

-- CA-1: sin administradores y con correo, crea la invitación pendiente a 7 días ------------------------
create temp table resultado on commit drop as select private.crear_invitacion_inicial() as id;
select isnt((select id from resultado), null, 'CA-1: devuelve el id de la invitación creada');
select is((select (email, rol, estado, creada_por, cupo_inicial)::text from public.invitaciones
            where id = (select id from resultado)),
          '(primer.admin@gmail.com,administrador,pendiente,,0.00)',
          'CA-1: invitación pendiente de Administrador, correo en minúsculas y sin quien la creó');
select is((select expira_en from public.invitaciones where id = (select id from resultado)),
          private.ahora() + interval '7 days', 'CA-1: vence a los 7 días');
select is((select (accion, entidad, actor_id, origen, detalle)::text from public.auditoria
            where entidad_id = (select id::text from resultado)),
          '(cuenta.invitada,invitaciones,,sistema,"{""rol"": ""administrador"", ""origen"": ""despliegue""}")',
          'queda en la bitácora como cuenta.invitada, sin actor y sin el correo');

-- CA-2: aplicarla otra vez no duplica ----------------------------------------------------------------
select is(private.crear_invitacion_inicial(), null, 'CA-2: repetirla con la invitación vigente no crea otra');
select is((select count(*)::int from public.invitaciones where email = 'primer.admin@gmail.com'), 1,
          'CA-2: sigue habiendo una sola invitación');

-- CA-3: esa persona entra con Google y queda como Administrador activo --------------------------------
select is(private.antes_de_crear_usuario(
            '{"user": {"email": "Primer.Admin@Gmail.com", "app_metadata": {"provider": "google"}}}'),
          '{}'::jsonb, 'CA-3: el hook de alta deja entrar a esa cuenta de Google');
insert into auth.users (id, email, raw_user_meta_data)
values ('00000000-0000-4000-8000-0000000000b1', 'Primer.Admin@Gmail.com', '{"full_name": "Primera Persona"}');
select is((select (rol, estado, email)::text from public.perfiles where id = '00000000-0000-4000-8000-0000000000b1'),
          '(administrador,activo,primer.admin@gmail.com)', 'CA-3: queda como Administrador activo');
select is((select estado::text from public.invitaciones where id = (select id from resultado)), 'aceptada',
          'CA-3: la invitación queda aceptada');

-- CA-2: con un administrador ya no crea nada, aunque el correo configurado sea otro -------------------
select vault.update_secret((select id from vault.secrets where name = 'admin_inicial_email'), 'otro.admin@gmail.com');
select is(private.crear_invitacion_inicial(), null, 'CA-2: con un administrador existente no crea ninguna invitación');
select is((select count(*)::int from public.invitaciones where email = 'otro.admin@gmail.com'), 0,
          'CA-2: ninguna para el otro correo');
update public.perfiles set estado = 'suspendido' where id = '00000000-0000-4000-8000-0000000000b1';
select is(private.crear_invitacion_inicial(), null, 'un administrador suspendido sigue contando como existente');

-- Sin administradores otra vez: la pendiente vigente se respeta; la vencida se reemite ----------------
update public.perfiles set rol = 'usuario' where rol = 'administrador';
insert into public.invitaciones (email, rol) values ('vigente.admin@gmail.com', 'administrador');
select vault.update_secret((select id from vault.secrets where name = 'admin_inicial_email'), 'vigente.admin@gmail.com');
select is(private.crear_invitacion_inicial(), null, 'con una pendiente vigente para ese correo no crea otra');
select is((select count(*)::int from public.invitaciones where email = 'vigente.admin@gmail.com' and estado = 'pendiente'),
          1, 'sigue habiendo una sola pendiente');

insert into public.invitaciones (email, rol, expira_en)
values ('vencida.admin@gmail.com', 'administrador', private.ahora() - interval '1 day');
select vault.update_secret((select id from vault.secrets where name = 'admin_inicial_email'), 'vencida.admin@gmail.com');
select isnt(private.crear_invitacion_inicial(), null, 'si la pendiente venció, la reemite');
select is((select count(*)::int from public.invitaciones where email = 'vencida.admin@gmail.com' and estado = 'vencida'),
          1, 'la vieja queda vencida');
select is((select count(*)::int from public.invitaciones where email = 'vencida.admin@gmail.com' and estado = 'pendiente'),
          1, 'y hay una pendiente nueva');

-- Un secreto mal cargado falla a la vista en vez de gastar la única vez --------------------------------
select vault.update_secret((select id from vault.secrets where name = 'admin_inicial_email'), 'no-es-un-correo');
select throws_ok($$select private.crear_invitacion_inicial()$$, '22023',
                 'ADMIN_INICIAL_EMAIL no tiene forma de correo (docs/04 §9)',
                 'un valor que no es un correo hace fallar el arranque');
select vault.update_secret((select id from vault.secrets where name = 'admin_inicial_email'), 'admin@outlook.com');
select throws_ok($$select private.crear_invitacion_inicial()$$, '22023',
                 'El dominio de ADMIN_INICIAL_EMAIL no está en auth.dominios_permitidos (docs/04 §9)',
                 'un correo de un dominio que el hook rechazaría hace fallar el arranque');
select is((select count(*)::int from public.invitaciones where email in ('no-es-un-correo', 'admin@outlook.com')), 0,
          'y no deja ninguna invitación');

-- Dominio inicial ---------------------------------------------------------------------------------------
update public.parametros set valor = '[]'::jsonb where clave = 'auth.dominios_permitidos';
create temp table version_antes on commit drop as
  select version from public.parametros where clave = 'auth.dominios_permitidos';
select is(private.cargar_dominio_inicial(), true, 'con los dominios vacíos los deja en ["gmail.com"]');
select is((select valor::text from public.parametros where clave = 'auth.dominios_permitidos'), '["gmail.com"]',
          'el valor queda como lo define Q-08');
select is((select version from public.parametros where clave = 'auth.dominios_permitidos'),
          (select version from version_antes) + 1,
          'sube la versión del parámetro');
select is(private.cargar_dominio_inicial(), false, 'repetirlo no cambia nada');
update public.parametros set valor = '["prueba.local"]'::jsonb where clave = 'auth.dominios_permitidos';
select is(private.cargar_dominio_inicial(), false, 'con otro dominio ya cargado no lo pisa');
select is((select valor::text from public.parametros where clave = 'auth.dominios_permitidos'), '["prueba.local"]',
          'y el valor sigue igual');

-- Hook: los mensajes nuevos (docs/04 §5 y §11, historial 3.20) -----------------------------------------
select is(private.antes_de_crear_usuario('{"user": {"email": "x@otra.test", "app_metadata": {"provider": "google"}}}')
            -> 'error' ->> 'message',
          'Solo se admiten cuentas de Google invitadas.', 'dominio no permitido: mensaje nuevo');
select is(private.antes_de_crear_usuario('{"user": {"email": "x@prueba.local", "app_metadata": {"provider": "email"}}}')
            -> 'error' ->> 'message',
          'Solo puedes ingresar con tu cuenta de Google.', 'proveedor no permitido: mensaje nuevo');
select ok(has_function_privilege('supabase_auth_admin', 'private.antes_de_crear_usuario(jsonb)', 'execute')
          and not has_function_privilege('authenticated', 'private.antes_de_crear_usuario(jsonb)', 'execute'),
          'el hook redefinido conserva sus permisos');

select * from finish();
rollback;

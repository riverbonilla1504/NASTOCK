-- HU-109 · Aislamiento por tabla: la matriz de lectura de docs/03 §4.3 y la escritura directa
-- bloqueada, para cada tabla y vista de public.
-- Criterios: CA-1 y CA-5 (backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-109-*.md).
-- Reglas: docs/03 §4.3–§4.4, docs/06 §7, docs/11 §9, docs/14 §6.
--
-- Cómo funciona: la tabla temporal `matriz` dice, por cada tabla de public, qué filas ve cada
-- persona (un predicado SQL sobre la tabla; :YO es la persona que lee). Como superusuario se cuenta
-- lo que cada persona debería ver; luego, con el rol y el token de cada una, se cuenta lo que ve de
-- verdad. Cada tabla recibe datos de esta prueba, y antes de contar se comprueba que haya filas (y,
-- en las que tienen dueño, filas propias y ajenas), para que ningún caso pase con la tabla vacía.
--
-- Cada historia que crea una tabla o una vista en public agrega su fila a `matriz` (docs/14 §6): si
-- falta, la prueba del registro falla.
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- Personas -------------------------------------------------------------------------------------
-- 01 Usuario A · 02 Usuario B · 03 Analista · 04 Administrador · 05 Usuario suspendido.
-- 09 tiene sesión pero ninguna fila en perfiles.
create temp table personas (persona text primary key, id uuid, rol text);
insert into personas values
  ('usuario_a',     '10900000-0000-4000-8000-000000000001', 'usuario'),
  ('usuario_b',     '10900000-0000-4000-8000-000000000002', 'usuario'),
  ('analista',      '10900000-0000-4000-8000-000000000003', 'analista'),
  ('administrador', '10900000-0000-4000-8000-000000000004', 'administrador'),
  ('suspendido',    '10900000-0000-4000-8000-000000000005', 'usuario'),
  ('sin_perfil',    '10900000-0000-4000-8000-000000000009', null);

set local session_replication_role = replica;
insert into auth.users (id, email)
  select id, 'aislamiento-' || persona || '@prueba.test' from personas;
set local session_replication_role = origin;

insert into public.perfiles (id, email, nombre, rol, estado, suspendido_en)
  select id, 'aislamiento-' || persona || '@prueba.test', 'Aislamiento ' || persona, rol::public.rol_app,
         case when persona = 'suspendido' then 'suspendido' else 'activo' end::public.estado_cuenta,
         case when persona = 'suspendido' then now() end
    from personas where rol is not null;

-- Datos de cada tabla ----------------------------------------------------------------------------
-- Identificadores de la prueba que las lecturas necesitan sin pasar por la RLS.
create temp table fx (clave text primary key, id uuid);
insert into fx
  select 'cupo_' || p.persona, private.crear_cupo(p.id, 0)
    from personas p where p.persona in ('usuario_a', 'usuario_b', 'suspendido');

-- Libro: un aporte a cada cupo de Usuario y otro a la Reserva, que no toca ningún cupo.
select private.registrar_movimiento('aporte', jsonb_build_array(
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'externa'), 'concepto', 'efectivo', 'monto', -1000),
  jsonb_build_object('subcuenta_id', (select id from fx where clave = 'cupo_usuario_a'), 'concepto', 'efectivo', 'monto', 1000)),
  null, 'HU-109 · aporte al cupo de A');
select private.registrar_movimiento('aporte', jsonb_build_array(
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'externa'), 'concepto', 'efectivo', 'monto', -1000),
  jsonb_build_object('subcuenta_id', (select id from fx where clave = 'cupo_usuario_b'), 'concepto', 'efectivo', 'monto', 1000)),
  null, 'HU-109 · aporte al cupo de B');
select private.registrar_movimiento('aporte', jsonb_build_array(
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'externa'), 'concepto', 'efectivo', 'monto', -500),
  jsonb_build_object('subcuenta_id', (select id from public.subcuentas where tipo = 'reserva'), 'concepto', 'efectivo', 'monto', 500)),
  null, 'HU-109 · aporte a la Reserva');

-- Órdenes, eventos, posiciones y protecciones: una compra llenada en cada cupo de Usuario.
insert into fx values
  ('orden_usuario_a', '10900000-0000-4000-8000-000000000101'),
  ('orden_usuario_b', '10900000-0000-4000-8000-000000000102');
insert into public.ordenes (id, origen, subcuenta_id, simbolo, lado, clase, tipo, tif, cantidad, precio_limite, retencion, parametros)
  select o.id, 'manual', c.id, 'AAPL', 'compra', 'simple', 'limite', 'day', 2, 50, 100, '{}'
    from fx o join fx c on c.clave = replace(o.clave, 'orden_', 'cupo_')
   where o.clave like 'orden_%';
update public.ordenes set estado = 'aceptada', broker_order_id = 'broker-' || id, enviada_en = private.ahora()
 where id in (select id from fx where clave like 'orden_%');
update public.subcuentas set retenido = 100 where id in (select id from fx where clave in ('cupo_usuario_a', 'cupo_usuario_b'));
select private.aplicar_llenado(id, 2, 50, 'filled', 0) from fx where clave like 'orden_%';
insert into public.ordenes_eventos (orden_id, estado_nuevo)
  select id, 'llenada' from fx where clave like 'orden_%';
insert into public.protecciones (posicion_id, tipo, cantidad, stop_precio)
  select p.id, 'nativa', 2, 45
    from public.posiciones p where p.subcuenta_id in (select id from fx where clave like 'cupo_%');

-- Alertas: una por audiencia y una personal para cada Usuario y para el Analista.
insert into public.alertas (tipo, severidad, audiencia, usuario_id, titulo, cuerpo, clave_dedup)
  select 'prueba.aislamiento', 'info', a.audiencia::public.audiencia, a.usuario_id, 'Alerta de prueba', 'HU-109', 'hu109-' || a.n
    from (values (1, 'todos', null::uuid), (2, 'analistas', null), (3, 'administradores', null),
                 (4, 'usuario', '10900000-0000-4000-8000-000000000001'::uuid),
                 (5, 'usuario', '10900000-0000-4000-8000-000000000002'::uuid),
                 (6, 'usuario', '10900000-0000-4000-8000-000000000003'::uuid)) a (n, audiencia, usuario_id);

-- Tablas de referencia, de la IA, de operación y de configuración.
insert into public.invitaciones (email, rol) values ('aislamiento-invitada@prueba.test', 'usuario');
insert into public.cotizaciones (simbolo, precio, fuente, momento) values ('AAPL', 50, 'prueba', now()) on conflict do nothing;
insert into public.barras_minuto (simbolo, momento, apertura, maximo, minimo, cierre, volumen)
  values ('AAPL', date_trunc('minute', now()), 50, 51, 49, 50, 100) on conflict do nothing;
insert into public.barras_diarias (simbolo, fecha, apertura, maximo, minimo, cierre, volumen)
  values ('AAPL', '2099-01-02', 50, 51, 49, 50, 100) on conflict do nothing;
insert into public.calendario_mercado (fecha, apertura, cierre, sesion)
  values ('2099-01-02', '2099-01-02 14:30Z', '2099-01-02 21:00Z', 'regular') on conflict do nothing;
with ciclo as (insert into public.ciclos_agente (disparador) values ('manual') returning id)
insert into public.evaluaciones_candidatos (ciclo_id, configuracion_version, bolsillo, simbolo, tipo, calidad_datos, resultado)
  select id, 1, 'usuarios', 'AAPL', 'entrada', 'ok', 'elegida' from ciclo;
insert into public.conciliaciones (resultado) values ('ok');
insert into public.movimientos_capital (tipo, monto, registrado_por)
  values ('aporte', 10, '10900000-0000-4000-8000-000000000004');
insert into public.parametros_historial (clave, valor_anterior, valor_nuevo, cambiado_por, motivo)
  select clave, valor, valor, '10900000-0000-4000-8000-000000000004', 'HU-109' from public.parametros limit 1;
select private.auditar('10900000-0000-4000-8000-000000000004', 'prueba.aislamiento', 'perfiles',
                       '10900000-0000-4000-8000-000000000001', '{}'::jsonb, null, null, 'app');

-- Matriz de lectura (docs/03 §4.3) ---------------------------------------------------------------
-- 'true' = todas las filas; 'false' = ninguna. La cuenta suspendida y la sesión sin perfil no ven
-- nada en ninguna tabla (03 §4.2).
create temp table matriz (tabla text primary key, clase text, ve_usuario text, ve_analista text, ve_administrador text);
insert into matriz
  select t, 'todos', 'true', 'true', 'true'
    from unnest(array['barras_diarias', 'barras_minuto', 'calendario_mercado', 'cotizaciones', 'lista_blanca', 'parametros']) t
  union all
  select t, 'supervisores', 'false', 'true', 'true'
    from unnest(array['ciclos_agente', 'conciliaciones', 'configuraciones_decision', 'evaluaciones_candidatos', 'fondos',
                      'movimientos_capital', 'salud_integraciones']) t
  union all
  select t, 'administrador', 'false', 'false', 'true'
    from unnest(array['auditoria', 'invitaciones', 'parametros_historial']) t
  union all
  select 'latido', 'nadie', 'false', 'false', 'false'
  union all
  select t, 'dueño', u, 'true', 'true'
    from (values
      ('perfiles',             'id = :YO'),
      ('subcuentas',           'tipo = ''cupo'' and usuario_id = :YO'),
      ('movimientos',          'id in (select a.movimiento_id from public.asientos a join public.subcuentas s on s.id = a.subcuenta_id where s.usuario_id = :YO)'),
      ('asientos',             'subcuenta_id in (select s.id from public.subcuentas s where s.usuario_id = :YO)'),
      ('ordenes',              'subcuenta_id in (select s.id from public.subcuentas s where s.usuario_id = :YO)'),
      ('ordenes_eventos',      'orden_id in (select o.id from public.ordenes o join public.subcuentas s on s.id = o.subcuenta_id where s.usuario_id = :YO)'),
      ('posiciones',           'subcuenta_id in (select s.id from public.subcuentas s where s.usuario_id = :YO)'),
      ('posiciones_valoradas', 'subcuenta_id in (select s.id from public.subcuentas s where s.usuario_id = :YO)'),
      ('protecciones',         'posicion_id in (select p.id from public.posiciones p join public.subcuentas s on s.id = p.subcuenta_id where s.usuario_id = :YO)')
    ) d (t, u)
  union all
  -- Por audiencia; las personales solo las ve su destinatario, también si es Administrador (HU-085 CA-1).
  select 'alertas', 'audiencia', 'audiencia = ''todos'' or usuario_id = :YO',
         'audiencia in (''todos'', ''analistas'') or usuario_id = :YO',
         'audiencia <> ''usuario'' or usuario_id = :YO';

-- Cuenta filas de public.<tabla> con el rol de quien llama (la RLS decide). Sin permiso de lectura
-- (latido) no ve ninguna fila: cuenta 0.
create function pg_temp.contar(p_tabla text, p_filtro text default 'true') returns bigint
language plpgsql as $$
declare v_n bigint;
begin
  execute format('select count(*) from public.%I where %s', p_tabla, p_filtro) into v_n;
  return v_n;
exception when insufficient_privilege then
  return 0;
end $$;

-- Ejecuta una sentencia y devuelve el SQLSTATE con que falla ('sin error' si no falla).
create function pg_temp.sqlstate_de(p_sql text) returns text
language plpgsql as $$
begin
  execute p_sql;
  return 'sin error';
exception when others then
  return sqlstate;
end $$;

-- Registro: cada tabla y vista de public tiene su fila en la matriz (14 §6) ------------------------
select is(
  array(select c.relname::text from pg_class c
         where c.relnamespace = 'public'::regnamespace and c.relkind in ('r', 'p', 'v', 'm')
           and not exists (select 1 from pg_depend d where d.objid = c.oid and d.deptype = 'e')
         order by 1),
  array(select tabla from matriz order by 1),
  'cada tabla y vista de public tiene su caso en la matriz de lectura (una nueva sin caso hace fallar la suite)');

-- Cada caso tiene datos: filas en la tabla y, si tiene dueño, propias y ajenas para cada Usuario --
select ok(pg_temp.contar(tabla) > 0, format('hay filas en %s para probar su lectura', tabla))
  from matriz order by tabla;
select ok(pg_temp.contar(m.tabla, replace(m.ve_usuario, ':YO', quote_literal(p.id) || '::uuid')) > 0
          and pg_temp.contar(m.tabla, format('not (%s)', replace(m.ve_usuario, ':YO', quote_literal(p.id) || '::uuid'))) > 0,
          format('%s tiene filas de %s y filas ajenas', m.tabla, p.persona))
  from matriz m cross join personas p
 where m.clase in ('dueño', 'audiencia') and p.persona in ('usuario_a', 'usuario_b')
 order by m.tabla, p.persona;

-- Lo que cada persona debería ver, contado como superusuario.
create temp table esperado as
  select m.tabla, p.persona,
         pg_temp.contar(m.tabla, case
           when p.persona in ('suspendido', 'sin_perfil') then 'false'
           else replace(case p.rol when 'usuario' then m.ve_usuario when 'analista' then m.ve_analista
                                    else m.ve_administrador end,
                        ':YO', quote_literal(p.id) || '::uuid') end) as filas
    from matriz m cross join personas p;
grant select on esperado, personas, matriz, fx to authenticated, anon;
grant execute on function pg_temp.contar(text, text), pg_temp.sqlstate_de(text) to authenticated, anon;

-- Lectura por persona (CA-1, CA-5) -----------------------------------------------------------------
set local role authenticated;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is(pg_temp.contar(e.tabla), e.filas, format('Usuario A ve en %s solo lo de la matriz (%s filas)', e.tabla, e.filas))
  from esperado e where e.persona = 'usuario_a' order by e.tabla;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000002", "role": "authenticated"}';
select is(pg_temp.contar(e.tabla), e.filas, format('Usuario B ve en %s solo lo de la matriz (%s filas)', e.tabla, e.filas))
  from esperado e where e.persona = 'usuario_b' order by e.tabla;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000003", "role": "authenticated"}';
select is(pg_temp.contar(e.tabla), e.filas, format('el Analista ve en %s lo de la matriz (%s filas)', e.tabla, e.filas))
  from esperado e where e.persona = 'analista' order by e.tabla;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000004", "role": "authenticated"}';
select is(pg_temp.contar(e.tabla), e.filas, format('el Administrador ve en %s lo de la matriz (%s filas)', e.tabla, e.filas))
  from esperado e where e.persona = 'administrador' order by e.tabla;

-- Token vigente que dice administrador y activo: manda perfiles (03 §4.1).
set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000005", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is(pg_temp.contar(e.tabla), 0::bigint, format('una cuenta suspendida no ve nada en %s', e.tabla))
  from esperado e where e.persona = 'suspendido' order by e.tabla;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000009", "role": "authenticated", "app_rol": "administrador", "app_estado": "activo"}';
select is(pg_temp.contar(e.tabla), 0::bigint, format('una sesión sin perfil no ve nada en %s', e.tabla))
  from esperado e where e.persona = 'sin_perfil' order by e.tabla;

-- CA-5: el cupo de otro, pedido por su identificador, no devuelve filas.
set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is(pg_temp.contar('subcuentas', format('id = %L', (select id from fx where clave = 'cupo_usuario_b'))), 0::bigint,
          'CA-5: el Usuario A no recibe el cupo de B aunque lo pida por su id');
select is(pg_temp.contar('asientos', format('subcuenta_id = %L', (select id from fx where clave = 'cupo_usuario_b'))), 0::bigint,
          'CA-5: ni sus asientos');

-- Escritura directa: ningún rol escribe en ninguna tabla ni vista (CA-1, CA-5) -------------------
-- En una tabla, insertar, actualizar, borrar y vaciar fallan por permisos (42501) antes de mirar
-- ninguna fila. Una vista que no es actualizable (posiciones_valoradas tiene un join) se rechaza
-- antes de llegar a los permisos: 55000 (no se puede escribir en la vista) o 42809 (truncate de algo
-- que no es tabla). Que tampoco tenga privilegios de escritura lo prueba 28_aislamiento_catalogo.
create temp table escrituras as
  select m.tabla, o.op,
         case when c.relkind = 'v' then array['42501', '55000', '42809'] else array['42501'] end as rechazos,
         case o.op
           when 'insert'   then format('insert into public.%I default values', m.tabla)
           when 'update'   then format('update public.%I set %2$I = %2$I', m.tabla,
                                       (select a.attname from pg_attribute a
                                         where a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
                                           and a.attidentity = '' and a.attgenerated = ''
                                         order by a.attnum limit 1))
           when 'delete'   then format('delete from public.%I', m.tabla)
           when 'truncate' then format('truncate public.%I', m.tabla)
         end as sentencia
    from matriz m
    join pg_class c on c.oid = format('public.%I', m.tabla)::regclass
    cross join (values ('insert'), ('update'), ('delete'), ('truncate')) o (op);
reset role;
grant select on escrituras to authenticated, anon;
set local role authenticated;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000001", "role": "authenticated"}';
select ok(r = any(rechazos), format('un Usuario no puede %s en %s (%s)', op, tabla, r))
  from (select tabla, op, rechazos, pg_temp.sqlstate_de(sentencia) r from escrituras order by tabla, op) x;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000003", "role": "authenticated"}';
select ok(r = any(rechazos), format('un Analista no puede %s en %s (%s)', op, tabla, r))
  from (select tabla, op, rechazos, pg_temp.sqlstate_de(sentencia) r from escrituras order by tabla, op) x;

set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000004", "role": "authenticated"}';
select ok(r = any(rechazos), format('un Administrador no puede %s en %s (%s)', op, tabla, r))
  from (select tabla, op, rechazos, pg_temp.sqlstate_de(sentencia) r from escrituras order by tabla, op) x;

-- CA-5: subirse el saldo del cupo propio tampoco.
set local request.jwt.claims to '{"sub": "10900000-0000-4000-8000-000000000001", "role": "authenticated"}';
select is(pg_temp.sqlstate_de(format('update public.subcuentas set efectivo = efectivo + 1000 where id = %L',
                                     (select id from fx where clave = 'cupo_usuario_a'))),
          '42501', 'CA-5: un Usuario no puede subirse el saldo de su cupo');
reset role;

-- anon no lee ni escribe nada (06 §7, regla 2).
set local role anon;
select is(pg_temp.sqlstate_de(format('select count(*) from public.%I', tabla)), '42501', format('anon no puede leer %s', tabla))
  from matriz order by tabla;
select ok(r = any(rechazos), format('anon no puede %s en %s (%s)', op, tabla, r))
  from (select tabla, op, rechazos, pg_temp.sqlstate_de(sentencia) r from escrituras order by tabla, op) x;
reset role;

-- Nada cambió: los saldos siguen siendo los del libro.
select is((select efectivo from public.subcuentas where id = (select id from fx where clave = 'cupo_usuario_a')),
          (select efectivo from public.subcuentas where id = (select id from fx where clave = 'cupo_usuario_b')),
          'los cupos de A y B siguen iguales tras los intentos de escritura');

select * from finish();
rollback;

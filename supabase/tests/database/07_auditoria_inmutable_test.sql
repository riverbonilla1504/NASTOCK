-- HU-107 · Trigger de inmutabilidad: auditoria rechaza UPDATE, DELETE y TRUNCATE, incluso del dueño y de
-- la llave secreta. Criterio: CA-3. Reglas: docs/11 §4.3 (punto 2) y docs/06 §1.
begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

-- El trigger ----------------------------------------------------------------------------------------
select triggers_are('public', 'auditoria', array['auditoria_inmutable'], 'auditoria tiene un solo trigger');
select ok(
  (select t.tgenabled = 'O' from pg_trigger t
    where t.tgrelid = 'public.auditoria'::regclass and t.tgname = 'auditoria_inmutable'),
  'el trigger está activo');
-- tgtype: 2 = antes de, 8 = delete, 16 = update, 32 = truncate; sin el bit 1, es por sentencia.
select is(
  (select t.tgtype::int from pg_trigger t
    where t.tgrelid = 'public.auditoria'::regclass and t.tgname = 'auditoria_inmutable'),
  2 + 8 + 16 + 32,
  'corre antes de UPDATE, DELETE y TRUNCATE, una vez por sentencia');

-- Tres registros por la puerta de siempre; auditar sigue funcionando -----------------------------------
select lives_ok(
  $$select private.auditar(null, 'ajuste.registrado', 'movimientos', '1', '{"nota": "uno"}'::jsonb),
           private.auditar(null, 'ajuste.registrado', 'movimientos', '2', '{"nota": "dos"}'::jsonb),
           private.auditar(null, 'ajuste.registrado', 'movimientos', '3', '{"nota": "tres"}'::jsonb)$$,
  'private.auditar agrega registros aunque exista el trigger');

create temp table antes as select * from public.auditoria;

-- Con el rol dueño: ni siquiera el dueño de la tabla puede cambiar la bitácora ---------------------------
select throws_ok($$update public.auditoria set accion = 'otra.accion'$$,
                 'P0001', 'auditoria: la bitácora es inmutable (UPDATE no permitido)', 'UPDATE de todos los registros');
select throws_ok($$update public.auditoria set hash = repeat('0', 64) where entidad_id = '2'$$,
                 'P0001', 'auditoria: la bitácora es inmutable (UPDATE no permitido)', 'UPDATE de un registro');
select throws_ok($$update public.auditoria set accion = 'x' where false$$,
                 'P0001', 'auditoria: la bitácora es inmutable (UPDATE no permitido)', 'UPDATE que no alcanzaría ninguna fila');
select throws_ok($$delete from public.auditoria$$,
                 'P0001', 'auditoria: la bitácora es inmutable (DELETE no permitido)', 'DELETE de todos los registros');
select throws_ok($$delete from public.auditoria where entidad_id = '2'$$,
                 'P0001', 'auditoria: la bitácora es inmutable (DELETE no permitido)', 'DELETE de un registro');
select throws_ok($$delete from public.auditoria where false$$,
                 'P0001', 'auditoria: la bitácora es inmutable (DELETE no permitido)', 'DELETE que no alcanzaría ninguna fila');
select throws_ok($$truncate public.auditoria$$,
                 'P0001', 'auditoria: la bitácora es inmutable (TRUNCATE no permitido)', 'TRUNCATE');
select throws_ok($$truncate public.auditoria restart identity cascade$$,
                 'P0001', 'auditoria: la bitácora es inmutable (TRUNCATE no permitido)', 'TRUNCATE con restart identity y cascade');
select throws_ok(
  $$insert into public.auditoria (momento, accion, entidad, origen, hash_anterior, hash)
    values (now(), 'x.y', 'tabla', 'app', (select hash_anterior from public.auditoria order by id limit 1), repeat('f', 64))
    on conflict (hash_anterior) do update set accion = 'x.y'$$,
  'P0001', 'auditoria: la bitácora es inmutable (UPDATE no permitido)', 'INSERT ... ON CONFLICT DO UPDATE');

-- "Incluso de la llave secreta": aun con los privilegios restituidos, el trigger la frena ----------------
-- Los grants se deshacen con la transacción de la prueba.
grant update, delete, truncate on public.auditoria to service_role;
set local role service_role;
select throws_ok($$update public.auditoria set accion = 'otra.accion'$$,
                 'P0001', 'auditoria: la bitácora es inmutable (UPDATE no permitido)',
                 'service_role con privilegio de UPDATE igual es rechazada');
select throws_ok($$delete from public.auditoria$$,
                 'P0001', 'auditoria: la bitácora es inmutable (DELETE no permitido)',
                 'service_role con privilegio de DELETE igual es rechazada');
select throws_ok($$truncate public.auditoria$$,
                 'P0001', 'auditoria: la bitácora es inmutable (TRUNCATE no permitido)',
                 'service_role con privilegio de TRUNCATE igual es rechazada');
reset role;

-- Nada cambió ---------------------------------------------------------------------------------------
select is(
  (select count(*)::int from (select * from public.auditoria except select * from antes) a)
  + (select count(*)::int from (select * from antes except select * from public.auditoria) b),
  0, 'los intentos de cambio no alteraron ningún registro');
select is(
  (select count(*)::int
     from (select a.hash, a.hash_anterior,
                  lag(a.hash) over (order by a.id) as previo,
                  private.hash_auditoria(a.hash_anterior, a.momento, a.actor_id, a.actor_rol, a.accion, a.entidad, a.entidad_id, a.antes, a.despues, a.detalle, a.origen) as recalculado
             from public.auditoria a) x
    where x.hash <> x.recalculado or (x.previo is not null and x.hash_anterior <> x.previo)),
  0, 'la cadena sigue íntegra');
select lives_ok($$select private.auditar(null, 'ajuste.registrado', 'movimientos', '4')$$,
                'auditar sigue agregando registros después de los intentos');

select * from finish();
rollback;

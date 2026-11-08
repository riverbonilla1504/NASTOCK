-- HU-083 · Canales privados de tiempo real: política canales_permitidos sobre realtime.messages.
-- Fuente: docs/09 §3 (canales y quién los escucha) y docs/03 §4.6. Depende de HU-001
-- (private.rol_actual() y private.es_supervisor(): NULL / falso si la cuenta no está activa).
--
-- Todos los canales son privados y solo la base de datos publica en ellos: hay política de SELECT
-- (quién escucha) y ninguna de INSERT (ningún cliente publica, CA-3).

create policy canales_permitidos on realtime.messages
for select to authenticated
using (
  case
    when (select realtime.topic()) in ('mercado', 'fondo')
      then (select private.rol_actual()) is not null
    when (select realtime.topic()) = 'usuario:' || (select auth.uid())::text
      then (select private.rol_actual()) is not null
    when (select realtime.topic()) = 'supervision'
      then (select private.es_supervisor())
    when (select realtime.topic()) = 'admin'
      then (select private.rol_actual()) = 'administrador'
    else false
  end
);

comment on policy canales_permitidos on realtime.messages is
  'Quién escucha cada canal (docs/09 §3). Sin política de INSERT: ningún cliente publica.';

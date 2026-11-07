-- HU-107 · Trigger que rechaza UPDATE, DELETE y TRUNCATE sobre auditoria.
-- Fuentes: docs/11 §4.3, punto 2 ("un trigger rechaza cualquier UPDATE o DELETE, incluso de la llave
-- secreta"), docs/06 §1 ("no se borra nada que tenga valor de auditoría"), CA-3.
--
-- Ningún rol de la API tiene ya el privilegio (migración de la tabla): este trigger es la segunda
-- línea y rechaza también al dueño de la tabla y a un rol al que se le concedieran privilegios por error.
-- Va por sentencia, no por fila: así rechaza también un UPDATE o DELETE que no alcanzaría ninguna fila,
-- y un TRUNCATE, que no dispara triggers por fila y vaciaría la bitácora de un golpe.

create function private.rechazar_cambio_auditoria()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'auditoria: la bitácora es inmutable (% no permitido)', tg_op;
end;
$$;

comment on function private.rechazar_cambio_auditoria() is
  'Función del trigger auditoria_inmutable: rechaza todo UPDATE, DELETE y TRUNCATE sobre auditoria (docs/11 §4.3).';

-- La función de un trigger solo exige execute a quien crea el trigger, no a quien lo dispara.
revoke all on function private.rechazar_cambio_auditoria() from public, anon, authenticated, service_role;

create trigger auditoria_inmutable
before update or delete or truncate on public.auditoria
for each statement execute function private.rechazar_cambio_auditoria();

comment on trigger auditoria_inmutable on public.auditoria is
  'La bitácora solo se agrega: rechaza UPDATE, DELETE y TRUNCATE, incluso del dueño y de service_role (docs/11 §4.3).';

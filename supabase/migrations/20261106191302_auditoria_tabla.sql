-- HU-107 · Tabla auditoria: la bitácora inmutable.
-- Fuentes: docs/06 §5.6 (tabla), §7 (seguridad a nivel de fila, reglas 1 y 3), docs/11 §4
-- (bitácora de auditoría), docs/03 §4.3 (solo el Administrador la lee), CA-3 y CA-5.
--
-- Esta migración crea la tabla, su RLS y sus permisos. La única puerta de escritura,
-- private.auditar(), llega en la migración siguiente y el trigger de inmutabilidad en la última.

create table public.auditoria (
  -- Crece en el orden de la cadena: auditar() toma un bloqueo antes de insertar (docs/11 §4.3).
  id             bigint generated always as identity primary key,
  momento        timestamptz not null,
  actor_id       uuid,
  actor_rol      public.rol_app,
  accion         text not null check (btrim(accion) <> ''),
  entidad        text not null check (btrim(entidad) <> ''),
  entidad_id     text,
  antes          jsonb,
  despues        jsonb,
  detalle        jsonb,
  origen         text not null check (origen in ('app', 'sistema', 'cron', 'auth')),
  hash_anterior  text not null check (hash_anterior ~ '^[0-9a-f]{64}$'),
  hash           text not null check (hash ~ '^[0-9a-f]{64}$'),
  -- Dos registros no pueden colgar del mismo anterior: una bifurcación de la cadena falla.
  constraint auditoria_hash_anterior_unico unique (hash_anterior)
);

comment on table public.auditoria is
  'Bitácora inmutable de las acciones sensibles (docs/11 §4). Solo la escribe private.auditar(); un trigger rechaza UPDATE, DELETE y TRUNCATE. Cada registro se encadena con el hash del anterior. Se guarda para siempre (docs/06 §10).';
comment on column public.auditoria.id is
  'Identidad. Crece en el orden de la cadena; una transacción revertida deja huecos en id, no en la cadena.';
comment on column public.auditoria.momento is
  'Hora de la acción, tomada de private.ahora(). Entra en el hash.';
comment on column public.auditoria.actor_id is
  'Quién actuó. NULL = el sistema. Sin llave foránea: la bitácora no depende de perfiles.';
comment on column public.auditoria.actor_rol is
  'Rol que tenía el actor al actuar, leído de perfiles por private.auditar(). NULL si es el sistema o no tiene perfil.';
comment on column public.auditoria.accion is
  'Acción del catálogo de docs/11 §4.1 (cuenta.activada, parametro.cambiado…).';
comment on column public.auditoria.entidad is
  'Tabla o entidad afectada.';
comment on column public.auditoria.entidad_id is
  'Identificador de la fila afectada, como texto. NULL si la acción no recae en una fila concreta.';
comment on column public.auditoria.antes is
  'Valor anterior. Nunca lleva llaves, tokens ni respuestas de Google (docs/11 §4.1).';
comment on column public.auditoria.despues is
  'Valor nuevo. Nunca lleva llaves, tokens ni respuestas de Google (docs/11 §4.1).';
comment on column public.auditoria.detalle is
  'Contexto de la acción. Entra en el hash. Nunca lleva llaves, tokens ni respuestas de Google (docs/11 §4.1).';
comment on column public.auditoria.origen is
  'De dónde vino la acción: app, sistema, cron o auth.';
comment on column public.auditoria.hash_anterior is
  'Hash del registro anterior; 64 ceros en el primero. Único: dos registros no cuelgan del mismo anterior.';
comment on column public.auditoria.hash is
  'sha256(hash_anterior ‖ momento ‖ actor ‖ acción ‖ entidad ‖ id ‖ detalle), calculado por private.hash_auditoria() (docs/11 §4.3).';

-- Sin escritura para nadie por la API (docs/06 §7, regla 1; docs/11 §4.3, punto 1). Supabase concede
-- por defecto todos los privilegios sobre las tablas nuevas de public a authenticated y a service_role,
-- y service_role además salta RLS: por eso se revocan de forma explícita (CA-3, "incluida la llave
-- secreta"). Sin el privilegio, un INSERT, UPDATE o DELETE falla con 42501; con solo RLS el rechazo
-- sería silencioso.
alter table public.auditoria enable row level security;
revoke all on table public.auditoria from public, anon, authenticated, service_role;
revoke all on sequence public.auditoria_id_seq from public, anon, authenticated, service_role;

-- Lectura: solo el Administrador (docs/03 §4.3 y PM-60). authenticated recibe select y la política
-- deja sin filas al Usuario, al Analista y a toda cuenta no activa (CA-5).
grant select on table public.auditoria to authenticated;

create policy auditoria_lectura on public.auditoria
for select to authenticated
using ((select private.rol_actual()) = 'administrador');

comment on policy auditoria_lectura on public.auditoria is
  'Solo el Administrador con la cuenta activa (docs/03 §4.3). Usuario, Analista y cuentas no activas: ninguna fila.';

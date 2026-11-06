-- HU-027 · Calendario del mercado.
-- Fuentes: docs/06 §5.2 (calendario_mercado), docs/06 §7 (RLS, escrituras solo por funciones),
-- docs/03 §4.3 (lo leen los tres roles), docs/02 §12 (RN-41: el calendario sale del broker, nunca se
-- programa a mano), docs/08 §6 (el estado del mercado se calcula, no se guarda).
--
-- Escritura: ninguna directa. La llena private.sincronizar_calendario, que llama calendario-mercado
-- (D-66) cada día con el calendario del broker.
--
-- Feriados y fines de semana no tienen fila: sin fila, el mercado está cerrado todo el día (CB-49).
-- Las horas van en UTC, con el horario de verano de Nueva York ya resuelto por el adaptador del
-- broker (CB-51); la base solo compara instantes y por eso no hay nada que cambiar en marzo ni en
-- noviembre.

create table public.calendario_mercado (
  fecha     date primary key,                    -- día de mercado en Nueva York
  apertura  timestamptz not null,                -- ya en UTC, con horario de verano resuelto
  cierre    timestamptz not null,
  sesion    text not null check (sesion in ('regular', 'media_jornada')),
  constraint calendario_mercado_cierre_despues_de_apertura check (cierre > apertura)
);

comment on table public.calendario_mercado is
  'Días de mercado según el calendario del broker (docs/06 §5.2). Sin fila el mercado está cerrado todo el día (feriados y fines de semana). Se sincroniza a diario; nunca se programa a mano (RN-41).';
comment on column public.calendario_mercado.apertura is
  'Apertura en UTC, con el horario de verano de Nueva York ya resuelto.';
comment on column public.calendario_mercado.sesion is
  'regular (cierre a las 16:00 de Nueva York) o media_jornada (cierre a las 13:00, RN-41).';

-- Seguridad ------------------------------------------------------------------------------------
-- RLS activo y sin políticas de escritura (docs/06 §7, regla 1); además se quitan los permisos de
-- escritura, para que un INSERT, UPDATE o DELETE directo falle con "permiso denegado".
-- anon no tiene acceso a nada (docs/06 §7, regla 2).

alter table public.calendario_mercado enable row level security;

revoke all on table public.calendario_mercado from public, anon, authenticated;
grant select on table public.calendario_mercado to authenticated;

-- Toda persona con la cuenta activa lee (docs/03 §4.3); una suspendida, de baja o sin perfil no
-- recibe filas aunque su token siga vigente (private.rol_actual() es nulo si la cuenta no está activa,
-- docs/03 §4.2). El (select …) entre paréntesis hace que Postgres lo evalúe una vez por consulta
-- (docs/06 §7, regla 4).
create policy calendario_mercado_lectura on public.calendario_mercado
  for select to authenticated
  using ((select private.rol_actual()) is not null);

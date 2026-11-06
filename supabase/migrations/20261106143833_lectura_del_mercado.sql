-- HU-026 · Lectura del universo y de las barras para toda persona activa, y llave foránea a perfiles.
-- Fuentes: docs/03 §4.2 (private.rol_actual() es NULL si la cuenta no está activa) y §4.3 (matriz de
-- lecturas: lista_blanca y barras_* las ven los tres roles), docs/06 §5.2 (actualizado_por → perfiles)
-- y §7 (regla 4: (select …) entre paréntesis para que Postgres evalúe una vez por consulta).
--
-- Depende de HU-001 (perfiles y private.rol_actual()). Las tablas se crearon cerradas en
-- *_lista_blanca_y_barras.sql: RLS activo y ninguna política.

alter table public.lista_blanca
  add constraint lista_blanca_actualizado_por_fkey
  foreign key (actualizado_por) references public.perfiles (id);

-- Toda persona con la cuenta activa lee; una suspendida, de baja o sin perfil no recibe filas
-- aunque su token siga vigente. Nadie escribe directo (ninguna política de escritura).
create policy lista_blanca_lectura on public.lista_blanca
  for select to authenticated
  using ((select private.rol_actual()) is not null);

create policy barras_diarias_lectura on public.barras_diarias
  for select to authenticated
  using ((select private.rol_actual()) is not null);

create policy barras_minuto_lectura on public.barras_minuto
  for select to authenticated
  using ((select private.rol_actual()) is not null);

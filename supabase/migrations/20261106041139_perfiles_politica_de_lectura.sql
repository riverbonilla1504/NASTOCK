-- HU-001 · Política de lectura de perfiles.
-- Fuente: docs/03 §4.3 (matriz: la suya / todas / todas) y docs/03 §4.2 (cuenta no activa: todas las
-- políticas niegan). No hay política de escritura: perfiles solo se escribe desde funciones
-- security definer (docs/06 §7, regla 1).

create policy perfiles_lectura on public.perfiles
for select to authenticated
using (
  -- Una cuenta suspendida, de baja o sin perfil no recibe ninguna fila, ni siquiera la suya (CA-2).
  (select private.rol_actual()) is not null
  and (
    (select private.es_supervisor())
    or id = (select auth.uid())
  )
);

comment on policy perfiles_lectura on public.perfiles is
  'Usuario: su fila. Analista y administrador: todas. Cuenta no activa: ninguna (docs/03 §4.3).';

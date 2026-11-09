-- HU-015 · Tabla conciliaciones, su lectura, su evento y la condición del trabajo.
-- Fuentes: docs/06 §2 (resultado_conciliacion) y §5.6 (tabla), docs/03 (lectura de supervisores),
-- docs/09 §3 (el canal `supervision` lleva `conciliacion`) y §4 (solo tabla, id, versión y estado),
-- docs/05 §7 (condición del trabajo: pasaron `conciliacion.minutos_entre` y el mercado está abierto).
--
-- Esta versión compara solo el efectivo. Las posiciones y las órdenes vivas, y la pausa automática del
-- trading ante un descuadre crítico, llegan con HU-080: por eso `detalle_posiciones` queda nulo.

create type public.resultado_conciliacion as enum ('ok', 'diferencia_menor', 'descuadre_critico');

create table public.conciliaciones (
  id                    uuid primary key default gen_random_uuid(),
  ejecutada_en          timestamptz not null default now(),
  resultado             public.resultado_conciliacion not null,
  efectivo_broker       numeric(14,2),
  efectivo_libro        numeric(14,2),
  diferencia_efectivo   numeric(14,2),
  detalle_posiciones    jsonb,
  accion_tomada         text,
  revisada_por          uuid references public.perfiles (id),
  revisada_en           timestamptz,
  nota                  text
);

create index conciliaciones_ejecutada_en_idx on public.conciliaciones (ejecutada_en desc);

comment on table public.conciliaciones is
  'Una fila por conciliación con el broker (docs/06 §5.6). Solo la escribe private.registrar_conciliacion(); la API solo lee.';

alter table public.conciliaciones enable row level security;
revoke all on table public.conciliaciones from public, anon, authenticated, service_role;
grant select on table public.conciliaciones to authenticated;

create policy conciliaciones_lectura on public.conciliaciones
for select to authenticated
using ((select private.es_supervisor()));

comment on policy conciliaciones_lectura on public.conciliaciones is
  'Analista y administrador. El Usuario no ve la conciliación. Cuenta no activa: ninguna.';

-- Evento `conciliacion` en el canal `supervision`, sin montos.
create function private.publicar_evento_conciliacion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.publicar_evento(
    'supervision',
    'conciliacion',
    private.carga_evento('conciliaciones', new.id::text, null, new.resultado::text)
  );
  return null;
end;
$$;

comment on function private.publicar_evento_conciliacion() is
  'Trigger de conciliaciones: publica el evento conciliacion en el canal supervision con tabla, id y resultado, sin montos (docs/09 §3 y §4).';

create trigger conciliaciones_publicar_evento
after insert on public.conciliaciones
for each row execute function private.publicar_evento_conciliacion();

revoke all on function private.publicar_evento_conciliacion() from public, anon, authenticated;

-- Efectivo del libro que debe respaldar la cuenta del broker: la suma del efectivo de todas las
-- subcuentas salvo `externa` (docs/10 §8: bolsillos, cupos y resultados). `externa` es la contrapartida
-- del dinero que entró o salió del fondo.
create function private.efectivo_del_libro()
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum(s.efectivo), 0)::numeric(14,2)
    from public.subcuentas s
   where s.tipo <> 'externa'
$$;

comment on function private.efectivo_del_libro() is
  'Suma del efectivo de las subcuentas que no son externa: lo que la cuenta del broker debe cubrir (docs/10 §8).';

revoke all on function private.efectivo_del_libro() from public, anon, authenticated;

-- Condición del trabajo `conciliacion` (docs/05 §7): pasaron `conciliacion.minutos_entre` desde la última
-- y el mercado está abierto. Además corre si hay un aporte registrado esperando: el efectivo de la cuenta
-- paper ya está disponible aunque el mercado esté cerrado (docs/08 §4) y esperar a la apertura retrasaría
-- el fondo sin necesidad.
create function private.conciliacion_pendiente()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    coalesce(
      (select max(c.ejecutada_en) from public.conciliaciones c)
        <= private.ahora() - make_interval(
             mins => coalesce((select (p.valor #>> '{}')::numeric from public.parametros p
                                where p.clave = 'conciliacion.minutos_entre'), 5)::int),
      true
    )
    and (
      private.mercado_abierto()
      or exists (select 1 from public.movimientos_capital m where m.tipo = 'aporte' and m.estado = 'registrado')
    )
$$;

comment on function private.conciliacion_pendiente() is
  'Condición del trabajo conciliacion: pasaron conciliacion.minutos_entre y (mercado abierto o hay un aporte registrado esperando).';

revoke all on function private.conciliacion_pendiente() from public, anon, authenticated;

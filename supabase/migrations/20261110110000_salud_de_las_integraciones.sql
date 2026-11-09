-- HU-035 · Salud de las integraciones.
-- Fuentes: docs/06 §3 (estado_integracion) y §5.6 (salud_integraciones), docs/08 §6 (ok ⇄ degradado
-- 1–2 fallos ⇄ caido ≥ 3; un éxito vuelve a ok), docs/09 §3 (evento `salud` en el canal supervision),
-- docs/11 §4.1 (integracion.caida, integracion.recuperada), docs/03 §4.3 (lectura: Analista y
-- Administrador), docs/12 CB-64, RR-21.
--
-- La alerta a Administradores y Analistas al pasar a `caido` (docs/06 §5.6, tipo `integracion_caida`) es de
-- HU-085, que crea la tabla `alertas` y aún no está en main: hoy la transición deja la auditoría, el
-- evento y un aviso (WARNING) en el registro de Postgres; la alerta se conecta al construir HU-085.

create type public.estado_integracion as enum ('ok', 'degradado', 'caido');

create table public.salud_integraciones (
  integracion      text primary key check (integracion in
                     ('alpaca_trading', 'alpaca_datos', 'alpaca_noticias', 'deepseek', 'jev', 'fcm')),
  estado           public.estado_integracion not null default 'ok',
  ultimo_exito_en  timestamptz,
  ultimo_fallo_en  timestamptz,
  fallos_seguidos  int not null default 0 check (fallos_seguidos >= 0),
  ultimo_error     text,
  actualizado_en   timestamptz not null default now()
);

comment on table public.salud_integraciones is
  'Una fila por integración externa (docs/06 §5.6). degradado: 1–2 fallos seguidos; caido: 3 o más (RR-21). Solo la escribe private.registrar_salud().';
comment on column public.salud_integraciones.ultimo_error is
  'Último error, recortado y sin llaves ni datos personales (el que pasa quien registra).';

insert into public.salud_integraciones (integracion)
values ('alpaca_trading'), ('alpaca_datos'), ('alpaca_noticias'), ('deepseek'), ('jev'), ('fcm');

alter table public.salud_integraciones enable row level security;
revoke all on table public.salud_integraciones from public, anon, authenticated, service_role;
grant select on table public.salud_integraciones to authenticated;

-- Analista y Administrador las ven todas; el Usuario, ninguna (CA-4). Cuenta no activa: ninguna.
create policy salud_integraciones_lectura on public.salud_integraciones
for select to authenticated
using ((select private.es_supervisor()));

comment on policy salud_integraciones_lectura on public.salud_integraciones is
  'Analista y administrador: todas las filas. Usuario: ninguna (docs/03 §4.3).';

-- Evento `salud` en el canal supervision en cada cambio de estado: tabla, integración y estado, sin errores.
create function private.publicar_evento_salud()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.publicar_evento(
    'supervision', 'salud',
    private.carga_evento('salud_integraciones', new.integracion, null, new.estado::text)
  );
  return null;
end;
$$;
comment on function private.publicar_evento_salud() is
  'Trigger de salud_integraciones: publica salud en el canal supervision cuando cambia el estado (docs/09 §3).';
revoke all on function private.publicar_evento_salud() from public, anon, authenticated, service_role;

create trigger salud_integraciones_publicar_evento
after update of estado on public.salud_integraciones
for each row when (old.estado is distinct from new.estado)
execute function private.publicar_evento_salud();

-- Registra un resultado de la integración y aplica la transición de estados (docs/08 §6).
-- Devuelve el estado en que queda.
create function private.registrar_salud(p_integracion text, p_ok boolean, p_error text default null)
returns public.estado_integracion
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_fila    public.salud_integraciones;
  v_ahora   timestamptz := private.ahora();
  v_fallos  int;
  v_estado  public.estado_integracion;
begin
  if p_ok is null then
    raise exception 'El resultado de la integración no puede ser nulo' using errcode = '22023';
  end if;

  select * into v_fila from public.salud_integraciones where integracion = p_integracion for update;
  if not found then
    raise exception 'NO_EXISTE' using detail = coalesce(p_integracion, '');
  end if;

  if p_ok then
    v_fallos := 0;
    v_estado := 'ok'::public.estado_integracion;
  else
    v_fallos := v_fila.fallos_seguidos + 1;
    v_estado := case when v_fallos >= 3 then 'caido'::public.estado_integracion else 'degradado'::public.estado_integracion end;
  end if;

  update public.salud_integraciones set
    estado          = v_estado,
    fallos_seguidos = v_fallos,
    ultimo_exito_en = case when p_ok then v_ahora else ultimo_exito_en end,
    ultimo_fallo_en = case when p_ok then ultimo_fallo_en else v_ahora end,
    ultimo_error    = case when p_ok then ultimo_error else left(btrim(coalesce(p_error, '')), 300) end,
    actualizado_en  = v_ahora
  where integracion = p_integracion;

  if v_estado = 'caido' and v_fila.estado <> 'caido' then
    perform private.auditar(null, 'integracion.caida', 'salud_integraciones', p_integracion,
                            jsonb_build_object('fallos_seguidos', v_fallos), p_origen => 'sistema');
    raise warning 'integracion_caida: % lleva % fallos seguidos', p_integracion, v_fallos;
  elsif v_estado = 'ok' and v_fila.estado = 'caido' then
    perform private.auditar(null, 'integracion.recuperada', 'salud_integraciones', p_integracion,
                            null, p_origen => 'sistema');
  end if;

  return v_estado;
end;
$$;

comment on function private.registrar_salud(text, boolean, text) is
  'Registra el resultado de una llamada a una integración: 1–2 fallos seguidos → degradado, 3 o más → caido, un éxito → ok. Audita integracion.caida e integracion.recuperada; el evento salud lo publica el trigger. La alerta llega con HU-085.';
revoke all on function private.registrar_salud(text, boolean, text) from public, anon, authenticated, service_role;

-- HU-034 · Interruptores del fondo: reanudar (encender) y activar_freno (apagar).
-- Fuentes: docs/03 PM-56 y PM-57; docs/02 RN-11 y RR-14; docs/06 §4 (fondos) y §8.1; docs/08 §6;
-- docs/09 §3 (evento `interruptor` en el canal admin; avisa, no informa); docs/11 §4.1
-- (interruptor.encendido, interruptor.apagado); docs/12 CB-80 (FONDO_SIN_CAPITAL).
--
-- Los interruptores nacen apagados (HU-013). Encender es del Administrador y exige un aporte confirmado.
-- Apagar (freno) es del Analista y del Administrador y exige un motivo. Los efectos del freno sobre
-- sugerencias y órdenes, y el botón para Analistas, son de HU-039; reanudar solo con la conciliación en
-- `ok`, de HU-040.

-- Evento `interruptor` en el canal admin cuando cambia un interruptor: tabla, id del fondo, sin versión y
-- sin estado (la app vuelve a leer el fondo por la API). Nunca motivos ni montos (docs/09 §4).
create function private.publicar_evento_interruptor()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.publicar_evento('admin', 'interruptor', private.carga_evento('fondos', new.id::text, null, null));
  return null;
end;
$$;

comment on function private.publicar_evento_interruptor() is
  'Trigger de fondos: publica interruptor en el canal admin cuando cambia ia_activa o trading_activo (docs/09 §3).';
revoke all on function private.publicar_evento_interruptor() from public, anon, authenticated, service_role;

create trigger fondos_publicar_interruptor
after update of ia_activa, trading_activo on public.fondos
for each row execute function private.publicar_evento_interruptor();

-- Núcleo común. p_encender: true = reanudar, false = frenar.
create function private.cambiar_interruptor(p_interruptor text, p_encender boolean, p_motivo text)
returns public.fondos
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor  uuid := (select auth.uid());
  v_rol    public.rol_app := private.rol_actual();
  v_motivo text := nullif(btrim(coalesce(p_motivo, '')), '');
  v_fondo  public.fondos;
  v_antes  boolean;
begin
  -- Sesión activa y rol (docs/03 §4.4). Encender: PM-57, solo Administrador. Apagar: PM-56.
  if v_rol is null then
    raise exception 'SESION_INVALIDA';
  end if;
  if p_encender and v_rol <> 'administrador' then
    raise exception 'NO_AUTORIZADO';
  end if;
  if not p_encender and v_rol not in ('analista', 'administrador') then
    raise exception 'NO_AUTORIZADO';
  end if;

  if p_interruptor is null or p_interruptor not in ('ia_activa', 'trading_activo') then
    raise exception 'El interruptor debe ser ia_activa o trading_activo' using errcode = '22023';
  end if;
  if not p_encender and v_motivo is null then
    raise exception 'Apagar un interruptor exige un motivo' using errcode = '22023';
  end if;

  select * into v_fondo from public.fondos for update;
  if not found then
    raise exception 'NO_EXISTE';
  end if;
  v_antes := case p_interruptor when 'ia_activa' then v_fondo.ia_activa else v_fondo.trading_activo end;
  if v_antes = p_encender then
    raise exception 'ESTADO_INVALIDO';
  end if;

  -- RN-11 / CB-80: sin un aporte confirmado el fondo no tiene capital y nada se enciende.
  if p_encender and not exists (
    select 1 from public.movimientos_capital m where m.tipo = 'aporte' and m.estado = 'confirmado'
  ) then
    raise exception 'FONDO_SIN_CAPITAL';
  end if;

  if p_encender then
    update public.fondos set
      ia_activa      = case when p_interruptor = 'ia_activa' then true else ia_activa end,
      trading_activo = case when p_interruptor = 'trading_activo' then true else trading_activo end
    where id = v_fondo.id returning * into v_fondo;
    -- El motivo de la pausa deja de valer cuando ya no queda nada apagado.
    if v_fondo.ia_activa and v_fondo.trading_activo then
      update public.fondos set motivo_pausa = null, pausado_por = null, pausado_en = null
       where id = v_fondo.id returning * into v_fondo;
    end if;
    perform private.auditar(v_actor, 'interruptor.encendido', 'fondos', v_fondo.id::text,
                            jsonb_build_object('interruptor', p_interruptor));
  else
    update public.fondos set
      ia_activa      = case when p_interruptor = 'ia_activa' then false else ia_activa end,
      trading_activo = case when p_interruptor = 'trading_activo' then false else trading_activo end,
      motivo_pausa   = v_motivo,
      pausado_por    = v_actor,
      pausado_en     = private.ahora()
    where id = v_fondo.id returning * into v_fondo;
    perform private.auditar(v_actor, 'interruptor.apagado', 'fondos', v_fondo.id::text,
                            jsonb_build_object('interruptor', p_interruptor, 'motivo', v_motivo));
  end if;
  return v_fondo;
end;
$$;
revoke all on function private.cambiar_interruptor(text, boolean, text) from public, anon, authenticated, service_role;

create function public.reanudar(p_interruptor text)
returns public.fondos
language sql
security definer
set search_path = ''
as $$ select * from private.cambiar_interruptor(p_interruptor, true, null) $$;

create function public.activar_freno(p_interruptor text, p_motivo text)
returns public.fondos
language sql
security definer
set search_path = ''
as $$ select * from private.cambiar_interruptor(p_interruptor, false, p_motivo) $$;

comment on function public.reanudar(text) is
  'Administrador (PM-57): enciende ia_activa o trading_activo. FONDO_SIN_CAPITAL sin un aporte confirmado (RN-11); ESTADO_INVALIDO si ya estaba encendido.';
comment on function public.activar_freno(text, text) is
  'Analista y Administrador (PM-56): apaga ia_activa o trading_activo con un motivo, que queda con su autor y hora. ESTADO_INVALIDO si ya estaba apagado.';

revoke all on function public.reanudar(text) from public, anon;
revoke all on function public.activar_freno(text, text) from public, anon;
grant execute on function public.reanudar(text) to authenticated;
grant execute on function public.activar_freno(text, text) to authenticated;

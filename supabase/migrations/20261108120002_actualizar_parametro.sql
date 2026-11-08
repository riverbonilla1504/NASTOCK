-- HU-033 · RPC actualizar_parametro(clave, valor, motivo).
-- Fuentes: PM-54, RN-02, docs/02 §10, docs/06 §5.6 y §6, docs/09 §3-§4, docs/11 §4.1, CB-75, CB-78.
-- Solo el Administrador activo (private.rol_actual()). Valida tipo y rango, guarda el historial, sube la
-- versión, audita parametro.cambiado y publica `parametro` en el canal admin (solo clave y versión: nunca
-- el valor). Los tres reparto.pct_* se cambian juntos con la clave `reparto`. No toca el libro: cambiar
-- el 50/25/25 no mueve dinero existente (CB-75).

-- Valida un valor contra el tipo y el rango de su fila. Falla con PARAMETRO_FUERA_DE_RANGO.
create function private.validar_valor_parametro(p_clave text, p_valor jsonb, p_tipo text, p_minimo numeric, p_maximo numeric)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_num numeric;
begin
  if p_valor is null then
    raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = p_clave;
  end if;

  if p_tipo = 'numero' then
    -- cupos.maximo_usd: JSON null significa "sin límite" (RN-19).
    if p_clave = 'cupos.maximo_usd' and jsonb_typeof(p_valor) = 'null' then
      return;
    end if;
    if jsonb_typeof(p_valor) <> 'number' then
      raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = p_clave;
    end if;
    v_num := (p_valor #>> '{}')::numeric;
    if (p_minimo is not null and v_num < p_minimo) or (p_maximo is not null and v_num > p_maximo) then
      raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = p_clave;
    end if;
  elsif p_tipo = 'booleano' then
    if jsonb_typeof(p_valor) <> 'boolean' then
      raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = p_clave;
    end if;
  elsif p_tipo = 'texto' then
    if jsonb_typeof(p_valor) <> 'string' or btrim(p_valor #>> '{}') = '' then
      raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = p_clave;
    end if;
    -- Enumerado de docs/02 §10. (ia.modelo_*: la lista permitida la valida HU-054, CB-79.)
    if p_clave like 'ia.horizonte.%' and (p_valor #>> '{}') not in ('intradía', 'días', 'semanas') then
      raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = p_clave;
    end if;
  elsif p_tipo = 'lista' then
    if jsonb_typeof(p_valor) <> 'array'
       or exists (select 1 from jsonb_array_elements(p_valor) e where jsonb_typeof(e) <> 'string') then
      raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = p_clave;
    end if;
  end if;
end;
$$;

comment on function private.validar_valor_parametro(text, jsonb, text, numeric, numeric) is
  'Valida tipo y rango de un valor de parametros (docs/02 §10). Falla con PARAMETRO_FUERA_DE_RANGO.';

-- Aplica el cambio de una clave: valida, guarda el historial, actualiza y publica el evento.
-- Devuelve el valor anterior y el nuevo para la bitácora.
create function private.aplicar_parametro(p_clave text, p_valor jsonb, p_motivo text, p_actor uuid)
returns table (anterior jsonb, nueva_version integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_fila public.parametros;
begin
  select * into v_fila from public.parametros where clave = p_clave for update;
  if not found then
    raise exception 'NO_EXISTE' using detail = p_clave;
  end if;

  perform private.validar_valor_parametro(p_clave, p_valor, v_fila.tipo, v_fila.minimo, v_fila.maximo);

  insert into public.parametros_historial (clave, valor_anterior, valor_nuevo, cambiado_por, motivo)
  values (p_clave, v_fila.valor, p_valor, p_actor, p_motivo);

  update public.parametros
     set valor = p_valor,
         actualizado_por = p_actor,
         actualizado_en = now(),
         version = version + 1
   where clave = p_clave;

  -- Los eventos avisan, no informan (docs/09 §4): clave y versión, nunca el valor.
  perform private.publicar_evento(
    'admin', 'parametro',
    private.carga_evento('parametros', p_clave, v_fila.version + 1, 'cambiado'));

  return query select v_fila.valor, v_fila.version + 1;
end;
$$;

comment on function private.aplicar_parametro(text, jsonb, text, uuid) is
  'Cambia una clave de parametros con su historial y su evento. La llama actualizar_parametro.';

create function public.actualizar_parametro(p_clave text, p_valor jsonb, p_motivo text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor    uuid := (select auth.uid());
  v_clave    text;
  v_claves   text[] := array['pct_reserva', 'pct_arriesgadas', 'pct_usuarios'];
  v_anterior jsonb;
  v_antes    jsonb := '{}'::jsonb;
  v_despues  jsonb := '{}'::jsonb;
  v_suma     numeric := 0;
  v_fila     public.parametros;
begin
  if private.rol_actual() is distinct from 'administrador' then
    raise exception 'NO_AUTORIZADO';
  end if;
  if p_motivo is null or btrim(p_motivo) = '' then
    raise exception 'Falta el motivo del cambio' using errcode = '22023';
  end if;

  if p_clave = 'reparto' then
    -- Los tres porcentajes juntos, en una sola operación, y suman 100 (RN-02, CB-78).
    if p_valor is null or jsonb_typeof(p_valor) <> 'object'
       or (select array_agg(k order by k) from jsonb_object_keys(p_valor) k)
          is distinct from (select array_agg(k order by k) from unnest(v_claves) k) then
      raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = 'reparto';
    end if;
    foreach v_clave in array v_claves loop
      select * into v_fila from public.parametros where clave = 'reparto.' || v_clave;
      perform private.validar_valor_parametro(v_fila.clave, p_valor -> v_clave, v_fila.tipo, v_fila.minimo, v_fila.maximo);
      v_suma := v_suma + (p_valor ->> v_clave)::numeric;
    end loop;
    if v_suma <> 100 then
      raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = 'reparto';
    end if;

    foreach v_clave in array v_claves loop
      select a.anterior into v_anterior
        from private.aplicar_parametro('reparto.' || v_clave, p_valor -> v_clave, p_motivo, v_actor) a;
      v_antes := v_antes || jsonb_build_object(v_clave, v_anterior);
    end loop;
    v_despues := p_valor;
  elsif p_clave like 'reparto.%' then
    -- Cambiar uno solo desbalancearía la suma (CB-78).
    raise exception 'PARAMETRO_FUERA_DE_RANGO' using detail = p_clave;
  else
    select a.anterior into v_antes from private.aplicar_parametro(p_clave, p_valor, p_motivo, v_actor) a;
    v_despues := p_valor;
  end if;

  perform private.auditar(
    v_actor, 'parametro.cambiado', 'parametros', p_clave,
    jsonb_build_object('motivo', p_motivo), v_antes, v_despues);
end;
$$;

comment on function public.actualizar_parametro(text, jsonb, text) is
  'Administrador: cambia un parámetro dentro de su rango con historial, bitácora y evento (PM-54, docs/06 §6). Los tres reparto.pct_* se cambian juntos con la clave reparto y suman 100 (CB-78).';

revoke all on function private.validar_valor_parametro(text, jsonb, text, numeric, numeric) from public, anon, authenticated;
revoke all on function private.aplicar_parametro(text, jsonb, text, uuid) from public, anon, authenticated;
revoke all on function public.actualizar_parametro(text, jsonb, text) from public, anon;
grant execute on function public.actualizar_parametro(text, jsonb, text) to authenticated;

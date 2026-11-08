-- HU-028 · private.publicar_cotizaciones(datos): guarda un lote de cotizaciones y barras de minuto
-- y avisa por el canal `mercado`.
-- Fuentes: docs/09 §2 (qué pasa en la transacción) y §4 (carga del evento `cotizaciones`),
-- docs/06 §5.2 y §8.2, FR-066, FR-067 (descarte de precios inválidos, CB-53) y FR-069.
--
-- `datos` es un arreglo jsonb; cada elemento:
--   { simbolo, precio, bid, ask, cierre_anterior, volumen_dia, fuente, momento,
--     barra_minuto: { momento, apertura, maximo, minimo, cierre, volumen } | null }
-- Un elemento con precio nulo, no numérico o menor o igual a cero, o con símbolo fuera del
-- universo, o malformado, se descarta y se informa en `descartes`; los demás se guardan.
--
-- Esta función crece con otras historias (docs/09 §2, pasos 3 a 5): protecciones virtuales
-- (HU-078), invalidación por banda (HU-067) y evento de QQQ (HU-046). Cada una agrega su paso
-- aquí, después del broadcast.
--
-- Barras de minuto: solo de los ETF (símbolos fuera del NASDAQ-100). Las de los símbolos con
-- posiciones se agregan cuando exista `posiciones` (docs/06 §10).

create function private.publicar_cotizaciones(p_datos jsonb)
returns table (guardadas integer, descartadas integer, barras_minuto integer, descartes jsonb)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ahora      timestamptz := private.ahora();
  v_universo   text[];
  v_elemento   jsonb;
  v_simbolo    text;
  v_precio     numeric;
  v_bid        numeric;
  v_ask        numeric;
  v_cierre_ant numeric;
  v_variacion  numeric;
  v_volumen    bigint;
  v_fuente     text;
  v_momento    timestamptz;
  v_barra      jsonb;
  v_guardadas  integer := 0;
  v_barras     integer := 0;
  v_descartes  jsonb := '[]'::jsonb;
  v_datos      jsonb := '[]'::jsonb;
  v_nuevo      boolean;
begin
  if p_datos is null or jsonb_typeof(p_datos) <> 'array' then
    raise exception 'publicar_cotizaciones: los datos deben ser un arreglo' using errcode = '22023';
  end if;

  select coalesce(array_agg(u.simbolo), '{}') into v_universo from private.simbolos_del_universo() u;

  for v_elemento in select e from jsonb_array_elements(p_datos) e loop
    v_simbolo := null;
    v_nuevo := false;
    begin
      v_simbolo := case when jsonb_typeof(v_elemento -> 'simbolo') = 'string' then v_elemento ->> 'simbolo' end;
      if v_simbolo is null or not (v_simbolo = any (v_universo)) then
        raise exception 'SIMBOLO_FUERA_DEL_UNIVERSO';
      end if;

      -- CB-53: precio nulo, no numérico o menor o igual a cero.
      if jsonb_typeof(v_elemento -> 'precio') is distinct from 'number'
         or (v_elemento ->> 'precio')::numeric <= 0 then
        raise exception 'PRECIO_INVALIDO';
      end if;
      v_precio := (v_elemento ->> 'precio')::numeric;

      if jsonb_typeof(v_elemento -> 'momento') is distinct from 'string' then
        raise exception 'MOMENTO_INVALIDO';
      end if;
      v_momento := (v_elemento ->> 'momento')::timestamptz;

      -- Bid, ask, cierre anterior y volumen son opcionales: lo que no sea un número válido queda nulo.
      v_bid := case when jsonb_typeof(v_elemento -> 'bid') = 'number' and (v_elemento ->> 'bid')::numeric > 0
                    then (v_elemento ->> 'bid')::numeric end;
      v_ask := case when jsonb_typeof(v_elemento -> 'ask') = 'number' and (v_elemento ->> 'ask')::numeric > 0
                    then (v_elemento ->> 'ask')::numeric end;
      v_cierre_ant := case when jsonb_typeof(v_elemento -> 'cierre_anterior') = 'number'
                                and (v_elemento ->> 'cierre_anterior')::numeric > 0
                           then (v_elemento ->> 'cierre_anterior')::numeric end;
      v_volumen := case when jsonb_typeof(v_elemento -> 'volumen_dia') = 'number'
                             and (v_elemento ->> 'volumen_dia')::numeric >= 0
                        then floor((v_elemento ->> 'volumen_dia')::numeric)::bigint end;
      v_variacion := case when v_cierre_ant is not null
                          then round((v_precio / v_cierre_ant - 1) * 100, 2) end;
      v_fuente := case when jsonb_typeof(v_elemento -> 'fuente') = 'string' and (v_elemento ->> 'fuente') <> ''
                       then v_elemento ->> 'fuente' else 'desconocida' end;

      -- Solo se reemplaza por un dato igual o más nuevo; recibido_en refleja la última consulta.
      insert into public.cotizaciones as c
        (simbolo, precio, bid, ask, cierre_anterior, variacion_dia_pct, volumen_dia, fuente, momento, recibido_en)
      values
        (v_simbolo, v_precio, v_bid, v_ask, v_cierre_ant, v_variacion, v_volumen, v_fuente, v_momento, v_ahora)
      on conflict (simbolo) do update
        set precio = excluded.precio, bid = excluded.bid, ask = excluded.ask,
            cierre_anterior = excluded.cierre_anterior, variacion_dia_pct = excluded.variacion_dia_pct,
            volumen_dia = excluded.volumen_dia, fuente = excluded.fuente, momento = excluded.momento,
            recibido_en = excluded.recibido_en
        where excluded.momento >= c.momento;
      v_nuevo := found;
    exception when others then
      v_descartes := v_descartes || jsonb_build_array(jsonb_build_object(
        'simbolo', coalesce(v_simbolo, '?'),
        'motivo', case when sqlerrm in ('SIMBOLO_FUERA_DEL_UNIVERSO', 'PRECIO_INVALIDO', 'MOMENTO_INVALIDO')
                       then sqlerrm else 'DATO_MALFORMADO' end));
      continue;
    end;

    if not v_nuevo then
      continue; -- llegó un dato más viejo que el guardado: no se publica
    end if;
    v_guardadas := v_guardadas + 1;
    v_datos := v_datos || jsonb_build_array(jsonb_build_object(
      's', v_simbolo, 'p', v_precio, 'b', v_bid, 'a', v_ask, 'vd', v_variacion));

    -- Barra de minuto de los ETF. Una barra incoherente se omite sin perder la cotización.
    v_barra := v_elemento -> 'barra_minuto';
    if jsonb_typeof(v_barra) = 'object'
       and exists (select 1 from public.lista_blanca l where l.simbolo = v_simbolo and not l.en_nasdaq100) then
      begin
        insert into public.barras_minuto as b (simbolo, momento, apertura, maximo, minimo, cierre, volumen)
        values (v_simbolo, (v_barra ->> 'momento')::timestamptz, (v_barra ->> 'apertura')::numeric,
                (v_barra ->> 'maximo')::numeric, (v_barra ->> 'minimo')::numeric,
                (v_barra ->> 'cierre')::numeric, (v_barra ->> 'volumen')::numeric::bigint)
        on conflict (simbolo, momento) do update
          set apertura = excluded.apertura, maximo = excluded.maximo, minimo = excluded.minimo,
              cierre = excluded.cierre, volumen = excluded.volumen;
        v_barras := v_barras + 1;
      exception when others then
        v_descartes := v_descartes || jsonb_build_array(jsonb_build_object(
          'simbolo', v_simbolo, 'motivo', 'BARRA_MINUTO_INVALIDA'));
      end;
    end if;
  end loop;

  -- FR-069: un solo evento por lote, con la carga de docs/09 §4 (los precios son públicos dentro
  -- de la empresa). No hay evento si nada se guardó.
  if v_guardadas > 0 then
    perform private.publicar_evento(
      'mercado', 'cotizaciones',
      jsonb_build_object('momento', v_ahora, 'datos', v_datos));
  end if;

  return query select v_guardadas, jsonb_array_length(v_descartes), v_barras, v_descartes;
end;
$$;

comment on function private.publicar_cotizaciones(jsonb) is
  'Guarda un lote de cotizaciones (descarta las inválidas, CB-53) y barras de minuto de los ETF, y publica el evento cotizaciones en el canal mercado (docs/09 §2). Crece con HU-078, HU-067 y HU-046.';

revoke all on function private.publicar_cotizaciones(jsonb) from public, anon, authenticated;

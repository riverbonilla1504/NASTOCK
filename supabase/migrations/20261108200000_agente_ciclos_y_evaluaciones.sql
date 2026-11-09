-- HU-044 a HU-048 · Corte de demo de IA (D-70): tablas del agente y funciones de private.
-- Fuentes: docs/06 §3 (tipos), §5.3 (tablas), §7 (RLS), docs/03 §4.3 (lectura), docs/07 §3 y §6.
--
-- Escritura: ninguna directa. Solo las funciones de private (las llama la Edge Function `agente`
-- por D-66). Lectura: Analista y Administrador; el Usuario ve lo suyo por `oportunidades()`.
-- Este corte no crea `senales` ni `propuestas_descartadas` (D-65, D-70): la IA solo evalúa y recomienda.

create type public.disparador_ciclo as enum ('programado', 'evento_mercado', 'manual', 'analisis');
create type public.estado_ciclo as enum ('en_curso', 'completado', 'fallido', 'omitido');

create table public.configuraciones_decision (
  id        uuid primary key default gen_random_uuid(),
  version   integer not null unique,
  preguntas jsonb not null,
  etiquetas jsonb not null,
  pesos     jsonb not null,
  umbrales  jsonb not null,
  estado    text not null check (estado in ('borrador', 'sombra', 'activa', 'retirada')),
  notas     text,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now()
);

-- Exactamente una activa (docs/06 §5.3).
create unique index configuraciones_decision_una_activa on public.configuraciones_decision ((true)) where estado = 'activa';

comment on table public.configuraciones_decision is
  'Criterios de decisión versionados: preguntas a JEV en inglés, cortes de etiquetas, pesos y umbrales (docs/06 §5.3, docs/07 §11).';
comment on column public.configuraciones_decision.umbrales is
  'Referencia de la versión. En el corte de demo (D-70) el agente lee los umbrales vigentes de `parametros` (jev.*), que mandan.';

create table public.ciclos_agente (
  id                    uuid primary key default gen_random_uuid(),
  disparador            public.disparador_ciclo not null,
  solicitado_por        uuid references public.perfiles (id),
  simbolo_foco          text,
  estado                public.estado_ciclo not null default 'en_curso',
  configuracion_version integer,
  modelo_jev            text,
  candidatas_evaluadas  integer,
  candidatas_excluidas  integer,
  senales_emitidas      integer,
  tokens_jev            integer,
  costo_usd             numeric(10,6),
  latencia_ms           integer,
  motivo_omision        text,
  error                 text,
  iniciado_en           timestamptz not null default now(),
  terminado_en          timestamptz
);

create index ciclos_agente_iniciado_idx on public.ciclos_agente (iniciado_en desc);

comment on table public.ciclos_agente is
  'Cada corrida del agente (docs/06 §5.3). La llena la función `agente` por private.registrar_ciclo y private.cerrar_ciclo.';

create table public.evaluaciones_candidatos (
  id                    uuid primary key default gen_random_uuid(),
  ciclo_id              uuid not null references public.ciclos_agente (id),
  configuracion_version integer not null,
  es_sombra             boolean not null default false,
  bolsillo              public.bolsillo not null,
  simbolo               text not null,
  tipo                  text not null check (tipo in ('entrada', 'salida')),
  calidad_datos         text not null,
  metricas              jsonb,
  estado_enviado        jsonb,
  contexto_id           uuid,
  estado_contexto       text,
  respuestas_jev        jsonb,
  modelo_jev            text,
  puntaje_cuantitativo  numeric(5,4),
  puntaje_compuesto     numeric(5,4),
  aportes               jsonb,
  contradiccion         numeric(4,3),
  confianza             numeric(4,3),
  resultado             text not null,
  explicacion           jsonb,
  senal_id              uuid,
  creado_en             timestamptz not null default now()
);

create index evaluaciones_candidatos_ciclo_idx on public.evaluaciones_candidatos (ciclo_id);

comment on table public.evaluaciones_candidatos is
  'Una fila por candidata por ciclo (docs/06 §5.3). `confianza` es la de entry_timing; `explicacion` la arma el código (docs/07 §14). contexto_id queda sin llave foránea hasta que exista contextos_ia (D-59).';
comment on column public.evaluaciones_candidatos.resultado is
  'elegida · elegible_no_elegida · no_elegible:<motivo> · excluida:<motivo> (docs/06 §5.3; no_elegible lo agrega el corte D-70: sin motor de políticas no hay descartada:<regla>).';

alter table public.configuraciones_decision enable row level security;
alter table public.ciclos_agente enable row level security;
alter table public.evaluaciones_candidatos enable row level security;

revoke all on table public.configuraciones_decision from public, anon, authenticated, service_role;
revoke all on table public.ciclos_agente from public, anon, authenticated, service_role;
revoke all on table public.evaluaciones_candidatos from public, anon, authenticated, service_role;

grant select on table public.configuraciones_decision to authenticated;
grant select on table public.ciclos_agente to authenticated;
grant select on table public.evaluaciones_candidatos to authenticated;

create policy configuraciones_decision_lectura on public.configuraciones_decision
  for select to authenticated
  using ((select private.rol_actual()) in ('analista', 'administrador'));
create policy ciclos_agente_lectura on public.ciclos_agente
  for select to authenticated
  using ((select private.rol_actual()) in ('analista', 'administrador'));
create policy evaluaciones_candidatos_lectura on public.evaluaciones_candidatos
  for select to authenticated
  using ((select private.rol_actual()) in ('analista', 'administrador'));

-- Configuración de decisión v1 (docs/07 §4.3, §6.1, §6.2, §6.3) ------------------------------------
-- Las preguntas van en inglés (JEV es más preciso así) con criterios estructurados. Las que
-- `requiere_contexto` solo se hacen cuando hay contexto (D-59: el corte no lo tiene).
-- Los cortes de etiquetas: `cortes` ordena de menor a mayor y `etiquetas` tiene un elemento más.
insert into public.configuraciones_decision (version, preguntas, etiquetas, pesos, umbrales, estado, notas)
values (
  1,
  $json$
  {
    "entrada": {
      "reversal_risk": {
        "type": "score",
        "instructions": "How likely is the recent price trend of the candidate to reverse within the horizon of the bucket described in the state?",
        "criteria": [
          "Low: the trend is healthy and not stretched",
          "Moderate: some signs of stretch, but no clear exhaustion",
          "High: stretched, overbought or far above its averages",
          "Very high: parabolic move or clear exhaustion"
        ]
      },
      "event_risk": {
        "type": "score",
        "instructions": "How much event risk (earnings, regulation, product launches, macro releases) could a typical company like this face within the horizon of the bucket described in the state? Judge only from what the state says; if nothing is said, answer the typical level.",
        "criteria": [
          "None: no relevant event expected",
          "Minor: routine events with limited impact",
          "Relevant: events such as quarterly earnings are likely inside the horizon",
          "Binary or highly uncertain: an event that can move the price sharply either way"
        ]
      },
      "entry_timing": {
        "type": "choice",
        "instructions": "For the bucket and horizon described in the state, is it a good moment to open a position in this candidate?",
        "criteria": {
          "buy_now": "The risk-adjusted setup is attractive for the horizon and the risk is acceptable",
          "wait": "Not clearly attractive yet, or too stretched: better to wait for a better entry",
          "avoid": "The setup is unattractive or the risk is too high for the horizon"
        }
      },
      "context_support": {
        "requiere_contexto": true,
        "type": "score",
        "instructions": "Does the context support or contradict the recent price behavior?",
        "criteria": ["Clearly contradicts it", "Somewhat contradicts it", "Neutral or mixed", "Somewhat supports it", "Clearly supports it"]
      },
      "data_context_conflict": {
        "requiere_contexto": true,
        "type": "noul",
        "instructions": "Does the context point in the opposite direction of the price trend (for example, price rising while company news is negative)?"
      },
      "news_sentiment": {
        "requiere_contexto": true,
        "type": "score",
        "instructions": "What is the tone of the news about the company?",
        "criteria": ["Very negative", "Negative", "Neutral", "Positive", "Very positive"]
      },
      "sector_tailwind": {
        "requiere_contexto": true,
        "type": "score",
        "instructions": "Is the sector a headwind, neutral or a tailwind for the company?",
        "criteria": ["Headwind", "Neutral", "Tailwind"]
      }
    }
  }
  $json$::jsonb,
  $json$
  {
    "rendimiento": {
      "1d":  { "cortes": [-0.02, -0.005, 0.005, 0.02] },
      "5d":  { "cortes": [-0.06, -0.02, 0.02, 0.06] },
      "20d": { "cortes": [-0.12, -0.04, 0.04, 0.12] },
      "60d": { "cortes": [-0.20, -0.07, 0.07, 0.20] },
      "etiquetas": ["strong loss", "moderate loss", "flat", "moderate gain", "strong gain"],
      "etiquetas_1d": ["sharp drop", "small drop", "flat", "small gain", "sharp gain"]
    },
    "volatilidad": {
      "cortes": [0.2, 0.4, 0.6, 0.8],
      "etiquetas": ["very low", "low", "moderate", "high", "very high"]
    },
    "rsi": {
      "cortes": [30, 45, 55, 70],
      "etiquetas": ["oversold", "weak", "neutral", "strong", "overbought"]
    },
    "distancia_maximo_52s": {
      "cortes": [-0.25, -0.10, -0.02],
      "etiquetas": ["far below the 52-week high", "well below the 52-week high", "slightly below the 52-week high", "at or near the 52-week high"]
    },
    "volumen_relativo": {
      "cortes": [0.7, 1.3, 2.0],
      "etiquetas": ["below normal", "normal", "above normal", "very high"]
    },
    "horizonte": {
      "arriesgadas": { "name": "risky", "horizon": "a few days (about one week)", "profile": "accepts higher volatility for higher expected return" },
      "usuarios": { "name": "users", "horizon": "a few weeks", "profile": "moderate: balances expected return and risk equally" }
    }
  }
  $json$::jsonb,
  $json$
  {
    "usuarios":    { "wQ": 0.25, "wC": 0.10, "wS": 0.10, "wT": 0.05, "wV": 0.20, "wE": 0.15, "wR": 0.15 },
    "arriesgadas": { "wQ": 0.30, "wC": 0.10, "wS": 0.10, "wT": 0.05, "wV": 0.15, "wE": 0.15, "wR": 0.15 }
  }
  $json$::jsonb,
  $json$
  { "confianza_minima": 0.65, "umbral_contradiccion": 0.5, "puntaje_minimo": 0.60 }
  $json$::jsonb,
  'activa',
  'Versión 1 (docs/07 §6). Corte de demo D-70.'
);

-- Funciones de private ------------------------------------------------------------------------------

-- Empieza un ciclo: uno a la vez (docs/07 §3). Un ciclo en curso de más de 5 minutos se marca
-- fallido (CB-62). Devuelve el id del ciclo nuevo o nulo si ya hay otro en curso.
create function private.registrar_ciclo(p_disparador public.disparador_ciclo)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  perform pg_advisory_xact_lock(hashtext('ciclo_agente'));

  update public.ciclos_agente
     set estado = 'fallido', error = 'colgado', terminado_en = private.ahora()
   where estado = 'en_curso' and iniciado_en < private.ahora() - interval '5 minutes';

  if exists (select 1 from public.ciclos_agente where estado = 'en_curso') then
    return null;
  end if;

  insert into public.ciclos_agente (disparador, iniciado_en)
  values (p_disparador, private.ahora())
  returning id into v_id;
  return v_id;
end;
$$;

comment on function private.registrar_ciclo(public.disparador_ciclo) is
  'Abre un ciclo del agente; nulo si hay otro en curso de menos de 5 minutos (docs/07 §3, CB-62).';

-- Cierra el ciclo con sus conteos y avisa por el canal `supervision` (solo identificadores y estado).
create function private.cerrar_ciclo(
  p_ciclo uuid,
  p_estado public.estado_ciclo,
  p_configuracion_version integer,
  p_modelo_jev text,
  p_evaluadas integer,
  p_excluidas integer,
  p_tokens integer,
  p_latencia_ms integer,
  p_motivo_omision text,
  p_error text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_estado = 'en_curso' then
    raise exception 'cerrar_ciclo: el estado final no puede ser en_curso' using errcode = '22023';
  end if;
  update public.ciclos_agente
     set estado = p_estado,
         configuracion_version = p_configuracion_version,
         modelo_jev = p_modelo_jev,
         candidatas_evaluadas = p_evaluadas,
         candidatas_excluidas = p_excluidas,
         senales_emitidas = 0,
         tokens_jev = p_tokens,
         costo_usd = 0,
         latencia_ms = p_latencia_ms,
         motivo_omision = p_motivo_omision,
         error = left(p_error, 500),
         terminado_en = private.ahora()
   where id = p_ciclo and estado = 'en_curso';
  if not found then
    raise exception 'cerrar_ciclo: el ciclo no existe o ya está cerrado' using errcode = 'P0002';
  end if;
  perform private.publicar_evento(
    'supervision', 'ciclo_agente',
    private.carga_evento('ciclos_agente', p_ciclo::text, null, p_estado::text)
  );
end;
$$;

comment on function private.cerrar_ciclo(uuid, public.estado_ciclo, integer, text, integer, integer, integer, integer, text, text) is
  'Cierra un ciclo y publica el evento ciclo_agente en el canal supervision (docs/09 §3, D-32).';

-- Guarda las evaluaciones de un ciclo en bloque. `p_filas` es un arreglo de objetos con las columnas
-- de evaluaciones_candidatos (sin id ni ciclo_id).
create function private.registrar_evaluaciones(p_ciclo uuid, p_configuracion_version integer, p_filas jsonb)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_n integer;
begin
  if p_filas is null or jsonb_typeof(p_filas) <> 'array' then
    raise exception 'registrar_evaluaciones: las filas deben ser un arreglo' using errcode = '22023';
  end if;
  insert into public.evaluaciones_candidatos (
    ciclo_id, configuracion_version, bolsillo, simbolo, tipo, calidad_datos, metricas, estado_enviado,
    estado_contexto, respuestas_jev, modelo_jev, puntaje_cuantitativo, puntaje_compuesto, aportes,
    contradiccion, confianza, resultado, explicacion
  )
  select p_ciclo, p_configuracion_version, (f ->> 'bolsillo')::public.bolsillo, f ->> 'simbolo',
         coalesce(f ->> 'tipo', 'entrada'), f ->> 'calidad_datos', f -> 'metricas', f -> 'estado_enviado',
         f ->> 'estado_contexto', f -> 'respuestas_jev', f ->> 'modelo_jev',
         (f ->> 'puntaje_cuantitativo')::numeric, (f ->> 'puntaje_compuesto')::numeric, f -> 'aportes',
         (f ->> 'contradiccion')::numeric, (f ->> 'confianza')::numeric, f ->> 'resultado', f -> 'explicacion'
    from jsonb_array_elements(p_filas) f;
  get diagnostics v_n = row_count;
  return v_n;
end;
$$;

comment on function private.registrar_evaluaciones(uuid, integer, jsonb) is
  'Guarda en bloque las evaluaciones de un ciclo (docs/07 §3, FR-118).';

-- Configuración de decisión activa (una fila).
create function private.configuracion_activa()
returns table (version integer, preguntas jsonb, etiquetas jsonb, pesos jsonb, umbrales jsonb)
language sql
stable
security definer
set search_path = ''
as $$
  select c.version, c.preguntas, c.etiquetas, c.pesos, c.umbrales
    from public.configuraciones_decision c
   where c.estado = 'activa'
$$;

-- Parámetros ia.* y jev.* que usa el agente (valores jsonb tal cual).
create function private.parametros_del_agente()
returns table (clave text, valor jsonb)
language sql
stable
security definer
set search_path = ''
as $$
  select p.clave, p.valor
    from public.parametros p
   where p.clave like 'ia.%' or p.clave like 'jev.%' or p.clave = 'mercado.max_antiguedad_cotizacion_seg'
$$;

-- Universo del agente: símbolos activos de Arriesgadas y Usuarios con su sector.
create function private.universo_del_agente()
returns table (bolsillo public.bolsillo, simbolo text, sector text, en_nasdaq100 boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select l.bolsillo, l.simbolo, l.sector, l.en_nasdaq100
    from public.lista_blanca l
   where l.activo
   order by l.bolsillo, l.simbolo
$$;

-- Barras diarias de los últimos `p_dias` días calendario, de todo el universo activo y QQQ.
create function private.barras_del_agente(p_dias integer)
returns table (simbolo text, fecha date, apertura numeric, maximo numeric, minimo numeric, cierre numeric, volumen bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select b.simbolo, b.fecha, b.apertura, b.maximo, b.minimo, b.cierre, b.volumen
    from public.barras_diarias b
   where b.fecha >= (private.ahora() at time zone 'America/New_York')::date - greatest(p_dias, 1)
     and b.simbolo in (select s.simbolo from private.simbolos_del_universo() s)
   order by b.simbolo, b.fecha
$$;

create function private.cotizaciones_del_agente()
returns table (simbolo text, precio numeric, variacion_dia_pct numeric, recibido_en timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select c.simbolo, c.precio, c.variacion_dia_pct, c.recibido_en
    from public.cotizaciones c
$$;

-- Hora y estado del mercado para el ciclo.
create function private.estado_del_agente()
returns table (ahora timestamptz, mercado_en_ventana boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select private.ahora(), private.mercado_en_ventana(interval '0 minutes')
$$;

-- ¿Le toca un ciclo al agente? (para el trabajo de pg_cron, docs/05 §7)
--  · Con la ventana de compras abierta: pasaron ia.minutos_entre_ciclos desde el último ciclo.
--  · Con el mercado cerrado (D-70): no hay un ciclo completado en 6 horas ni un intento en 30 minutos,
--    para que Oportunidades siempre tenga contenido.
create function private.ciclo_agente_pendiente()
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_minutos numeric;
begin
  if exists (
    select 1 from public.ciclos_agente
     where estado = 'en_curso' and iniciado_en > private.ahora() - interval '5 minutes'
  ) then
    return false;
  end if;

  if private.ventana_compras_abierta() then
    select coalesce((select (p.valor #>> '{}')::numeric from public.parametros p where p.clave = 'ia.minutos_entre_ciclos'), 15)
      into v_minutos;
    return not exists (
      select 1 from public.ciclos_agente
       where estado in ('completado', 'omitido', 'en_curso')
         and iniciado_en > private.ahora() - make_interval(secs => v_minutos * 60)
    );
  end if;

  return not exists (select 1 from public.ciclos_agente
                      where estado = 'completado' and iniciado_en > private.ahora() - interval '6 hours')
     and not exists (select 1 from public.ciclos_agente
                      where iniciado_en > private.ahora() - interval '30 minutes');
end;
$$;

comment on function private.ciclo_agente_pendiente() is
  'Verdadero si el trabajo ciclo_agente debe despertar a la función `agente` (docs/07 §2; con mercado cerrado, D-70).';

revoke all on function private.registrar_ciclo(public.disparador_ciclo) from public, anon, authenticated;
revoke all on function private.cerrar_ciclo(uuid, public.estado_ciclo, integer, text, integer, integer, integer, integer, text, text) from public, anon, authenticated;
revoke all on function private.registrar_evaluaciones(uuid, integer, jsonb) from public, anon, authenticated;
revoke all on function private.configuracion_activa() from public, anon, authenticated;
revoke all on function private.parametros_del_agente() from public, anon, authenticated;
revoke all on function private.universo_del_agente() from public, anon, authenticated;
revoke all on function private.barras_del_agente(integer) from public, anon, authenticated;
revoke all on function private.cotizaciones_del_agente() from public, anon, authenticated;
revoke all on function private.estado_del_agente() from public, anon, authenticated;
revoke all on function private.ciclo_agente_pendiente() from public, anon, authenticated;

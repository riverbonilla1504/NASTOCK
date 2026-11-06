-- Datos de la base local y de CI. Supabase lo aplica en `supabase db reset` y nunca
-- en `supabase db push` a la nube (docs/05 §12, docs/15 §3).

-- Secretos de Vault que usa private.despertar_funcion (docs/05 §10.1).
-- Son valores de prueba solo para local y CI: no son llaves reales.
-- En la nube se crean una vez por SQL con los valores reales (docs/16 §3.2).
select vault.create_secret('http://host.docker.internal:54321/functions/v1', 'url_funciones');
select vault.create_secret('solo-local-no-es-secreto', 'secreto_interno');

-- Esquema `pruebas`: ayudas de prueba para local y CI (docs/15 §3, TT-05).
-- Vive SOLO aquí: ninguna migración lo crea, porque las migraciones llegan a la nube con
-- `supabase db push` y este esquema no debe existir allí (CB-91). Sin él,
-- private.ahora() devuelve now().
-- Son objetos de ayuda para las pruebas, sin grants para anon ni authenticated. Quién los
-- puede llamar desde las pruebas E2E lo decide TT-06.
create schema pruebas;
revoke all on schema pruebas from public, anon, authenticated;

comment on schema pruebas is
  'Ayudas de prueba: reloj fijable, escenario de cada proveedor simulado y push simulados. Solo local y CI; lo crea seed.sql (docs/15 §3).';

-- Reloj: una sola fila. fijada_en nulo = hora real.
create table pruebas.reloj (
  id         boolean primary key default true check (id),  -- solo puede existir la fila true
  fijada_en  timestamptz                                    -- hora que devuelve private.ahora(); nulo: la real
);
insert into pruebas.reloj default values;
alter table pruebas.reloj enable row level security;
revoke all on table pruebas.reloj from public, anon, authenticated;

-- Fija la hora que devuelve private.ahora(). Con nulo vuelve a la hora real.
-- Devuelve la hora que queda vigente.
create function pruebas.fijar_reloj(p_hora timestamptz)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
begin
  update pruebas.reloj set fijada_en = p_hora;
  return private.ahora();
end;
$$;

comment on function pruebas.fijar_reloj(timestamptz) is
  'Fija la hora de private.ahora(). Nulo vuelve a la hora real. Devuelve la hora vigente.';
revoke all on function pruebas.fijar_reloj(timestamptz) from public, anon, authenticated;

-- Escenario de cada proveedor simulado (docs/10 §9: llenado parcial, rechazo, sin
-- respuesta, confianza baja, contradicción…). Los nombres de los escenarios los define
-- cada proveedor simulado; sin fila, el proveedor se comporta de forma normal.
create table pruebas.escenarios (
  proveedor  text primary key
             check (proveedor in ('broker', 'mercado', 'noticias', 'contexto', 'jev', 'push')),
  escenario  text not null check (escenario <> '')
);
alter table pruebas.escenarios enable row level security;
revoke all on table pruebas.escenarios from public, anon, authenticated;

comment on table pruebas.escenarios is
  'Escenario forzado de cada proveedor simulado. Sin fila: comportamiento normal. Los proveedores son los de _shared/proveedores.ts.';

-- Elige el escenario de un proveedor. Con escenario nulo lo vuelve al comportamiento normal.
create function pruebas.elegir_escenario(p_proveedor text, p_escenario text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_escenario is null then
    delete from pruebas.escenarios where proveedor = p_proveedor;
  else
    insert into pruebas.escenarios (proveedor, escenario)
    values (p_proveedor, p_escenario)
    on conflict (proveedor) do update set escenario = excluded.escenario;
  end if;
end;
$$;

comment on function pruebas.elegir_escenario(text, text) is
  'Elige el escenario de un proveedor simulado. Escenario nulo: vuelve al comportamiento normal.';
revoke all on function pruebas.elegir_escenario(text, text) from public, anon, authenticated;

-- Push simulados: el FCM simulado guarda aquí lo que enviaría (docs/10 §9).
create table pruebas.push_simulados (
  id         bigint generated always as identity primary key,
  token_fcm  text not null,                        -- dispositivo al que iba (06 §5.1, dispositivos)
  titulo     text not null,
  cuerpo     text not null,
  datos      jsonb not null default '{}',          -- datos de la notificación, sin montos (09 §5.2)
  creado_en  timestamptz not null default private.ahora()
);
alter table pruebas.push_simulados enable row level security;
revoke all on table pruebas.push_simulados from public, anon, authenticated;

comment on table pruebas.push_simulados is
  'Push que el FCM simulado habría enviado. Las pruebas E2E las leen aquí.';

-- Barras diarias de prueba (docs/15 §3, HU-026): un año de lunes a viernes, del 2025-11-03 al
-- 2026-10-30 (260 días), para cada símbolo de la lista blanca.
--
-- Es el MISMO algoritmo que el proveedor de mercado simulado (supabase/functions/_shared/
-- mercado/simulado.ts, contrato en specs/026-universo-y-carga-historica/contracts/mercado.md):
-- una caminata determinista, función de (símbolo, día) acumulada desde el ancla 2020-01-01.
-- Así, las barras sembradas y las que carga el simulado coinciden y no hay saltos entre ellas.
-- Si cambias algo aquí, cámbialo también allá: simulado_test.ts y 02_universo_y_barras_test.sql
-- comprueban los mismos valores conocidos.
--
-- Generador: x0 = (semilla·131 + día·7919 + 12345) mod 2147483647 y x(k+1) = 48271·x(k) mod
-- 2147483647, con u_k = x_k / 2147483647. `día` = días desde 2000-01-01. Solo con enteros
-- (bigint) hasta u_k; el precio sale de float8, como en TypeScript.
insert into public.barras_diarias (simbolo, fecha, apertura, maximo, minimo, cierre, volumen)
with
simbolos as (
  select distinct l.simbolo from public.lista_blanca l
),
semillas as (
  -- Σ código(letra_i) · 31^(n−1−i) mod 2147483647
  select s.simbolo,
         ((select sum(ascii(substr(s.simbolo, i, 1))::numeric * (31::numeric ^ (length(s.simbolo) - i)))
             from generate_series(1, length(s.simbolo)) as i) % 2147483647)::bigint as semilla
    from simbolos s
),
perfil as (
  select s.simbolo,
         s.semilla,
         case s.simbolo
           when 'QQQ'  then 400
           when 'QLD'  then 80
           when 'TQQQ' then 60
           else 30 + (s.semilla % 370)
         end::float8 as base,
         case s.simbolo when 'QLD' then 2 when 'TQQQ' then 3 end as factor,
         case s.simbolo when 'QQQ' then 0.012 else 0.015 end::float8 as sigma
    from semillas s
),
dias as (
  select g::date as fecha, (g::date - date '2000-01-01') as dia
    from generate_series(date '2020-01-01', date '2026-10-30', interval '1 day') g
   where extract(isodow from g) <= 5
),
retorno_qqq as (
  -- u1 de QQQ en cada día: lo siguen QLD (×2) y TQQQ (×3)
  select d.dia,
         (((48271 * ((p.semilla * 131 + d.dia * 7919 + 12345) % 2147483647)) % 2147483647)::float8
            / 2147483647 - 0.5) * 2 * p.sigma as r
    from dias d
    cross join perfil p
   where p.simbolo = 'QQQ'
),
x0 as (
  select p.simbolo, p.base, p.sigma, p.factor, d.fecha, d.dia,
         (p.semilla * 131 + d.dia * 7919 + 12345) % 2147483647 as x0
    from perfil p cross join dias d
),
x1 as (select x0.*, (48271 * x0) % 2147483647 as x1 from x0),
x2 as (select x1.*, (48271 * x1) % 2147483647 as x2 from x1),
x3 as (select x2.*, (48271 * x2) % 2147483647 as x3 from x2),
x4 as (select x3.*, (48271 * x3) % 2147483647 as x4 from x3),
x5 as (select x4.*, (48271 * x4) % 2147483647 as x5 from x4),
retornos as (
  select x5.simbolo, x5.base, x5.fecha,
         x5.x2::float8 / 2147483647 as u2,
         x5.x3::float8 / 2147483647 as u3,
         x5.x4::float8 / 2147483647 as u4,
         x5.x5::float8 / 2147483647 as u5,
         case
           when x5.factor is not null then x5.factor * q.r
           else (x5.x1::float8 / 2147483647 - 0.5) * 2 * x5.sigma
         end as r
    from x5
    join retorno_qqq q on q.dia = x5.dia
),
acumulados as (
  select r.*,
         sum(r.r) over (partition by r.simbolo order by r.fecha) as acum
    from retornos r
),
con_anterior as (
  select a.*,
         coalesce(lag(a.acum) over (partition by a.simbolo order by a.fecha), 0::float8) as acum_ant
    from acumulados a
),
barras as (
  select c.simbolo, c.fecha,
         c.base * exp(c.acum) as cierre,
         c.base * exp(c.acum_ant) * exp((c.u2 - 0.5) * 0.01) as apertura,
         c.u3, c.u4, c.u5
    from con_anterior c
)
select b.simbolo,
       b.fecha,
       round(b.apertura::numeric, 4),
       round((greatest(b.apertura, b.cierre) * (1 + b.u3 * 0.01))::numeric, 4),
       round((least(b.apertura, b.cierre) * (1 - b.u4 * 0.01))::numeric, 4),
       round(b.cierre::numeric, 4),
       floor(1000000 * (0.5 + b.u5))::bigint
  from barras b
 where b.fecha between date '2025-11-03' and date '2026-10-30';

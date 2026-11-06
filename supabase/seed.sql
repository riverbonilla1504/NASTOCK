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

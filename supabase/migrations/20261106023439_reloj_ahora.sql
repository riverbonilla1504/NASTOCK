-- TT-05 · private.ahora(): la única fuente de "ahora" para la lógica.
-- Fuentes: docs/15 §3 (Reloj), docs/05 §12 (seed.sql crea las ayudas de prueba), FR-006.
--
-- Toda la lógica de negocio (vencimientos, ventanas de mercado, cierres) toma la hora de
-- esta función y no de now(). En local y CI, seed.sql crea el esquema `pruebas`, y con
-- `pruebas.fijar_reloj(...)` la hora se puede fijar. En la nube ese esquema no existe y
-- la función devuelve now().
--
-- Esta migración NO crea el esquema `pruebas` ni nada dentro de él: si lo creara, llegaría
-- a la nube con `supabase db push` (CB-91). Por eso la función busca la tabla del reloj
-- en el momento de la llamada, con SQL dinámico, y funciona igual si no existe.

create function private.ahora()
returns timestamptz
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_fijada timestamptz;
begin
  -- pruebas.reloj existe solo si seed.sql la creó (local y CI).
  if to_regclass('pruebas.reloj') is not null then
    execute 'select fijada_en from pruebas.reloj' into v_fijada;
  end if;
  return coalesce(v_fijada, now());
end;
$$;

comment on function private.ahora() is
  'Única fuente de "ahora" para la lógica. Devuelve la hora fijada con pruebas.fijar_reloj() si el esquema pruebas existe (solo local y CI) y now() en los demás casos (docs/15 §3).';

revoke all on function private.ahora() from public, anon, authenticated;

-- HU-109 · Ajustes que encontró la suite de aislamiento al recorrer el catálogo de public.
-- Fuentes: docs/06 §7 (ningún rol escribe directo; anon sin acceso), docs/11 §9 (asesor de
-- seguridad sin advertencias en cada PR), docs/03 §4.3 y §4.4.

-- 1. posiciones_valoradas (HU-074) conservó los privilegios que Supabase da por defecto a una
-- vista nueva: authenticated tenía insert, update, delete, truncate, references y trigger. La vista
-- no es actualizable (tiene un join) y es security_invoker, así que no se podía escribir por ella,
-- pero ningún rol de la API debe tener privilegios de escritura en public (06 §7, regla 1).
revoke insert, update, delete, truncate, references, trigger on public.posiciones_valoradas
  from anon, authenticated;

-- 2. La secuencia de ordenes_eventos (HU-073) también conservó los privilegios por defecto:
-- authenticated podía usarla y avanzarla (nextval, setval). Solo la usan las funciones que insertan.
revoke all on sequence public.ordenes_eventos_id_seq from anon, authenticated;

-- Y para que cada tabla, vista o secuencia nueva arranque sin escritura para authenticated (anon ya
-- arranca sin nada, migración del esquema private). Cada migración sigue dando solo el select que
-- necesita.
alter default privileges for role postgres in schema public
  revoke insert, update, delete, truncate, references, trigger on tables from authenticated;
alter default privileges for role postgres in schema public
  revoke all on sequences from authenticated;

-- 3. El asesor de seguridad de Supabase (supabase db advisors) marca extension_in_public: pg_net se
-- creó sin esquema y quedó registrada en public, aunque sus objetos viven en el esquema net. No es
-- reubicable (alter extension ... set schema falla), así que se vuelve a crear en extensions, como
-- las demás. Nada depende de ella con una dependencia fija: private.despertar_funcion la llama desde
-- plpgsql y los trabajos de pg_cron la nombran en su texto. Las solicitudes en vuelo se pierden; el
-- trabajo siguiente de pg_cron vuelve a despertar cada función.
drop extension if exists pg_net;
create extension pg_net with schema extensions;

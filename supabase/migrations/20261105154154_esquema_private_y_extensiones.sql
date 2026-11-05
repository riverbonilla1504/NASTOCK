-- TT-03 · Esquema private y extensiones base.
-- Fuentes: docs/05 §3.2 (servicios de Supabase), docs/06 §1 (esquemas) y §7 (seguridad).

-- Esquema private: funciones auxiliares e internas. No está en [api].schemas de
-- config.toml, así que la API no lo expone, y ningún rol de la API lo puede usar.
create schema if not exists private;
revoke all on schema private from public;
revoke all on schema private from anon, authenticated;

-- Reloj (pg_cron), llamadas HTTP desde SQL (pg_net) y colas confiables (pgmq).
create extension if not exists pg_cron;
create extension if not exists pg_net;
create extension if not exists pgmq;

-- anon no tiene acceso a nada salvo public.ping() (06 §7, regla 2).
-- Supabase da por defecto permisos a anon sobre todo lo que se crea en public;
-- se quitan aquí para que cada tabla o función nueva arranque cerrada.
alter default privileges for role postgres in schema public revoke all on tables from anon;
alter default privileges for role postgres in schema public revoke all on sequences from anon;
alter default privileges for role postgres in schema public revoke all on functions from anon;

-- Postgres deja que cualquiera (public) ejecute toda función nueva.
-- Aquí cada función otorga su permiso de forma explícita.
alter default privileges for role postgres revoke execute on functions from public;

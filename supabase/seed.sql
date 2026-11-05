-- Datos de la base local y de CI. Supabase lo aplica en `supabase db reset` y nunca
-- en `supabase db push` a la nube (docs/05 §12, docs/15 §3).

-- Secretos de Vault que usa private.despertar_funcion (docs/05 §10.1).
-- Son valores de prueba solo para local y CI: no son llaves reales.
-- En la nube se crean una vez por SQL con los valores reales (docs/16 §3.2).
select vault.create_secret('http://host.docker.internal:54321/functions/v1', 'url_funciones');
select vault.create_secret('solo-local-no-es-secreto', 'secreto_interno');

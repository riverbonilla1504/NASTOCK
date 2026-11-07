-- HU-029 · Trabajos `cierre_diario` y `limpieza` de pg_cron.
-- Fuentes: docs/05 §7 (tabla de trabajos) y TT-03 (private.despertar_funcion, pg_cron y pg_net).
--
-- cierre_diario: cada 10 minutos pregunta a SQL si le toca (ya cerró el mercado hoy y falta la
-- barra de algún símbolo) y solo entonces despierta a la función. Un día sin sesión no despierta
-- nada (CA-4); con las barras de hoy ya guardadas, tampoco (CA-2).
-- limpieza: diario a las 08:00 UTC, siempre; SQL puro.
-- cron.schedule con un nombre existente reemplaza el trabajo: repetir la migración no duplica.

select cron.schedule(
  'cierre_diario',
  '*/10 * * * *',
  $$select private.despertar_funcion('cierre-diario') where private.cierre_diario_pendiente()$$
);

select cron.schedule(
  'limpieza',
  '0 8 * * *',
  $$select private.limpiar_barras_minuto()$$
);

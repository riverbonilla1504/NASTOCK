-- HU-027 · Trabajo diario `calendario` de pg_cron.
-- Fuentes: docs/05 §7 (tabla de trabajos: `calendario`, diario 10:00 UTC, siempre, HTTP →
-- calendario-mercado) y TT-03 (private.despertar_funcion, pg_cron y pg_net).
--
-- 10:00 UTC son las 5:00 en Bogotá y las 5:00 o 6:00 en Nueva York: horas antes de la apertura,
-- con el horario de verano de EE. UU. o sin él. pg_cron trabaja en UTC y esta hora no cambia.
-- cron.schedule con un nombre existente reemplaza el trabajo, así que repetir la migración no
-- crea un segundo.

select cron.schedule(
  'calendario',
  '0 10 * * *',
  $$select private.despertar_funcion('calendario-mercado')$$
);

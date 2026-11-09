-- HU-015 · Trabajo `conciliacion` de pg_cron, cada minuto.
-- Fuentes: docs/05 §7 (la conciliación corre cada `conciliacion.minutos_entre` en horario de mercado) y
-- TT-03 (private.despertar_funcion). La condición vive en private.conciliacion_pendiente(), que además
-- deja correr la conciliación fuera de horario mientras haya un aporte registrado esperando.
--
-- cron.schedule con un nombre existente reemplaza el trabajo, así que repetir la migración no crea
-- un segundo.

select cron.schedule(
  'conciliacion',
  '* * * * *',
  $$select private.despertar_funcion('conciliacion') where private.conciliacion_pendiente()$$
);

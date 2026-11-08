-- HU-028 · Trabajo `ingesta_mercado` de pg_cron, cada 15 segundos.
-- Fuentes: docs/05 §7 (la ingesta corre siempre y pregunta a SQL si le toca: mercado abierto o hasta
-- 10 minutos antes de abrir) y TT-03 (private.despertar_funcion). Fuera de ese horario no se llama
-- al proveedor ni a la función (FR-068).
--
-- cron.schedule con un nombre existente reemplaza el trabajo, así que repetir la migración no crea
-- un segundo.

select cron.schedule(
  'ingesta_mercado',
  '15 seconds',
  $$select private.despertar_funcion('ingesta-mercado') where private.mercado_en_ventana(interval '10 minutes')$$
);

# Tareas: HU-028 · Ingesta de precios cada 15 segundos

Desde la sección "Tareas" de la historia (`backlog/E-04-datos-de-mercado/HU-028-*.md`).

- [x] T001 Migración: tabla `cotizaciones` con RLS de lectura (CA-1) — `*_cotizaciones.sql`
- [x] T002 Migración: `private.publicar_cotizaciones(datos)`: guarda cotizaciones y barras de minuto y emite el evento `cotizaciones` (CA-1, CA-2) — `*_publicar_cotizaciones.sql`
- [x] T003 Migración: `estado_mercado()` llena `datos_actualizados_en` (CA-4) — `*_frescura_en_estado_mercado.sql`
- [x] T004 Migración: trabajo `ingesta_mercado` de `pg_cron`, cada 15 s, condicionado a `mercado_en_ventana(10 min)` (CA-1, CA-3) — `*_trabajo_ingesta_mercado.sql`
- [x] T005 pgTAP de `publicar_cotizaciones`, RLS, frescura y trabajo — `09_ingesta_de_precios_test.sql`
- [x] T006 Proveedor de mercado: `barraMinuto` en `Cotizacion` (real y simulado) con pruebas
- [x] T007 Función `ingesta-mercado`: secreto interno (CA-5), `snapshots`, validación con zod (CA-2), llamada a `publicar_cotizaciones` — `manejador.ts`, `index.ts`
- [x] T008 `deno test` de `ingesta-mercado`: precio inválido, fallo del proveedor, mercado cerrado, sin secreto
- [x] T009 Escenario E2E-03 de backend — `01_mercado_en_vivo_test.ts`
- [x] T010 `docs/17` actualizado
- [x] T011 `scripts/verificar.sh` completo en verde

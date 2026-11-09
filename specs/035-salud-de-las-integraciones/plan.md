# Plan: HU-035 · Salud de las integraciones

**Rama**: `035-salud-de-las-integraciones` (apilada sobre HU-034) · **Módulo**: M-18 · **Fuentes**: `docs/06` §5.6, `docs/08` §6, `docs/09` §3, `docs/11` §4.1, CB-64, RR-21.

- Migración `20261110110000_salud_de_las_integraciones.sql`: tipo `estado_integracion`, tabla `salud_integraciones` con sus seis filas, RLS (Analista y Administrador), `private.registrar_salud(integracion, ok, error)` (1–2 fallos → `degradado`, 3 o más → `caido`, un éxito → `ok`; audita `integracion.caida` e `integracion.recuperada`) y trigger que publica `salud` en el canal `supervision`.
- `_shared/salud.ts` (`registrarSalud`, que nunca lanza) usado por `ingesta-mercado` (`alpaca_datos`), `conciliacion` y `calendario-mercado` (`alpaca_trading`; la historia de barras, `alpaca_datos`).
- **Pendiente por HU-085** (no existe la tabla `alertas`): la alerta a Administradores y Analistas al pasar a `caido`. Hoy: auditoría, evento y un WARNING en el registro de Postgres.
- `conciliacion` ahora abre la base también cuando el broker falla, solo para anotar el fallo (no concilia).

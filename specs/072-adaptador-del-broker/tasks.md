# Tareas: HU-072 · Adaptador del broker para órdenes

- [X] T001 Interfaz: operaciones de órdenes, tipos, `validarOrden`, errores
- [X] T002 `alpaca.ts`: `enviarOrden`, `consultarOrden`, `cancelarOrden`, `posiciones` con zod
- [X] T003 `simulado_ordenes.ts` y `simulado.ts`: llenado, patas del bracket y escenarios forzables
- [X] T004 `mod.ts`: `crearBroker(leer, escenario)` y reexportaciones
- [X] T005 Pruebas `deno test` del adaptador real (fixtures `orden_*.json`, `posiciones.json`, `error_*.json`) y del simulado
- [ ] T006 Registro de la salud de `alpaca_trading` con `_shared/salud.ts`: pendiente, depende de HU-035 (otra rama)
- [X] T007 `docs/17` actualizado (M-10)
- [X] T008 `deno test`, `deno lint` y `deno fmt` en verde; `scripts/verificar.sh` completo no corrido (decisión de Javier: pruebas mínimas)

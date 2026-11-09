# Plan: HU-072 · Adaptador del broker para órdenes

**Rama**: `072-adaptador-del-broker` · **Módulos**: M-10, M-19 · **Fuentes**: `docs/10` §1, §5, §6, §9, §10 · `docs/05` §4, §6.

- **Interfaz** (`_shared/broker/interfaz.ts`): `enviarOrden`, `consultarOrden` (por `idBroker` o `idCliente`), `cancelarOrden` (`cancelada` / `ya_cerrada` / `no_existe`) y `posiciones`; tipos `OrdenAEnviar`, `OrdenDelBroker`, `PataDeOrden`; `validarOrden` (alcance D-63), `OrdenInvalida`, `OrdenRechazada` (403 fondos, 422 parámetros) y `envioIncierto` (sin respuesta o 5xx → consultar por `idCliente` antes de reintentar).
- **Alpaca** (`alpaca.ts`): `POST /v2/orders` (compra: `bracket`, `limit`, `gtc`; venta: `simple`, `limit`, `day`), `GET /v2/orders/{id}?nested=true`, `GET /v2/orders:by_client_order_id`, `DELETE /v2/orders/{id}`, `GET /v2/positions`. Respuestas validadas con zod; estado desconocido = error. `#pedir` pasa a devolver estado y cuerpo y acepta estados esperados (404, 422, 403).
- **Simulado** (`simulado.ts` + `simulado_ordenes.ts`): órdenes en memoria; `avanzar(precios)` llena con el siguiente precio (nunca peor que el límite) y cruza las patas (OCO) desde el paso siguiente al llenado; escenarios `llenado_parcial`, `rechazo`, `sin_respuesta`, `halt`. `crearBroker(leer, escenario)` recibe el escenario que la función lee de `pruebas.escenarios`.
- **Sin migraciones ni RPC**: la historia solo toca `_shared/broker/`.

Decisiones sin regla explícita en `docs/`:
- Las compras de `cantidad` ≥ 2 en `llenado_parcial` llenan `floor(cantidad/2)`; con 1 acción se llenan completas.
- Un `idCliente` repetido o un activo no negociable se rechazan en el simulado como 422 (`parametros_invalidos`), igual que Alpaca.

Pruebas: `deno test _shared/broker` (`alpaca_ordenes_test.ts` 11, `simulado_ordenes_test.ts` 13, `mod_test.ts` +1).

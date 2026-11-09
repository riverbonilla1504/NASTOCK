# Especificación de funcionalidad (Feature Specification): HU-073 · Enviar al broker las órdenes aprobadas

**Feature Branch**: `073-enviar-ordenes-al-broker`

**Created**: 2026-11-10

**Status**: Implementada (pendiente de revisión)

**Input**: Historia de usuario: "HU-073 · Enviar al broker las órdenes aprobadas", en [`backlog/E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md`](../../backlog/E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md)

> **MVP corto** (D-62, D-63, D-65, [`docs/14` §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)): solo acciones enteras (`bracket`); sin notificación `orden_fallida`; sin sugerencias, así que solo se envían órdenes manuales (HU-075). La historia absorbe de HU-062 la migración de `ordenes`, `ordenes_eventos` y la cola, sin llave foránea a `sugerencias` ni `opiniones_ia`. Los efectos sobre la sugerencia (`en_ejecucion`, `fallida`) no aplican.

## Escenarios de usuario y pruebas

### Historia de usuario 1 - Enviar al broker las órdenes aprobadas (Prioridad: P1)

**Como** Usuario, **quiero** que la orden que aprobé llegue al broker en segundos, una sola vez y nunca a un precio peor que el aprobado, **para** que lo que se ejecuta sea exactamente lo que decidí.

**Prueba independiente**: pgTAP de las funciones de la base (`19_ordenes_y_envio_test.sql`) y `deno test` de `ejecutor-ordenes` con el broker simulado. El E2E-08 completo nace con HU-075 (la orden manual).

**Escenarios de aceptación**:

1. **CA-1** · Una orden creada y encolada se toma, se revalida (banda, mercado, políticas, interruptor y salud), se envía con `client_order_id` igual a su id y queda `aceptada`. *(La sugerencia no existe en el MVP, D-65.)*
2. **CA-2** · La compra de acciones enteras es un bracket límite `gtc` con stop-loss y take-profit. *(La compra fraccional no existe, D-63.)*
3. **CA-3** (CB-33) · Un envío sin respuesta deja la orden `desconocida`; se consulta por `client_order_id`: si existe, sigue; si no, pasa a `error_envio`. Nunca se duplica.
4. **CA-4** · Una revalidación que falla (mercado cerrado, banda, salud, interruptor) deja la orden en `error_envio` con su motivo y libera la retención.
5. **CA-5** (CB-36) · El rechazo del broker por fondos deja la orden `rechazada`, libera la retención y audita el posible descuadre.
6. **CA-6** (CB-68) · Un mensaje de la cola que falla 5 veces se archiva y la orden queda en `error_envio`.
7. **CA-7** (permiso) · Una llamada a `ejecutor-ordenes` sin el secreto interno se rechaza.

### Casos borde

CB-33, CB-36, CB-67 y CB-68 (ver arriba). CB-67 (una función supera su tiempo máximo): la cola reaparece el mensaje a los 60 s y la siguiente pasada consulta al broker antes de reenviar.

## Requisitos

- **FR-160** Envío de órdenes desde una cola · **FR-161** Envío idempotente · **FR-162** Tipos de orden · **FR-163** Tratamiento de los errores del broker · **FR-164** Reintentos de la cola de órdenes (catálogo de `backlog/requisitos-funcionales/`, sin renumerar).

### Entidades clave

- **Orden** (`ordenes`) y su historia (`ordenes_eventos`), con estados de `docs/08` §2; **cola** `ordenes_por_enviar` (pgmq).

## Criterios de éxito

- **SC-001**: la misma orden nunca se envía dos veces al broker, aunque el ejecutor corra dos veces o el envío quede en duda.
- **SC-002**: una orden que no pasa la revalidación no llega al broker y libera lo que retenía.
- **SC-003**: ninguna respuesta del broker guardada en `ordenes_eventos` contiene llaves.

## Supuestos

- Supuestos de `docs/01` §5 aplicables: Alpaca paper no llena fuera de horario; las pruebas usan el simulado.
- La orden la crea `crear_orden_manual` (HU-075), que **retiene** el monto (RN-23, campo `retencion`) y guarda en `parametros` el `precio_referencia` de la compra; sin él la banda (RR-12) falla. La revalidación usa `private.validar_operacion` (HU-037) descontando la retención de la propia orden para no contarla dos veces (RR-03).
- El estado de las órdenes del broker **simulado** vive en la memoria de cada invocación de la función. Que sobreviva entre invocaciones (para ver llenados en demostraciones) es asunto de HU-074.
- Q-12 sigue abierta (llenado parcial de un bracket): no se toca aquí.
- La alerta al Administrador (CB-36, CB-68) es de HU-085, que crea `alertas`; hoy deja auditoría y un aviso en el registro de Postgres, igual que la salud de HU-035.
- El estado `enviada` sin `broker_order_id` tras una falla (429, caída del ejecutor) se resuelve consultando al broker por `client_order_id` y, si no está, reenviando: es seguro porque el `client_order_id` es único en Alpaca. Esa segunda vez no vuelve a revalidar.
- Depende de #95 (HU-072) y de HU-034, HU-035 y HU-037, que ya existen en sus ramas; hacer merge después de ellas.

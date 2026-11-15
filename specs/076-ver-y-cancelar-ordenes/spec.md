# Especificación: HU-076 · Ver mis órdenes y cancelar una que no se ha llenado

**Feature Branch**: `076-ver-y-cancelar-ordenes` · **Created**: 2026-11-15 · **Status**: En implementación.

**Input**: Issue #99 y `backlog/E-08-ejecucion-y-broker/HU-076-ver-mis-ordenes-y-cancelar-una-que-no-se-ha-llenado.md`.

## Escenarios de usuario y pruebas

### US1 · Ver y cancelar mis órdenes (P1)

Como Usuario quiero ver mis órdenes y cancelar las que siguen vivas para poder cambiar de idea antes de que terminen. Prueba independiente: orden propia visible, solicitud, confirmación del broker y conservación de llenados/retención coherente.

1. **CA-1** Dado un Usuario, cuando abre sus órdenes, entonces ve cada una con su estado (enviada, aceptada, llenada, cancelada y los demás) actualizado en vivo.
2. **CA-2** Dada una orden propia aceptada y sin llenar, cuando la cancela, entonces se pide la cancelación al broker, la orden queda `cancelada`, se libera la retención y se registra `orden.cancelada`.
3. **CA-3** (caso borde) CB-37: Dada una orden que se llena justo cuando la cancela, cuando llega la cancelación, entonces falla porque ya se llenó, se trata como llenada y se informa.
4. **CA-4** Dada una orden parcialmente llenada, cuando la cancela, entonces se cancela el resto y lo llenado se conserva.
5. **CA-5** (permiso) Dado un Usuario, cuando intenta cancelar una orden de otro cupo, entonces recibe `NO_AUTORIZADO`.

## Requisitos

- **FR-171**: cancelación de una orden propia según PM-13 y estados de docs/08 §2. La solicitud se envía mediante `sincronizar-ordenes`, conforme a la precisión aprobada de docs/10 §7 (historial 3.30).
- Entidades: orden, solicitud de cancelación, cupo, retención, posición y auditoría existentes. No agregar otro motor de llenados.

## Criterios de éxito

- SC-001: solo el dueño puede solicitar la cancelación.
- SC-002: solicitar no libera fondos antes de confirmar un estado terminal.
- SC-003: los llenados parciales o ganadores de la carrera se conservan y la pantalla informa el resultado real.

## Supuestos

S2 Flutter, S3 USD, S4 decenas de usuarios y S6 plan gratuito (docs/01 §5). Depende de HU-075 y HU-074 ya integradas. Q-12 sobre patas de bracket mantiene su política documentada; esta historia no cambia las protecciones de HU-077. La precisión pendiente del backlog se aprobó antes de implementar. No incluye dinero real ni nuevas pestañas principales.

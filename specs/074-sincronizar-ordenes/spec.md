# Especificación de funcionalidad (Feature Specification): HU-074 · Sincronizar órdenes y aplicar llenados

**Feature Branch**: `074-sincronizar-ordenes`

**Created**: 2026-11-14

**Status**: Implementada (#191; especificación escrita después de construir)

**Input**: Historia de usuario: "HU-074 · Sincronizar órdenes y aplicar llenados", en [`backlog/E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md`](../../backlog/E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Sincronizar órdenes y aplicar llenados (Prioridad: P1)

**Como** Usuario, **quiero** que cada llenado de mi orden se refleje en mi cupo y en mi posición sin que yo haga nada, **para** ver lo que realmente compré o vendí y a qué precio.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R4 · Decidir y operar en paper. Cambios del MVP corto ([docs/14 §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)): - Las protecciones son siempre nativas (D-63). El tipo `tipo_proteccion` se crea con todos sus valores, pero solo se usa `nativa`. - No aplican las notificaciones `orden_ejecutada` y `orden_fallida` (D-62). Los eventos `orden`, `posicion` y `cupo` sí se emiten. - **Sin sugerencias (D-65):** las órdenes son manuales y no tienen sugerencia. Lo que CA-1, CA-4 y CA-5 dicen de la sugerencia no aplica; lo demás sí. - E2E-08 lo crea HU-075 en el MVP corto, así que esta historia depende de HU-075 para extenderlo. Habilita HU-023 · Reparto de la ganancia realizada y absorción de pérdidas, HU-053 · Señales de venta de posiciones abiertas, HU-056 · Evaluación de sugerencias y candidatas tras el cierre, HU-067 · Invalidación por precio y por cambio de situación, HU-069 · Solicitar la liquidación de un cupo, HU-076 · Ver mis órdenes y cancelar una que no se ha llenado, HU-077 · Protección nativa en compras de acciones enteras, HU-078 · Protección virtual en compras fraccionales, HU-080 · Conciliación completa con pausa automática, HU-091 · Ver mis posiciones y sus protecciones, HU-092 · Ver el detalle del fondo, HU-093 · Ver el historial de operaciones.

**Prueba independiente (Independent Test)**: E2E-08 (actualizado)

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una compra aceptada que el broker llena por 1 acción a 110,20, **cuando** corre la sincronización, **entonces** el libro registra efectivo −110,20 e invertido +110,20, se crea la posición con costo promedio 110,20, se libera la retención y la sugerencia pasa a `ejecutada`.
2. **CA-2** · **Dado** el mismo llenado informado dos veces, **cuando** se aplica otra vez, **entonces** no cambia nada.
3. **CA-3** · **Dada** una posición de 6 acciones a 50,00, **cuando** se llenan 4 más a 60,00, **entonces** queda en 10 acciones con costo promedio 54,00; una venta no cambia el costo promedio de lo que queda.
4. **CA-4** (caso borde CB-35) · **Dada** una compra que no se llena en `ejecucion.minutos_max_llenado` minutos, **cuando** se cumple el tiempo, **entonces** se cancela, la sugerencia queda `fallida` y se libera la retención.
5. **CA-5** (caso borde CB-34) · **Dado** un llenado parcial y luego la cancelación o el vencimiento, **cuando** termina la orden, **entonces** la sugerencia queda `ejecutada_parcial`, el libro y la posición reflejan lo llenado y se libera el resto de la retención.
6. **CA-6** (caso borde CB-38) · **Dado** el cierre del mercado con una orden `day` viva, **cuando** el broker la vence, **entonces** queda `vencida` y lo llenado se conserva.

---

### Casos borde (Edge Cases)

- **CB-34** · Llenado parcial y luego vence o se cancela. Sugerencia `ejecutada_parcial`; libro y posición por lo llenado; retención restante liberada; protección sobre lo llenado (virtual si era bracket). (`docs/12` §4; fuente: 10 §6, Q-12). Lo comprueba CA-5.
- **CB-35** · La compra límite no se llena porque el precio se escapó. Se cancela al cumplir el tiempo máximo → `fallida`; retención liberada; aviso. (`docs/12` §4; fuente: 10 §5). Lo comprueba CA-4.
- **CB-38** · Cierra el mercado con una orden `day` viva. `vencida`; lo llenado se conserva. (`docs/12` §4; fuente: 08 §2). Lo comprueba CA-6.
- **CB-39** · El activo entra en halt con una orden viva. No se llena; se cancela por tiempo máximo; alerta. (`docs/12` §4; fuente: 10 §10).

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-165**: Mientras haya órdenes vivas, el sistema debe consultar cada 10 segundos su estado en el broker, traducirlo a los estados propios y guardar el estado crudo y cada evento. *(Sincronización de órdenes · actores: Sistema y Broker (Alpaca paper) · fuente: 10 §7 · 08 §2.1)*
- **FR-166**: El sistema debe aplicar cada llenado por diferencia contra lo ya aplicado, de forma idempotente: libro, posición con costo promedio ponderado, liberación de la retención y activación de la protección. *(Aplicación de llenados · actores: Sistema · fuente: 08 §2.2 · 02 §6.2 · RN-25 · RN-06)*
- **FR-167**: El sistema debe cancelar una compra aceptada o parcialmente llenada que supere `ejecucion.minutos_max_llenado` minutos, conservar lo llenado y liberar el resto de la retención. *(Tiempo máximo de llenado · actores: Sistema · fuente: 08 §2.2 · CB-35 · CB-39)*
- **FR-168**: Al terminar una orden, el sistema debe dejar su sugerencia en ejecutada, ejecutada parcial o fallida según lo llenado y liberar la retención que quede. *(Cierre de la orden y de su sugerencia · actores: Sistema · fuente: 08 §2.2 · CB-34 · CB-38)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

- **Posición** (`posiciones`): cantidad, costo promedio, costo total, resultado realizado y estado, una abierta por subcuenta y símbolo (docs/06 §5.4).
- **Protección** (`protecciones`): stop y objetivo de una posición; se crea vacía y la llena HU-077 (D-63: siempre nativa).
- **Orden** (`ordenes`): estado (`aceptada`, `parcialmente_llenada`, `llenada`, `cancelada`, `vencida`…) y lo llenado.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El libro registra efectivo −110,20 e invertido +110,20, se crea la posición con costo promedio 110,20, se libera la retención y la sugerencia pasa a `ejecutada` (CA-1).
- **SC-002**: No cambia nada (CA-2).
- **SC-003**: Queda en 10 acciones con costo promedio 54,00; una venta no cambia el costo promedio de lo que queda (CA-3).
- **SC-004**: Se cancela, la sugerencia queda `fallida` y se libera la retención (CA-4).
- **SC-005**: La sugerencia queda `ejecutada_parcial`, el libro y la posición reflejan lo llenado y se libera el resto de la retención (CA-5).
- **SC-006**: Queda `vencida` y lo llenado se conserva (CA-6).

## Supuestos (Assumptions)

- Depende de HU-073 · Enviar al broker las órdenes aprobadas: Sincroniza las órdenes que envía el ejecutor.
- Depende de HU-075 · Crear una orden manual en mi cupo: En el MVP corto, E2E-08 empieza con la orden manual (D-65).
- Sin sugerencias (D-65): donde los CA dicen "la sugerencia queda `fallida` o `ejecutada_parcial`", en el MVP es la orden manual la que queda cancelada, vencida o parcialmente llenada, con la retención liberada.
- Sin notificaciones `orden_ejecutada` ni `orden_fallida` (D-62): la pantalla muestra el estado en vivo.
- Las patas de protección llenadas (venta por stop u objetivo) son de HU-077, pendiente (`docs/18` §3).
- El broker simulado vive en la memoria de la función: entre invocaciones frías pierde sus órdenes.

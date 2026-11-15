# Especificación de funcionalidad (Feature Specification): HU-023 · Reparto de la ganancia realizada y absorción de pérdidas

**Feature Branch**: `023-reparto-de-la-ganancia`

**Created**: 2026-11-14

**Status**: Implementada (#192; especificación escrita después de construir)

**Input**: Historia de usuario: "HU-023 · Reparto de la ganancia realizada y absorción de pérdidas", en [`backlog/E-03-fondo-y-libro-contable/HU-023-reparto-de-la-ganancia-realizada-y-absorcion-de-perdidas.md`](../../backlog/E-03-fondo-y-libro-contable/HU-023-reparto-de-la-ganancia-realizada-y-absorcion-de-perdidas.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Reparto de la ganancia realizada y absorción de pérdidas (Prioridad: P1)

**Como** Usuario, **quiero** que la ganancia de cada venta de mi cupo se reparta sola 50/25/25 y que mi parte vuelva a mi cupo, **para** que el resultado de mis decisiones se refleje en mi cupo y en el fondo según las reglas de RiTech.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R4 · Decidir y operar en paper. Habilita HU-070 · Aprobar las ventas de liquidación, HU-093 · Ver el historial de operaciones.

**Prueba independiente (Independent Test)**: E2E-08 (actualizado)

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una venta en un cupo con costo 110,20 y recibido 123,20, **cuando** se aplica el llenado, **entonces** el cupo recibe 123,20, `resultados` registra −13,00 y el reparto mueve 6,50 a la Reserva y 3,25 a Arriesgadas, dejando 3,25 en el cupo.
2. **CA-2** · **Dada** una venta con ganancia en Arriesgadas, **cuando** se aplica el llenado, **entonces** el 25 % de Usuarios va a `usuarios_comun`.
3. **CA-3** · **Dada** una venta con pérdida (costo 110,20 y recibido 103,40), **cuando** se aplica el llenado, **entonces** la subcuenta absorbe los 6,80 completos y no hay reparto.
4. **CA-4** (caso borde CB-18) · **Dada** una ganancia de 0,03, **cuando** se reparte, **entonces** Arriesgadas recibe 0,00, el cupo 0,00 y la Reserva 0,03.
5. **CA-5** (caso borde CB-17) · **Dado** un cambio de porcentajes con una venta en curso, **cuando** la venta se llena, **entonces** el reparto usa los porcentajes vigentes al llenarse y los guarda en el movimiento.

---

### Casos borde (Edge Cases)

- **CB-17** · El admin cambia los porcentajes de reparto con ventas en curso. Cada reparto usa los porcentajes vigentes al llenarse la venta y los guarda en el movimiento. (`docs/12` §2; fuente: RN-08, RN-26). Lo comprueba CA-5.
- **CB-18** · Ganancia de centavos (0,03). Arriesgadas 0,00 · cupo 0,00 · Reserva 0,03 (truncamiento). (`docs/12` §2; fuente: RN-30). Lo comprueba CA-4.
- **CB-19** · Un cupo pierde 100 y luego gana 100. Se reparte la ganancia de 100 igual: el cupo termina con menos que al inicio. Es consecuencia del reparto por operación (pendiente de validar). (`docs/12` §2; fuente: RN-29, Q-01).

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-057**: Al aplicarse el llenado de una venta con ganancia, el sistema debe repartir la ganancia con los porcentajes vigentes en ese momento: 50 % a la Reserva, 25 % a Arriesgadas y 25 % al cupo que vendió, o a `usuarios_comun` si vendió Arriesgadas; las partes de 25 % se truncan a centavos y la Reserva recibe el resto. *(Reparto de la ganancia realizada · actores: Sistema · fuente: RN-26 · RN-29 · RN-30 · CB-17 · CB-18 · D-03 · D-04)*
- **FR-058**: En toda venta, el sistema debe devolver completo el costo de lo vendido a la subcuenta que vendió y, si hay pérdida, hacer que la absorba completa esa subcuenta, sin reparto ni compensación. *(Costo y pérdida de una venta · actores: Sistema · fuente: RN-27 · RN-28 · CB-19)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

- **Movimiento** `reparto_ganancia` del libro contable: asientos que suman cero, con los porcentajes vigentes guardados como en el aporte (`parametros.reparto.{pct_reserva, pct_arriesgadas, pct_usuarios}`) (docs/06 §4).
- **Subcuenta** `resultados`: técnica, recibe la ganancia o la pérdida realizada antes de repartirla.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El cupo recibe 123,20, `resultados` registra −13,00 y el reparto mueve 6,50 a la Reserva y 3,25 a Arriesgadas, dejando 3,25 en el cupo (CA-1).
- **SC-002**: El 25 % de Usuarios va a `usuarios_comun` (CA-2).
- **SC-003**: La subcuenta absorbe los 6,80 completos y no hay reparto (CA-3).
- **SC-004**: Arriesgadas recibe 0,00, el cupo 0,00 y la Reserva 0,03 (CA-4).
- **SC-005**: El reparto usa los porcentajes vigentes al llenarse y los guarda en el movimiento (CA-5).

## Supuestos (Assumptions)

- Depende de HU-074 · Sincronizar órdenes y aplicar llenados: El reparto ocurre dentro de `private.aplicar_llenado`.
- La rama de Arriesgadas (CA-2) está implementada y probada, aunque en el MVP no se dispara porque Arriesgadas no opera (D-64).
- Q-01 (reparto por operación o neto por periodo) sigue sin validar; CB-19 está probado tal como está documentado.
- El reparto visible en los tres bolsillos dentro de E-08 queda pendiente con HU-077 (`docs/18` §3).

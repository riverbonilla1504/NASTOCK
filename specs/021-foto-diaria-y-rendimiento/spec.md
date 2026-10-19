# Especificación de funcionalidad (Feature Specification): HU-021 · Foto diaria de patrimonio y rendimiento TWR

**Feature Branch**: `021-foto-diaria-y-rendimiento`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-021 · Foto diaria de patrimonio y rendimiento TWR", en [`backlog/E-03-fondo-y-libro-contable/HU-021-foto-diaria-de-patrimonio-y-rendimiento-twr.md`](../../backlog/E-03-fondo-y-libro-contable/HU-021-foto-diaria-de-patrimonio-y-rendimiento-twr.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Foto diaria de patrimonio y rendimiento TWR (Prioridad: P1)

**Como** Administrador, **quiero** que el sistema guarde cada día el patrimonio de cada subcuenta y calcule el rendimiento ponderado en el tiempo, **para** que los reportes oficiales no dependan de precios en vivo ni se distorsionen con aportes y repartos.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Media y pertenece a la entrega R2 · El fondo existe. Los reportes oficiales usan la foto diaria tomada tras el cierre, no los valores en vivo (RN-45). El rendimiento no es ganancia sobre capital inicial, porque con aportes, retiros y repartos esa cuenta engaña: se usa el rendimiento ponderado en el tiempo (RN-44). Habilita tres historias: HU-024 (usa el patrimonio por bolsillo tras el cierre), HU-094 (usa las fotos diarias y el TWR) y HU-096 (se genera en el cierre diario).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos que nombra la historia: foto con flujos, idempotencia y lectura por rol. No tiene escenario E2E propio. Entrega la historia diaria del patrimonio y un rendimiento que no se distorsiona con aportes ni repartos.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** el cierre del mercado, **cuando** corre `cierre-diario`, **entonces** `patrimonio_diario` tiene una fila por subcuenta con efectivo, valor de posiciones, patrimonio, flujos netos y rendimiento del día.
2. **CA-2** · **Dado** un día con una asignación de 400 a un cupo, **cuando** se calcula el rendimiento de ese cupo, **entonces** la asignación cuenta como flujo y no como ganancia.
3. **CA-3** · **Dado** que `cierre-diario` corre dos veces el mismo día, **cuando** termina, **entonces** no duplica la foto.
4. **CA-4** (aislamiento) · **Dado** un Usuario, **cuando** consulta `patrimonio_diario`, **entonces** ve las filas de su cupo y los agregados; un Analista o un Administrador ven todo.
5. **CA-5** · **Dadas** las fotos diarias de un periodo, **cuando** se calcula el rendimiento del fondo, de un bolsillo o de un cupo, **entonces** es el producto de (1 + rendimiento de cada día) menos 1.

---

### Casos borde (Edge Cases)

HU-021 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-054**: Tras cada cierre de mercado, el sistema debe guardar por subcuenta el efectivo, el valor de las posiciones, el patrimonio, los flujos netos y el rendimiento del día. *(Foto diaria de patrimonio · actores: Sistema · fuente: RN-45 · 02 §13 · 06 §5.6)*
- **FR-055**: El sistema debe calcular el rendimiento de fondo, bolsillo y cupo como rendimiento ponderado en el tiempo (TWR) sobre las fotos diarias, descontando aportes, retiros, asignaciones, repartos y rebalanceos. *(Rendimiento ponderado en el tiempo · actores: Sistema · fuente: RN-44 · 02 §13)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega una entidad, definida en `docs/06` §5.6:

- **Foto diaria de patrimonio**: el estado de una subcuenta al cierre de un día: efectivo, valor de las posiciones, patrimonio, flujos netos y rendimiento del día.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Después de cada cierre de mercado hay una foto por subcuenta.
- **SC-002**: Un aporte o una asignación de cupo no aparece como ganancia en el rendimiento.
- **SC-003**: El rendimiento de un periodo es el producto de (1 + rendimiento de cada día) menos 1, para el fondo, cada bolsillo y cada cupo.
- **SC-004**: Un Usuario ve las fotos de su cupo y los agregados; un Analista o un Administrador las ven todas.
- **SC-005**: Repetir el cierre el mismo día no duplica la foto.

## Supuestos (Assumptions)

- Depende de HU-013 · Libro contable de doble partida: la foto se toma de los saldos del libro.
- Depende de HU-029 · Barra diaria tras el cierre y retención de barras de minuto: reutiliza la función `cierre-diario` y su trabajo programado.
- Los flujos son aportes, retiros, asignaciones, repartos y rebalanceos (`docs/02` §13).
- Los valores en vivo son indicativos; los reportes oficiales usan la foto diaria (RN-45).

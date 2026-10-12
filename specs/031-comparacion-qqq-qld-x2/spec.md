# Especificación de funcionalidad (Feature Specification): HU-031 · Comparación de QQQ, QLD y ×2 teórico

**Feature Branch**: `031-comparacion-qqq-qld-x2`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-031 · Comparación de QQQ, QLD y ×2 teórico", en [`backlog/E-04-datos-de-mercado/HU-031-comparacion-de-qqq-qld-y-x2-teorico.md`](../../backlog/E-04-datos-de-mercado/HU-031-comparacion-de-qqq-qld-y-x2-teorico.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Comparación de QQQ, QLD y ×2 teórico (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** comparar en una gráfica QQQ, QLD real y la línea ×2 teórico, **para** entender por qué QLD no siempre rinde el doble del índice en un periodo.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Media y pertenece a la entrega R1 · Ver el mercado en vivo. La comparación de QQQ, QLD y ×2 teórico es parte de lo que los tres roles ven del mercado (PM-04). QLD es lo que se compra por defecto en el bolsillo de Usuarios (`docs/02` §1), y el riesgo de los ETFs apalancados se mitiga, entre otras cosas, explicándolo en la app (RSG-08). Habilita una historia: HU-094 (reutiliza la comparación con QQQ y ×2 teórico).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de pantalla de la gráfica y de la advertencia que nombra la historia. No tiene escenario E2E propio. Entrega la gráfica que explica por qué QLD no siempre rinde el doble del índice en un periodo.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** la pantalla de mercado, **cuando** la persona abre la comparación, **entonces** ve tres líneas: QQQ, QLD real y ×2 teórico.
2. **CA-2** · **Dado** un periodo elegido, **cuando** se dibuja ×2 teórico, **entonces** vale dos veces la variación acumulada de QQQ desde el inicio de ese periodo, calculada con barras diarias.
3. **CA-3** · **Dada** la comparación, **cuando** se muestra, **entonces** incluye la advertencia de que QLD duplica el movimiento de cada día y no el del periodo.

---

### Casos borde (Edge Cases)

HU-031 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-073**: La app debe mostrar en una misma gráfica las líneas de QQQ, de QLD real y de ×2 teórico. *(Comparación QQQ, QLD y ×2 teórico · actores: Usuario, Analista y Administrador · fuente: PM-04 · 02 §1)*
- **FR-074**: La app debe mostrar la advertencia de que QLD duplica el movimiento de cada día y no el del periodo. *(Advertencia sobre el ETF apalancado · actores: Usuario, Analista y Administrador · fuente: 02 §1 · RSG-08)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §5.2:

- **Barra diaria**: el resumen de un día de mercado de un símbolo. La gráfica usa las de QQQ y las de QLD.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: La comparación muestra tres líneas en una misma gráfica: QQQ, QLD real y ×2 teórico.
- **SC-002**: Para el periodo elegido, ×2 teórico vale dos veces la variación acumulada de QQQ desde el inicio de ese periodo.
- **SC-003**: La comparación incluye la advertencia de que QLD duplica el movimiento de cada día y no el del periodo.

## Supuestos (Assumptions)

- Depende de HU-030 · Pantalla de mercado en vivo: la comparación es parte de la pantalla de mercado.
- Depende de HU-029 · Barra diaria tras el cierre y retención de barras de minuto: usa las barras diarias de QQQ y de QLD.
- Depende de HU-115 · Motor ×2 teórico de la v2 con sus pruebas: usa el motor ×2 copiado de la v2.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

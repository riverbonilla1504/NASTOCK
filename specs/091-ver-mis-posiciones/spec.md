# Especificación de funcionalidad (Feature Specification): HU-091 · Ver mis posiciones y sus protecciones

**Feature Branch**: `091-ver-mis-posiciones`

**Created**: 2026-11-14

**Status**: Implementada (#194; especificación escrita después de construir)

**Input**: Historia de usuario: "HU-091 · Ver mis posiciones y sus protecciones", en [`backlog/E-10-cartera-y-reportes/HU-091-ver-mis-posiciones-y-sus-protecciones.md`](../../backlog/E-10-cartera-y-reportes/HU-091-ver-mis-posiciones-y-sus-protecciones.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Ver mis posiciones y sus protecciones (Prioridad: P1)

**Como** Usuario, **quiero** ver las posiciones de mi cupo con su valor, su resultado y su protección, **para** saber cómo va cada inversión y a qué precio se vendería sola.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R4 · Decidir y operar en paper. Solo acciones enteras (D-63, [docs/14 §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)): en CA-3 la protección es siempre nativa. Habilita HU-094 · Ver el rendimiento y compararlo con el NASDAQ-100.

**Prueba independiente (Independent Test)**: Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-08.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Usuario con una posición, **cuando** abre Mi cupo, **entonces** ve la cantidad, el costo promedio, el último precio, el valor, la ganancia no realizada y la antigüedad del precio.
2. **CA-2** · **Dado** un precio nuevo, **cuando** llega, **entonces** el valor y la ganancia no realizada de la posición cambian en pantalla.
3. **CA-3** · **Dada** la posición, **cuando** se muestra, **entonces** trae su protección: tipo (nativa o virtual), stop y objetivo en precio y estado.
4. **CA-4** (aislamiento) · **Dado** un Usuario, **cuando** consulta `posiciones_valoradas` o `protecciones`, **entonces** solo ve las de su cupo.

---

### Casos borde (Edge Cases)

Ninguno propio.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-198**: La app debe mostrar por cada posición del cupo la cantidad, el costo promedio, el último precio, el valor, la ganancia no realizada y la antigüedad del precio, actualizados con cada precio. *(Posiciones valoradas de mi cupo · actores: Usuario · fuente: PM-10 · 06 §6 · 02 §13 · RN-06)*
- **FR-199**: La app debe mostrar por cada posición su protección: tipo, stop y objetivo en precio y estado. *(Protecciones visibles · actores: Usuario y Analista · fuente: 08 §3 · 03 §4.3)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

- **Posición valorada**: la posición con el último precio, el valor y la ganancia no realizada; la app la lee de `mi_cupo` y la valora con las cotizaciones en vivo.
- **Protección** (`protecciones`): tipo, stop, objetivo y estado de la posición.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Ve la cantidad, el costo promedio, el último precio, el valor, la ganancia no realizada y la antigüedad del precio (CA-1).
- **SC-002**: El valor y la ganancia no realizada de la posición cambian en pantalla (CA-2).
- **SC-003**: Trae su protección: tipo (nativa o virtual), stop y objetivo en precio y estado (CA-3).
- **SC-004**: Solo ve las de su cupo (CA-4).

## Supuestos (Assumptions)

- Depende de HU-074 · Sincronizar órdenes y aplicar llenados: Muestra las posiciones que crean los llenados.
- Depende de HU-077 · Protección nativa en compras de acciones enteras: Muestra la protección de cada posición.
- Depende de HU-019 · Ver mi cupo: Extiende la pantalla Mi cupo.
- Las protecciones se muestran si existen; las crea HU-077, pendiente, así que hoy una posición nueva aparece sin protección.
- Pendientes (`docs/18` §3): la prueba pgTAP de `protecciones` y E2E-08, ambas con HU-077.

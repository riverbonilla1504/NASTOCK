# Especificación de funcionalidad (Feature Specification): HU-035 · Salud de las integraciones

**Feature Branch**: `035-salud-de-las-integraciones`

**Created**: 2026-11-14

**Status**: Implementada (especificación escrita después de construir)

**Input**: Historia de usuario: "HU-035 · Salud de las integraciones", en [`backlog/E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md`](../../backlog/E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Salud de las integraciones (Prioridad: P1)

**Como** Administrador, **quiero** saber en todo momento si cada integración está funcionando, **para** enterarme de una caída antes de que afecte una operación.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R3 · La IA analiza. Habilita HU-037 · Motor de políticas: reglas de la propuesta, HU-041 · Noticias de las candidatas, HU-045 · Adaptador de JEV y estado en etiquetas, HU-072 · Adaptador del broker para órdenes, HU-086 · Bandeja de notificaciones, HU-103 · Pantalla de salud e integraciones.

**Prueba independiente (Independent Test)**: Sin escenario propio en el catálogo de 15 §4.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una integración en `ok`, **cuando** falla una vez, **entonces** pasa a `degradado`; al tercer fallo seguido pasa a `caido`; y un éxito la devuelve a `ok` con los fallos seguidos en 0.
2. **CA-2** (caso borde CB-64) · **Dada** una integración que pasa a `caido`, **cuando** ocurre, **entonces** se crea una alerta para Administradores y Analistas y se registra `integracion.caida`; cuando se recupera, se registra `integracion.recuperada`.
3. **CA-3** · **Dado** un cambio de estado de una integración, **cuando** ocurre, **entonces** se publica el evento `salud` en el canal `supervision`.
4. **CA-4** (aislamiento) · **Dado** un Usuario, **cuando** consulta `salud_integraciones`, **entonces** no recibe filas; un Analista y un Administrador las ven todas.

---

### Casos borde (Edge Cases)

- **CB-64** · Alpaca caído. Salud `caido`; sin órdenes nuevas; protecciones nativas siguen en el broker; las virtuales no pueden ejecutarse (alerta). (`docs/12` §8; fuente: RR-21). Lo comprueba CA-2.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-081**: El sistema debe registrar cada éxito y cada fallo de cada integración y calcular su estado: `ok`, `degradado` con 1 o 2 fallos seguidos y `caido` con 3 o más; un éxito lo devuelve a `ok`. *(Salud de las integraciones · actores: Sistema · fuente: 06 §5.6 · 08 §6)*
- **FR-082**: Cuando una integración pasa a `caido`, el sistema debe alertar a Administradores y Analistas y registrar `integracion.caida`; cuando se recupera, debe registrar `integracion.recuperada`. *(Alerta por integración caída · actores: Sistema · fuente: 08 §6 · 07 §10 · 09 §5.1 · 11 §4.1 · CB-64)*
- **FR-083**: El sistema debe mostrar a Analistas y Administradores el estado de cada integración con su último éxito, su último fallo y su último error, y no debe mostrarlo a los Usuarios. *(Consulta de la salud · actores: Analista y Administrador · fuente: PM-34 · 03 §4.3)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

- **Salud de una integración** (`salud_integraciones`): estado (`ok`, `degradado`, `caido`), fallos seguidos y última hora de éxito y de error de cada proveedor (docs/06).

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Pasa a `degradado`; al tercer fallo seguido pasa a `caido`; y un éxito la devuelve a `ok` con los fallos seguidos en 0 (CA-1).
- **SC-002**: Se crea una alerta para Administradores y Analistas y se registra `integracion.caida`; cuando se recupera, se registra `integracion.recuperada` (CA-2).
- **SC-003**: Se publica el evento `salud` en el canal `supervision` (CA-3).
- **SC-004**: No recibe filas; un Analista y un Administrador las ven todas (CA-4).

## Supuestos (Assumptions)

- Depende de HU-028 · Ingesta de precios cada 15 segundos: La ingesta es la primera función que registra su salud.
- Depende de HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25: La función `conciliacion` también registra su salud.
- Depende de HU-085 · Alertas del sistema por audiencia: Crea la alerta de integración caída.
- Depende de HU-107 · Bitácora inmutable con cadena de hash: Registra `integracion.caida` e `integracion.recuperada`.
- La alerta al caer una integración (CA-2) espera a HU-085, que no está construida (ver `docs/18` §3).

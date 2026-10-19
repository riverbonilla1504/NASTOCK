# Especificación de funcionalidad (Feature Specification): HU-022 · Registrar ajustes contables

**Feature Branch**: `022-registrar-ajustes-contables`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-022 · Registrar ajustes contables", en [`backlog/E-03-fondo-y-libro-contable/HU-022-registrar-ajustes-contables.md`](../../backlog/E-03-fondo-y-libro-contable/HU-022-registrar-ajustes-contables.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Registrar ajustes contables (Prioridad: P1)

**Como** Administrador, **quiero** registrar un ajuste contable justificado, **para** corregir el libro sin editar nunca un asiento.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Baja y pertenece a la entrega R2 · El fondo existe. Registrar ajustes contables es un permiso exclusivo del Administrador, con justificación obligatoria (PM-45). Nadie modifica ni borra asientos: las correcciones son movimientos nuevos de ajuste (`docs/06` §4.1, L3). Habilita dos historias: HU-025 (es un ajuste justificado del Administrador) y HU-099 (registra ajustes).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos que nombra la historia: ajuste válido, sin suma cero, sin justificación y permisos. No tiene escenario E2E propio. Entrega la única forma de corregir el libro sin editar un asiento.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Administrador, **cuando** registra un ajuste con asientos que suman cero y una justificación, **entonces** se crea un movimiento `ajuste` y se registra `ajuste.registrado`.
2. **CA-2** · **Dado** un ajuste cuyos asientos no suman cero o que no trae justificación, **cuando** se intenta, **entonces** la función lo rechaza.
3. **CA-3** · **Dado** un ajuste que dejaría un saldo negativo, **cuando** se intenta, **entonces** la base de datos lo rechaza.
4. **CA-4** (permiso) · **Dado** un Usuario o un Analista, **cuando** llama `registrar_ajuste`, **entonces** recibe `NO_AUTORIZADO`.

---

### Casos borde (Edge Cases)

HU-022 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-056**: El sistema debe permitir al Administrador registrar un movimiento de ajuste con asientos que suman cero y una justificación obligatoria. *(Ajuste contable · actores: Administrador · fuente: PM-45 · 02 §14 · 06 §4.2)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §4:

- **Movimiento y asientos**: el ajuste es un movimiento del libro con asientos libres que suman cero y una justificación obligatoria.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Un Administrador corrige un saldo con un ajuste justificado, y el libro conserva los asientos originales.
- **SC-002**: No se registra un ajuste que no suma cero, que no trae justificación o que deja un saldo en negativo.
- **SC-003**: Un Usuario o un Analista no logra registrar un ajuste.
- **SC-004**: Cada ajuste queda en la bitácora.

## Supuestos (Assumptions)

- Depende de HU-013 · Libro contable de doble partida: el ajuste es un movimiento del libro.
- Depende de HU-107 · Bitácora inmutable con cadena de hash: registra `ajuste.registrado`.
- Es la única forma de corregir el libro (`docs/06` §4.1, L3).
- Los ajustes se registran en la pantalla Capital (`docs/03` §3); el formulario llega con HU-099.

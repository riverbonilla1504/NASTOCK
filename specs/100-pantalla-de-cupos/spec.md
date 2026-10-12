# Especificación de funcionalidad (Feature Specification): HU-100 · Pantalla de cupos

**Feature Branch**: `100-pantalla-de-cupos`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-100 · Pantalla de cupos", en [`backlog/E-11-administracion/HU-100-pantalla-de-cupos.md`](../../backlog/E-11-administracion/HU-100-pantalla-de-cupos.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Pantalla de cupos (Prioridad: P1)

**Como** Administrador, **quiero** ver la bolsa común y el cupo de cada empleado y asignar o reducir dinero, **para** repartir el bolsillo de Usuarios con la información a la vista.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Asignar y reducir cupos es un permiso exclusivo del Administrador (PM-42), con los límites de RN-16 y RN-17, y `docs/03` §3 lo ubica en la entrada Cupos. Habilita una historia: HU-069 (la acción vive en la pantalla de cupos).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de pantalla que nombra la historia: la lista, los formularios y los mensajes de error. No tiene escenario E2E propio; la ejercita E2E-04. Entrega al Administrador la pantalla para repartir el bolsillo de Usuarios con la información a la vista.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Administrador, **cuando** abre Cupos, **entonces** ve el disponible de `usuarios_comun` y cada cupo con su titular, su efectivo, su disponible y su patrimonio.
2. **CA-2** · **Dado** un cupo, **cuando** asigna o reduce un monto tras la confirmación, **entonces** los saldos se actualizan; si falla, ve el mensaje de `FONDOS_INSUFICIENTES`.
3. **CA-3** · **Dado** un cambio de saldos, **cuando** ocurre, **entonces** la pantalla se actualiza en vivo.
4. **CA-4** (permiso) · **Dado** un Usuario o un Analista, **cuando** abre esta pantalla, **entonces** el enrutador lo lleva a `/inicio`.

---

### Casos borde (Edge Cases)

HU-100 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-210**: La app debe mostrar el disponible de `usuarios_comun` y cada cupo con su efectivo, su disponible y su patrimonio, y permitir asignar y reducir cupos. *(Pantalla de cupos · actores: Administrador · fuente: 03 §3 · PM-42)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §4:

- **Subcuenta**: la pantalla muestra la bolsa común de Usuarios y el cupo de cada persona, con su efectivo, su disponible y su patrimonio.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El Administrador ve el disponible de la bolsa común y cada cupo con su titular, su efectivo, su disponible y su patrimonio.
- **SC-002**: Asigna o reduce un monto tras confirmar, y los saldos se actualizan; si no procede, ve el mensaje del error.
- **SC-003**: La pantalla se actualiza en vivo cuando cambian los saldos.
- **SC-004**: Un Usuario o un Analista no entra a esta pantalla.

## Supuestos (Assumptions)

- Depende de HU-097 · Sección de Administración y guía de primeros pasos: es una entrada de la sección de Administración.
- Depende de HU-018 · Asignar y reducir cupos: asigna y reduce cupos.
- Depende de HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles: confirma los movimientos de dinero.
- La acción de solicitar la liquidación de un cupo se agrega en HU-069.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

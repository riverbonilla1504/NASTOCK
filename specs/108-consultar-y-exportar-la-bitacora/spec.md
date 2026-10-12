# Especificación de funcionalidad (Feature Specification): HU-108 · Consultar y exportar la bitácora

**Feature Branch**: `108-consultar-y-exportar-la-bitacora`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-108 · Consultar y exportar la bitácora", en [`backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md`](../../backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Consultar y exportar la bitácora (Prioridad: P1)

**Como** Administrador, **quiero** consultar la bitácora con filtros y exportarla, **para** revisar lo que pasó y entregarlo cuando me lo pidan.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Solo el Administrador ve la bitácora (PM-60), con filtros por persona, acción, entidad y rango de fechas y exportación CSV (`docs/11` §4.4). Habilita una historia: HU-110 (usa la función que verifica la cadena).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-14, que esta historia agrega: las acciones sensibles quedan auditadas y la cadena de hash se verifica. Lo acompañan las pruebas de base de datos de la verificación y las de pantalla. Entrega al Administrador la forma de revisar lo que pasó y de entregarlo cuando se lo pidan.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Administrador, **cuando** abre Bitácora, **entonces** ve los registros con momento, actor, acción y entidad, y puede filtrarlos por persona, acción, entidad y rango de fechas.
2. **CA-2** · **Dado** un filtro aplicado, **cuando** exporta, **entonces** obtiene un CSV con esos registros.
3. **CA-3** · **Dadas** las acciones sensibles de la entrega (invitar, suspender, registrar y confirmar un aporte, asignar un cupo, cambiar un parámetro y encender un interruptor), **cuando** se ejecutan, **entonces** cada una aparece en la bitácora y la cadena de hash se verifica completa.
4. **CA-4** (permiso) · **Dado** un Usuario o un Analista, **cuando** abre la pantalla o consulta `auditoria`, **entonces** no tiene acceso.

---

### Casos borde (Edge Cases)

HU-108 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-221**: El sistema debe permitir solo al Administrador consultar la bitácora con filtros por persona, acción, entidad y rango de fechas, y exportarla en CSV. *(Consulta de la bitácora · actores: Administrador · fuente: PM-60 · 11 §4.4)*
- **FR-218**: El sistema debe registrar en la bitácora cada acción del catálogo (cuentas, capital, cupos, decisiones, operación, configuración y control) con actor, rol, acción, entidad, valores anterior y nuevo y origen, sin llaves ni tokens. *(Bitácora de acciones sensibles · actores: Sistema · fuente: 11 §4.1 · 01 §2 (P6) · 06 §5.6)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §5.6:

- **Registro de bitácora**: una acción sensible ya ocurrida, con su momento, su actor, su rol, la acción, la entidad afectada y los valores anterior y nuevo.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El Administrador encuentra cualquier acción sensible filtrando por persona, acción, entidad o rango de fechas.
- **SC-002**: Exporta a CSV exactamente los registros que filtró.
- **SC-003**: Las acciones sensibles de la entrega aparecen en la bitácora y su cadena se verifica completa.
- **SC-004**: Un Usuario o un Analista no accede a la bitácora.
- **SC-005**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-14.

## Supuestos (Assumptions)

- Depende de HU-107 · Bitácora inmutable con cadena de hash: consulta la tabla `auditoria`.
- Depende de HU-097 · Sección de Administración y guía de primeros pasos: es una entrada de la sección de Administración.
- Depende de HU-117 · Exportador de reportes de la v2 con sus pruebas: exporta con el exportador de la v2.
- Depende de HU-018 · Asignar y reducir cupos: el escenario audita aportes y cupos.
- Depende de HU-033 · Parámetros configurables con rango e historial: el escenario audita un cambio de parámetro.
- Depende de HU-034 · Encender y apagar los interruptores del fondo: el escenario audita un interruptor.
- Depende de HU-010 · Suspender y reactivar una cuenta: el escenario audita una suspensión.
- Depende de TT-06 · Arnés E2E de backend y de la app: agrega el escenario E2E-14.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

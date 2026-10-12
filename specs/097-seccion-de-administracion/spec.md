# Especificación de funcionalidad (Feature Specification): HU-097 · Sección de Administración y guía de primeros pasos

**Feature Branch**: `097-seccion-de-administracion`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-097 · Sección de Administración y guía de primeros pasos", en [`backlog/E-11-administracion/HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md`](../../backlog/E-11-administracion/HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Sección de Administración y guía de primeros pasos (Prioridad: P1)

**Como** Administrador, **quiero** tener una sección de Administración con todo lo que gobierno y una guía cuando el fondo aún no tiene capital, **para** encontrar cada tarea en un solo lugar y saber por dónde empezar.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. La sección de Administración es solo del Administrador, con las entradas de `docs/03` §3. Antes del primer aporte el fondo no opera (RN-11) y el Administrador ve la guía de primeros pasos (CB-80), que sigue el flujo del aporte de `docs/08` §7.6. Habilita nueve historias: HU-098 (es una entrada de la sección de Administración), HU-099 (es una entrada de la sección de Administración), HU-100 (es una entrada de la sección de Administración), HU-101 (son entradas de la sección de Administración), HU-102 (es una entrada de la sección de Administración), HU-103 (es una entrada de la sección de Administración), HU-105 (es una entrada de la sección de Administración), HU-106 (es una entrada de la sección de Administración) y HU-108 (es una entrada de la sección de Administración).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-01, que esta historia extiende: el Administrador ve Administración y los demás roles no. Lo acompañan las pruebas de pantalla del menú y de la guarda. Entrega al Administrador un solo lugar para todo lo que gobierna y una guía para empezar.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Administrador, **cuando** abre Administración, **entonces** ve las entradas Usuarios e invitaciones, Capital, Cupos, Rebalanceos, Parámetros, Lista blanca, Interruptores, Salud e integraciones, Bitácora y Prompts.
2. **CA-2** (caso borde CB-80) · **Dado** el fondo sin capital, **cuando** el Administrador entra, **entonces** ve la guía de primeros pasos: registrar el aporte, esperar su confirmación, asignar cupos y encender los interruptores.
3. **CA-3** · **Dado** el primer aporte confirmado, **cuando** el Administrador vuelve a entrar, **entonces** la guía ya no aparece.
4. **CA-4** (permiso) · **Dado** un Usuario o un Analista, **cuando** abre `/admin/...`, **entonces** el enrutador lo lleva a `/inicio`.

---

### Casos borde (Edge Cases)

- **CB-80** · Fondo sin capital (antes del primer aporte). Interruptores apagados; la app muestra "Fondo sin capital" y el admin ve la guía de primeros pasos (`docs/12` §9; fuente: RN-11). Lo comprueba CA-2.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-206**: La app debe ofrecer solo al Administrador una sección con Usuarios e invitaciones, Capital, Cupos, Rebalanceos, Parámetros, Lista blanca, Interruptores, Salud e integraciones, Bitácora y Prompts. *(Sección de Administración · actores: Administrador · fuente: 03 §3 · 05 §9.3)*
- **FR-207**: Mientras el fondo no tenga capital, la app debe mostrar al Administrador la guía de primeros pasos. *(Guía de primeros pasos · actores: Administrador · fuente: CB-80 · 08 §7.6)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Solo consulta si el fondo ya tiene capital (`docs/06` §4).

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El Administrador encuentra en una sola sección las diez entradas de `docs/03` §3.
- **SC-002**: Mientras el fondo no tiene capital, ve la guía con sus cuatro pasos: registrar el aporte, esperar su confirmación, asignar cupos y encender los interruptores.
- **SC-003**: Después del primer aporte confirmado, la guía ya no aparece.
- **SC-004**: Un Usuario o un Analista no entra a Administración.
- **SC-005**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-01.

## Supuestos (Assumptions)

- Depende de HU-006 · Navegación y guardas según el rol: cuelga de la navegación por rol.
- Cada entrada se habilita con la historia de su pantalla.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

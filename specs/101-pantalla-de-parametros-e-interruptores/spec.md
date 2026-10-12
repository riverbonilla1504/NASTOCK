# Especificación de funcionalidad (Feature Specification): HU-101 · Pantalla de parámetros e interruptores

**Feature Branch**: `101-pantalla-de-parametros-e-interruptores`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-101 · Pantalla de parámetros e interruptores", en [`backlog/E-11-administracion/HU-101-pantalla-de-parametros-e-interruptores.md`](../../backlog/E-11-administracion/HU-101-pantalla-de-parametros-e-interruptores.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Pantalla de parámetros e interruptores (Prioridad: P1)

**Como** Administrador, **quiero** ver y cambiar los parámetros y los interruptores del fondo, **para** ajustar las reglas y encender o pausar el sistema desde la app.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Media y pertenece a la entrega R2 · El fondo existe. Cambiar parámetros (PM-54), apagar la IA o el trading (PM-56) y volver a encenderlos (PM-57) se hacen desde las entradas Parámetros e Interruptores de `docs/03` §3. No habilita otras historias.

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de pantalla que nombra la historia: la edición, la suma de porcentajes y los interruptores. No tiene escenario E2E propio. Entrega al Administrador la pantalla para ajustar las reglas y encender o pausar el sistema.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Administrador, **cuando** abre Parámetros, **entonces** ve cada parámetro con su valor, su rango y su descripción, agrupados por tema.
2. **CA-2** · **Dado** un parámetro, **cuando** lo cambia con un motivo, **entonces** se guarda y aparece en su historial; un valor fuera de rango muestra el mensaje de `PARAMETRO_FUERA_DE_RANGO`.
3. **CA-3** · **Dados** los tres porcentajes de reparto, **cuando** los edita, **entonces** la pantalla los cambia juntos y no deja guardar si no suman 100.
4. **CA-4** · **Dado** un Administrador, **cuando** abre Interruptores, **entonces** ve el estado de `ia_activa` y de `trading_activo` con el motivo, el autor y la hora de la pausa, y puede encenderlos o apagarlos con confirmación.
5. **CA-5** (permiso) · **Dado** un Usuario o un Analista, **cuando** abre esta pantalla, **entonces** el enrutador lo lleva a `/inicio`.

---

### Casos borde (Edge Cases)

HU-101 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-211**: La app debe listar los parámetros con su valor, su rango y su descripción, permitir cambiarlos con un motivo y mostrar su historial. *(Pantalla de parámetros · actores: Administrador · fuente: 03 §3 · PM-54 · 02 §10)*
- **FR-212**: La app debe mostrar el estado de ambos interruptores con el motivo, el autor y la hora de la pausa, y permitir encenderlos y apagarlos. *(Pantalla de interruptores · actores: Administrador · fuente: 03 §3 · PM-56 · PM-57 · 06 §4)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa estas (`docs/06` §4 y §5.6):

- **Parámetro**: un valor configurable del sistema, con su clave, su valor, su rango y su descripción.
- **Historial de parámetros**: cada cambio de un parámetro, con su valor anterior, el nuevo, quién lo cambió, cuándo y el motivo.
- **Fondo**: guarda los dos interruptores (IA y trading) y, de la última pausa, el motivo, quién la hizo y cuándo.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El Administrador ve cada parámetro con su valor, su rango y su descripción.
- **SC-002**: Cambia un parámetro con un motivo y el cambio aparece en su historial; un valor fuera de rango muestra el mensaje del error.
- **SC-003**: Los tres porcentajes de reparto se editan juntos y no se guardan si no suman 100.
- **SC-004**: Ve el estado de los dos interruptores con el motivo, el autor y la hora de la pausa, y los enciende o los apaga con confirmación.
- **SC-005**: Un Usuario o un Analista no entra a esta pantalla.

## Supuestos (Assumptions)

- Depende de HU-097 · Sección de Administración y guía de primeros pasos: son entradas de la sección de Administración.
- Depende de HU-033 · Parámetros configurables con rango e historial: cambia los parámetros.
- Depende de HU-034 · Encender y apagar los interruptores del fondo: enciende y apaga los interruptores.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

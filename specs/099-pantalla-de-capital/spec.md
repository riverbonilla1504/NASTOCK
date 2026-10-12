# Especificación de funcionalidad (Feature Specification): HU-099 · Pantalla de capital

**Feature Branch**: `099-pantalla-de-capital`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-099 · Pantalla de capital", en [`backlog/E-11-administracion/HU-099-pantalla-de-capital.md`](../../backlog/E-11-administracion/HU-099-pantalla-de-capital.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Pantalla de capital (Prioridad: P1)

**Como** Administrador, **quiero** registrar aportes y retiros y ver su estado, **para** gobernar el capital del fondo desde la app.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Registrar y anular aportes, registrar retiros y registrar ajustes son permisos exclusivos del Administrador (PM-40, PM-41, PM-45), y `docs/03` §3 los reúne en la entrada Capital. Todo movimiento de dinero exige confirmación (`docs/04` §8). No habilita otras historias.

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de pantalla de los formularios y de los mensajes de error que nombra la historia. No tiene escenario E2E propio; la ejercita E2E-04. Entrega al Administrador la pantalla desde la que gobierna el capital del fondo.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Administrador, **cuando** abre Capital, **entonces** ve la lista de aportes y retiros con su monto, su referencia, su estado, quién lo registró y cuándo.
2. **CA-2** · **Dado** el formulario de aporte, **cuando** lo envía tras la confirmación, **entonces** el aporte aparece como registrado y pasa a confirmado sin recargar cuando la conciliación lo confirma.
3. **CA-3** · **Dado** un aporte registrado, **cuando** elige anularlo, **entonces** la app pide el motivo y lo anula; en un aporte confirmado esa opción no está.
4. **CA-4** · **Dado** el formulario de retiro, **cuando** elige la subcuenta de origen, **entonces** solo puede elegir Reserva, Arriesgadas o la bolsa común, y ve el disponible de cada una.
5. **CA-5** (permiso) · **Dado** un Analista, **cuando** consulta `movimientos_capital`, **entonces** los ve en solo lectura; un Usuario no recibe filas.
6. **CA-6** · **Dado** el formulario de ajuste, **cuando** lo envía con sus asientos y su justificación tras la confirmación, **entonces** el ajuste queda registrado.

---

### Casos borde (Edge Cases)

HU-099 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-209**: La app debe listar los aportes y retiros con su estado y permitir registrar un aporte, anular un aporte no confirmado y registrar un retiro. *(Pantalla de capital · actores: Administrador · fuente: 03 §3 · PM-40 · PM-41)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa dos (`docs/06` §4 y §4.3):

- **Movimiento de capital**: un aporte o un retiro. Atributos clave: monto, estado (registrado, confirmado o anulado), referencia, nota, quién lo registró y cuándo.
- **Subcuenta**: la pantalla muestra el disponible de la reserva, de arriesgadas y de la bolsa común al elegir el origen de un retiro.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El Administrador ve los aportes y los retiros con su monto, su referencia, su estado, quién los registró y cuándo.
- **SC-002**: Un aporte registrado pasa a confirmado en la pantalla sin recargar.
- **SC-003**: Un aporte confirmado no ofrece la opción de anular.
- **SC-004**: Un retiro solo puede salir de la Reserva, de Arriesgadas o de la bolsa común, y la pantalla muestra el disponible de cada una.
- **SC-005**: Un Analista ve los movimientos de capital en solo lectura; un Usuario no los ve.

## Supuestos (Assumptions)

- Depende de HU-097 · Sección de Administración y guía de primeros pasos: es una entrada de la sección de Administración.
- Depende de HU-014 · Registrar y anular aportes: registra y anula aportes.
- Depende de HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25: muestra la confirmación del aporte.
- Depende de HU-016 · Registrar retiros de capital: registra retiros.
- Depende de HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles: confirma los movimientos de dinero.
- Depende de HU-022 · Registrar ajustes contables: registra ajustes.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

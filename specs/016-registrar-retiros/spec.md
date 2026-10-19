# Especificación de funcionalidad (Feature Specification): HU-016 · Registrar retiros de capital

**Feature Branch**: `016-registrar-retiros`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-016 · Registrar retiros de capital", en [`backlog/E-03-fondo-y-libro-contable/HU-016-registrar-retiros-de-capital.md`](../../backlog/E-03-fondo-y-libro-contable/HU-016-registrar-retiros-de-capital.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Registrar retiros de capital (Prioridad: P1)

**Como** Administrador, **quiero** registrar un retiro de capital desde la Reserva o desde otro bolsillo, **para** sacar dinero del fondo dejando su rastro contable.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Media y pertenece a la entrega R2 · El fondo existe. Registrar retiros es un permiso exclusivo del Administrador (PM-41, RN-12). Por defecto el retiro sale de la Reserva, puede salir de otro bolsillo y nunca de un cupo (RN-13), y no puede superar el disponible de la subcuenta de origen (RN-14). Habilita una historia: HU-099 (registra retiros).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos que nombra la historia: retiro desde cada subcuenta permitida, desde un cupo, sin disponible y permisos. No tiene escenario E2E propio. Entrega la forma de sacar dinero del fondo dejando su rastro contable.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dados** un Administrador y la Reserva con 5.000 disponibles, **cuando** registra un retiro de 1.000 sin elegir subcuenta, **entonces** sale de la Reserva, queda confirmado al registrarse y el libro registra reserva −1.000 y externa +1.000.
2. **CA-2** (caso borde CB-13) · **Dado** un retiro mayor al disponible de la subcuenta de origen, **cuando** se registra, **entonces** responde `FONDOS_INSUFICIENTES`.
3. **CA-3** · **Dado** un retiro, **cuando** se indica un cupo como origen, **entonces** la función lo rechaza: primero se reduce el cupo.
4. **CA-4** · **Dado** un retiro registrado, **cuando** ocurre, **entonces** quedan en la bitácora `capital.retiro_registrado` y `capital.retiro_confirmado`.
5. **CA-5** (permiso) · **Dado** un Usuario o un Analista, **cuando** llama `registrar_retiro`, **entonces** recibe `NO_AUTORIZADO`.
6. **CA-6** · **Dado** un Administrador, **cuando** registra un retiro eligiendo `arriesgadas` o `usuarios_comun` como origen, **entonces** sale de esa subcuenta.

---

### Casos borde (Edge Cases)

- **CB-13** · Retiro mayor al disponible de la Reserva. `FONDOS_INSUFICIENTES`. El admin elige otra subcuenta o rebalancea primero (`docs/12` §2; fuente: RN-14). Lo comprueba CA-2.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-048**: El sistema debe permitir al Administrador registrar un retiro desde la Reserva o desde `arriesgadas` o `usuarios_comun`, nunca desde un cupo, por un monto que no supere el disponible de esa subcuenta; el retiro queda confirmado al registrarse. *(Registro de un retiro · actores: Administrador · fuente: PM-41 · RN-12 · RN-13 · RN-14 · CB-13 · 02 §4)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa dos (`docs/06` §4 y §4.3):

- **Movimiento de capital**: un aporte o un retiro. Atributos clave: monto, estado (registrado, confirmado o anulado), referencia, nota, quién lo registró y cuándo. Un retiro guarda su subcuenta de origen y nace confirmado.
- **Subcuenta**: el retiro baja el efectivo de la subcuenta de origen: la reserva, arriesgadas o la bolsa común de Usuarios.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Un retiro queda confirmado al registrarse y baja el saldo de la subcuenta de origen.
- **SC-002**: No se puede retirar más que el disponible de la subcuenta de origen.
- **SC-003**: No se puede retirar directamente desde un cupo.
- **SC-004**: Cada retiro queda en la bitácora.

## Supuestos (Assumptions)

- Depende de HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25: solo hay dinero que retirar después de un aporte confirmado.
- En paper trading un retiro es solo contable: la cuenta paper conserva el efectivo y la conciliación lo reporta como excedente no asignado (`docs/02` §4).
- Un retiro no se anula: se corrige con un aporte (`docs/08` §4).
- La pantalla está en HU-099.

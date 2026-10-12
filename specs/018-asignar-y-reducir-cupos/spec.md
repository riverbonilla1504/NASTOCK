# Especificación de funcionalidad (Feature Specification): HU-018 · Asignar y reducir cupos

**Feature Branch**: `018-asignar-y-reducir-cupos`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-018 · Asignar y reducir cupos", en [`backlog/E-03-fondo-y-libro-contable/HU-018-asignar-y-reducir-cupos.md`](../../backlog/E-03-fondo-y-libro-contable/HU-018-asignar-y-reducir-cupos.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Asignar y reducir cupos (Prioridad: P1)

**Como** Administrador, **quiero** asignar dinero de la bolsa común al cupo de un empleado y reducirlo, **para** repartir el 25 % de Usuarios entre los empleados.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Asignar y reducir cupos es un permiso exclusivo del Administrador (PM-42). Asignar mueve dinero de la bolsa común al cupo sin superar su disponible (RN-16), reducir lo devuelve solo hasta el disponible del cupo (RN-17), y un máximo opcional limita el cupo de una persona (RN-19). Habilita siete historias: HU-012 (mueve el efectivo del cupo a `usuarios_comun`), HU-019 (muestra el dinero que se asigna al cupo), HU-037 (RR-03 a RR-05 usan el disponible y el patrimonio de la subcuenta), HU-059 (calcula cada sugerencia con el disponible del cupo), HU-100 (asigna y reduce cupos), HU-108 (el escenario audita aportes y cupos) y HU-109 (prueba el aislamiento entre cupos).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-04, que esta historia extiende: asignación de un cupo después del reparto. Lo acompañan las pruebas de base de datos: asignar, reducir, límites y permisos. Entrega al Administrador la forma de repartir el bolsillo de Usuarios entre los empleados.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** `usuarios_comun` con 2.500 disponibles, **cuando** el Administrador asigna 400 a un Usuario, **entonces** el libro registra usuarios_comun −400 y cupo +400 y se registra `cupo.asignado`.
2. **CA-2** (caso borde CB-14) · **Dada** una asignación mayor al disponible de `usuarios_comun`, **cuando** se intenta, **entonces** responde `FONDOS_INSUFICIENTES`.
3. **CA-3** (caso borde CB-16) · **Dado** un cupo con casi todo invertido, **cuando** el Administrador lo reduce, **entonces** solo puede hacerlo hasta su disponible; por encima responde `FONDOS_INSUFICIENTES`.
4. **CA-4** · **Dado** `cupos.maximo_usd` configurado, **cuando** una asignación dejaría el cupo por encima de ese máximo, **entonces** responde `CUPO_SUPERA_MAXIMO`.
5. **CA-5** (permiso) · **Dado** un Usuario o un Analista, **cuando** llama `asignar_cupo` o `reducir_cupo`, **entonces** recibe `NO_AUTORIZADO`.
6. **CA-6** · **Dado** un cupo con disponible, **cuando** el Administrador lo reduce por un monto que no lo supera, **entonces** el dinero pasa del cupo a `usuarios_comun` y se registra `cupo.reducido`.

---

### Casos borde (Edge Cases)

- **CB-14** · Asignar un cupo mayor a lo que hay en la bolsa común. `FONDOS_INSUFICIENTES` (`docs/12` §2; fuente: RN-16). Lo comprueba CA-2.
- **CB-16** · Reducir el cupo de alguien que tiene casi todo invertido. Solo se puede reducir hasta su disponible (`docs/12` §2; fuente: RN-17). Lo comprueba CA-3.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-050**: El sistema debe permitir al Administrador mover dinero de `usuarios_comun` al cupo de un Usuario sin superar el disponible de `usuarios_comun` ni `cupos.maximo_usd`. *(Asignación de cupo · actores: Administrador · fuente: PM-42 · RN-16 · RN-19 · CB-14)*
- **FR-051**: El sistema debe permitir al Administrador mover dinero del cupo de un Usuario a `usuarios_comun` solo hasta el disponible de ese cupo, sin vender posiciones. *(Reducción de cupo · actores: Administrador · fuente: PM-42 · RN-17 · CB-16)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa dos, definidas en `docs/06` §4:

- **Subcuenta**: el dinero pasa entre la bolsa común de Usuarios y el cupo de una persona.
- **Movimiento y asientos**: cada asignación y cada reducción es un movimiento del libro.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Un Administrador asigna dinero y pasa de la bolsa común al cupo; lo reduce y vuelve a la bolsa común.
- **SC-002**: No se asigna más de lo disponible en la bolsa común ni por encima del máximo por persona.
- **SC-003**: No se reduce un cupo más allá de su disponible: nunca se venden posiciones para reducirlo.
- **SC-004**: Cada asignación y cada reducción quedan en la bitácora.
- **SC-005**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-04.

## Supuestos (Assumptions)

- Depende de HU-017 · Cupo al aceptar la invitación: los cupos nacen al aceptar la invitación.
- Depende de HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25: `usuarios_comun` recibe dinero con el aporte confirmado.
- Reducir un cupo no vende posiciones: para eso está la liquidación (HU-069).
- La pantalla está en HU-100.
- **Q-07** (`docs/13` §2, abierta): Monto real del fondo y cómo se reparten los cupos iniciales (¿iguales para todos?). Valor provisional: USD 10.000; cupos que defina el admin.

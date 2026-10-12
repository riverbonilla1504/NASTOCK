# Especificación de funcionalidad (Feature Specification): HU-017 · Cupo al aceptar la invitación

**Feature Branch**: `017-cupo-al-aceptar-la-invitacion`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-017 · Cupo al aceptar la invitación", en [`backlog/E-03-fondo-y-libro-contable/HU-017-cupo-al-aceptar-la-invitacion.md`](../../backlog/E-03-fondo-y-libro-contable/HU-017-cupo-al-aceptar-la-invitacion.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Cupo al aceptar la invitación (Prioridad: P1)

**Como** Usuario, **quiero** recibir mi cupo al aceptar la invitación, con el monto inicial que definió el Administrador si la bolsa común lo cubre, **para** tener dónde operar desde mi primer ingreso.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Al aceptar la invitación, el empleado recibe su cupo: en 0, o con el monto inicial que indicó el Administrador si la bolsa común lo cubre (RN-18). Cada empleado ve y opera solo su cupo (RN-20). Habilita dos historias: HU-011 (usa `private.crear_cupo` y el cierre del cupo) y HU-018 (los cupos nacen al aceptar la invitación).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos que nombra la historia: cupo con monto, cupo sin fondos suficientes, roles sin cupo y lectura solo del propio. No tiene escenario E2E propio; la ejercita E2E-04. Entrega a cada Usuario su cupo desde el primer ingreso.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dadas** una invitación de Usuario con cupo inicial de 400 y `usuarios_comun` con 2.500, **cuando** la persona ingresa por primera vez, **entonces** se crea su subcuenta de cupo y se le asignan 400 con un movimiento `asignacion_cupo`.
2. **CA-2** (caso borde CB-15) · **Dado** un cupo inicial que `usuarios_comun` no cubre, **cuando** la persona ingresa, **entonces** entra igual con el cupo en 0 y se crea la alerta `cupo_inicial_no_asignado` para el Administrador.
3. **CA-3** · **Dada** una invitación de Analista o de Administrador, **cuando** la persona ingresa, **entonces** no se crea ningún cupo.
4. **CA-4** · **Dados** los Usuarios que ingresaron antes de existir el libro, **cuando** se aplica la migración, **entonces** cada uno recibe su cupo en 0.
5. **CA-5** (aislamiento) · **Dado** un Usuario, **cuando** consulta `subcuentas`, **entonces** solo ve su cupo.

---

### Casos borde (Edge Cases)

- **CB-15** · Invitación con cupo inicial que la bolsa común no cubre. El empleado entra igual con cupo 0; alerta `cupo_inicial_no_asignado` al admin (`docs/12` §2; fuente: RN-18). Lo comprueba CA-2.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-049**: Cuando una persona con rol Usuario acepta su invitación, el sistema debe crear su cupo con el monto inicial indicado si `usuarios_comun` lo cubre; si no lo cubre, debe crearlo en 0 y generar la alerta `cupo_inicial_no_asignado`, sin impedir el ingreso. *(Cupo al aceptar la invitación · actores: Sistema · fuente: RN-18 · 04 §6 · CB-15)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa estas (`docs/06` §4, §5.1 y §5.5):

- **Subcuenta de cupo**: el dinero asignado a un Usuario. Nace cuando esa persona acepta su invitación.
- **Invitación**: trae el cupo inicial que el Administrador quiso darle a la persona.
- **Alerta**: avisa al Administrador cuando el cupo inicial no se pudo asignar.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Un Usuario invitado con cupo inicial lo recibe en su primer ingreso, si la bolsa común lo cubre.
- **SC-002**: Si la bolsa común no lo cubre, la persona entra igual con el cupo en 0 y el Administrador recibe una alerta.
- **SC-003**: Un Analista o un Administrador no recibe cupo.
- **SC-004**: Un Usuario solo ve su cupo.

## Supuestos (Assumptions)

- Depende de HU-013 · Libro contable de doble partida: el cupo es una subcuenta del libro.
- Depende de HU-002 · Alta solo con invitación vigente: extiende el trigger de alta.
- Depende de HU-085 · Alertas del sistema por audiencia: crea la alerta `cupo_inicial_no_asignado`.
- Si el cupo inicial no se puede asignar, el ingreso no falla (`docs/04` §6).
- Cuando el cupo inicial se asigna, queda registrado en la bitácora.

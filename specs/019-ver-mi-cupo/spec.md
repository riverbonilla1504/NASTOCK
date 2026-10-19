# Especificación de funcionalidad (Feature Specification): HU-019 · Ver mi cupo

**Feature Branch**: `019-ver-mi-cupo`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-019 · Ver mi cupo", en [`backlog/E-03-fondo-y-libro-contable/HU-019-ver-mi-cupo.md`](../../backlog/E-03-fondo-y-libro-contable/HU-019-ver-mi-cupo.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Ver mi cupo (Prioridad: P1)

**Como** Usuario, **quiero** ver cuánto dinero tengo en mi cupo y cuánto puedo invertir, **para** saber con qué cuento antes de decidir.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Ver el propio cupo es un permiso del Usuario (PM-10), y cada empleado ve y opera solo el suyo (RN-20). Antes del primer aporte el sistema muestra "Fondo sin capital" (RN-11). Habilita tres historias: HU-075 (opera sobre el disponible del cupo), HU-091 (extiende la pantalla Mi cupo) y HU-093 (extiende la pantalla Mi cupo).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-04, que esta historia extiende: el Usuario ve su cupo asignado en Mi cupo. Lo acompañan las pruebas de base de datos de la consulta y las de pantalla. Entrega al Usuario cuánto dinero tiene y cuánto puede invertir.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Usuario con 400 asignados, **cuando** abre Mi cupo, **entonces** ve efectivo 400,00, retenido 0,00, disponible 400,00 y patrimonio 400,00.
2. **CA-2** · **Dado** que el Administrador le asigna o le reduce dinero, **cuando** ocurre, **entonces** Mi cupo se actualiza solo al recibir el evento `cupo`.
3. **CA-3** (aislamiento) · **Dados** dos Usuarios, **cuando** cada uno llama `mi_cupo()`, **entonces** cada uno recibe solo su cupo y ninguno puede leer la subcuenta del otro por la API.
4. **CA-4** (caso borde CB-80) · **Dado** el fondo sin capital, **cuando** el Usuario abre la app, **entonces** ve "Fondo sin capital".
5. **CA-5** · **Dado** un Usuario, **cuando** abre Mi cupo, **entonces** ve además el resultado realizado, el no realizado y el rendimiento de su cupo.

---

### Casos borde (Edge Cases)

- **CB-80** · Fondo sin capital (antes del primer aporte). Interruptores apagados; la app muestra "Fondo sin capital" y el admin ve la guía de primeros pasos (`docs/12` §9; fuente: RN-11). Lo comprueba CA-4.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-052**: El sistema debe entregar al Usuario el efectivo, el retenido, el disponible, el patrimonio, el resultado realizado y no realizado y el rendimiento de su cupo, y solo del suyo. *(Consulta de mi cupo · actores: Usuario · fuente: PM-10 · RN-20 · 06 §6)*
- **FR-047**: Mientras no exista un aporte confirmado, el sistema debe mantener apagados los interruptores, no correr la IA ni aceptar operaciones, y la app debe mostrar "Fondo sin capital". *(Fondo sin capital · actores: Usuario, Analista y Administrador · fuente: RN-11 · CB-80)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §4:

- **Subcuenta de cupo**: el dinero asignado a un Usuario, con su efectivo, su invertido y su retenido. De ella salen el disponible y el patrimonio.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Un Usuario ve el efectivo, el retenido, el disponible y el patrimonio de su cupo, y su resultado y su rendimiento.
- **SC-002**: La pantalla se actualiza sola cuando el Administrador le asigna o le reduce dinero.
- **SC-003**: Ningún Usuario ve el cupo de otro.
- **SC-004**: Mientras el fondo no tiene capital, el Usuario ve "Fondo sin capital".
- **SC-005**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-04.

## Supuestos (Assumptions)

- Depende de HU-018 · Asignar y reducir cupos: muestra el dinero que se asigna al cupo.
- Depende de HU-006 · Navegación y guardas según el rol: la pantalla cuelga del menú del Usuario.
- Depende de HU-084 · Gestor de tiempo real en la app: se actualiza con el patrón foto y eventos.
- Las posiciones, las protecciones y el historial se agregan en HU-091 y HU-093.
- El rendimiento usa las fotos diarias de HU-021.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

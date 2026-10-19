# Especificación de funcionalidad (Feature Specification): HU-020 · Ver el resumen del fondo por bolsillos

**Feature Branch**: `020-resumen-del-fondo`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-020 · Ver el resumen del fondo por bolsillos", en [`backlog/E-03-fondo-y-libro-contable/HU-020-ver-el-resumen-del-fondo-por-bolsillos.md`](../../backlog/E-03-fondo-y-libro-contable/HU-020-ver-el-resumen-del-fondo-por-bolsillos.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Ver el resumen del fondo por bolsillos (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** ver el patrimonio del fondo y el peso de cada bolsillo, **para** entender cómo está repartido el dinero de RiTech.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Los tres roles ven el resumen agregado del fondo: patrimonio y peso por bolsillo (PM-30). Los Usuarios lo ven solo en agregados, nunca cupos ajenos (D-22). Habilita una historia: HU-092 (extiende la pantalla Fondo).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas que nombra la historia: las de base de datos (agregados correctos, sin filas individuales y cuenta no activa) y las de pantalla. No tiene escenario E2E propio. Entrega a cualquier persona cómo está repartido el dinero de RiTech.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** el fondo con un aporte confirmado de 10.000, **cuando** cualquier persona activa abre Fondo, **entonces** ve por bolsillo el efectivo, el valor de las posiciones, el patrimonio, el peso actual y el peso objetivo (50 / 25 / 25).
2. **CA-2** (aislamiento) · **Dado** un Usuario, **cuando** llama `resumen_fondo()`, **entonces** recibe solo agregados por bolsillo: ningún cupo individual ni ningún nombre.
3. **CA-3** · **Dado** un movimiento del libro, **cuando** ocurre, **entonces** el evento `resumen_cambio` del canal `fondo` actualiza la pantalla sin recargar.
4. **CA-4** · **Dada** una cuenta suspendida, **cuando** llama `resumen_fondo()`, **entonces** no recibe datos.

---

### Casos borde (Edge Cases)

HU-020 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-053**: El sistema debe entregar a toda persona activa, por bolsillo, el efectivo, el valor de las posiciones, el patrimonio, el peso actual y el peso objetivo, solo en agregados y sin revelar cupos individuales. *(Resumen agregado del fondo · actores: Usuario, Analista y Administrador · fuente: PM-30 · 06 §6 · D-22 · Q-04)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §4:

- **Subcuenta**: sus saldos se muestran sumados por bolsillo; nunca se muestra una subcuenta de cupo individual.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Cualquier persona activa ve, por bolsillo, el efectivo, el valor de las posiciones, el patrimonio, el peso actual y el peso objetivo.
- **SC-002**: En el resumen no aparece ningún cupo individual ni ningún nombre.
- **SC-003**: La pantalla se actualiza sola cuando se mueve el libro.
- **SC-004**: Una cuenta suspendida no recibe datos.

## Supuestos (Assumptions)

- Depende de HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25: hay saldos por bolsillo desde el primer aporte confirmado.
- Depende de HU-006 · Navegación y guardas según el rol: la pantalla cuelga del menú de los tres roles.
- Depende de HU-084 · Gestor de tiempo real en la app: se actualiza con el patrón foto y eventos.
- El resumen se entrega de una forma que deja explícito qué agregados se exponen (`docs/06` §6).
- El detalle para Analistas y Administradores está en HU-092.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.
- **Q-04** (`docs/13` §2, abierta): ¿Los empleados deben ver el patrimonio agregado del fondo por bolsillo? Valor provisional: Sí, solo agregados.

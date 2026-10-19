# Especificación de funcionalidad (Feature Specification): HU-098 · Pantalla de usuarios e invitaciones

**Feature Branch**: `098-pantalla-de-usuarios-e-invitaciones`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-098 · Pantalla de usuarios e invitaciones", en [`backlog/E-11-administracion/HU-098-pantalla-de-usuarios-e-invitaciones.md`](../../backlog/E-11-administracion/HU-098-pantalla-de-usuarios-e-invitaciones.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Pantalla de usuarios e invitaciones (Prioridad: P1)

**Como** Administrador, **quiero** ver todas las cuentas y las invitaciones con su estado y actuar sobre ellas, **para** gestionar desde una sola pantalla quién usa la plataforma.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Invitar, cambiar roles y suspender o reactivar cuentas son permisos exclusivos del Administrador (PM-50, PM-51, PM-52), y `docs/03` §3 los reúne en la entrada Usuarios e invitaciones. Habilita una historia: HU-012 (las acciones viven en la pantalla de usuarios).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de pantalla que nombra la historia: la lista, las acciones y los mensajes de error. No tiene escenario E2E propio. Entrega al Administrador una sola pantalla para gestionar quién usa la plataforma.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Administrador, **cuando** abre Usuarios e invitaciones, **entonces** ve cada cuenta con nombre, correo, rol y estado, y cada invitación con su estado y su vencimiento.
2. **CA-2** · **Dada** una cuenta, **cuando** el Administrador elige suspender, reactivar o cambiar el rol, **entonces** la app pide confirmación, llama la función correspondiente y muestra el resultado o el mensaje del código de error (`ULTIMO_ADMIN`, `AUTO_ACCION` o `CUPO_CON_POSICIONES`).
3. **CA-3** · **Dado** un cambio en una cuenta o en una invitación, **cuando** ocurre, **entonces** la lista se actualiza con los eventos `cuenta` e `invitacion` del canal `admin`.
4. **CA-4** (permiso) · **Dado** un Analista, **cuando** consulta `invitaciones` por la API, **entonces** no recibe filas.
5. **CA-5** · **Dada** la pantalla, **cuando** el Administrador invita a una persona o revoca una invitación, **entonces** la app llama la función correspondiente y muestra el resultado o el mensaje del código de error (`INVITACION_DUPLICADA` o `CORREO_YA_REGISTRADO`).

---

### Casos borde (Edge Cases)

HU-098 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-208**: La app debe listar las cuentas con su rol y estado y las invitaciones con su estado y vencimiento, y dar acceso a invitar, revocar, suspender, reactivar, cambiar rol, dar de baja y reincorporar. *(Pantalla de usuarios e invitaciones · actores: Administrador · fuente: 03 §3 · PM-50 · PM-51 · PM-52 · PM-53)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa dos, definidas en `docs/06` §5.1:

- **Perfil**: la persona dentro de la plataforma, con su correo, su nombre, su rol y su estado (activo, suspendido o baja).
- **Invitación**: el registro previo de una persona invitada, con su estado (pendiente, aceptada, revocada o vencida) y su vencimiento.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El Administrador ve todas las cuentas con su rol y su estado, y las invitaciones con su estado y su vencimiento.
- **SC-002**: Desde la pantalla invita, revoca, suspende, reactiva y cambia el rol, y ve el resultado o el mensaje del error.
- **SC-003**: La lista se actualiza sola cuando cambia una cuenta o una invitación.
- **SC-004**: Un Analista no ve las invitaciones.

## Supuestos (Assumptions)

- Depende de HU-097 · Sección de Administración y guía de primeros pasos: es una entrada de la sección de Administración.
- Depende de HU-003 · Invitar a una persona y revocar invitaciones: incluye el formulario y la lista de invitaciones.
- Depende de HU-010 · Suspender y reactivar una cuenta: usa la función `admin-usuarios`.
- Depende de HU-011 · Cambiar el rol de una cuenta: usa `cambiar_rol`.
- Dar de baja y reincorporar se agregan en HU-012.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

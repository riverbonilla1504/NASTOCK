# Especificación de funcionalidad (Feature Specification): HU-011 · Cambiar el rol de una cuenta

**Feature Branch**: `011-cambiar-el-rol`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-011 · Cambiar el rol de una cuenta", en [`backlog/E-02-identidad-y-acceso/HU-011-cambiar-el-rol-de-una-cuenta.md`](../../backlog/E-02-identidad-y-acceso/HU-011-cambiar-el-rol-de-una-cuenta.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Cambiar el rol de una cuenta (Prioridad: P1)

**Como** Administrador, **quiero** cambiar el rol de una persona, **para** que sus permisos sigan a su función real en RiTech.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Media y pertenece a la entrega R2 · El fondo existe. Cambiar el rol es un permiso exclusivo del Administrador (PM-51) y hay un solo rol por persona (D-01). Dejar de ser Usuario exige el cupo sin posiciones ni órdenes vivas (RN-54), y pasar a Usuario crea un cupo en 0 (RN-55). Habilita dos historias: HU-065 (anula la primera aprobación al cambiar el rol) y HU-098 (usa `cambiar_rol`).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas que nombra la historia: las de base de datos de cada regla y de cada error, y la de pantalla que comprueba que la navegación cambia. No tiene escenario E2E propio. Entrega al Administrador la forma de que los permisos sigan a la función real de cada persona.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Analista, **cuando** el Administrador lo cambia a Usuario, **entonces** se le crea un cupo en 0, se registra `cuenta.rol_cambiado` y su app renueva el token y rearma la navegación al recibir `perfil_actualizado`.
2. **CA-2** · **Dado** un Usuario con el cupo sin posiciones ni órdenes vivas, **cuando** pasa a otro rol, **entonces** el efectivo de su cupo vuelve a `usuarios_comun` y el cupo se cierra.
3. **CA-3** (caso borde CB-10) · **Dado** un Usuario con posiciones u órdenes vivas, **cuando** se intenta cambiar su rol, **entonces** la función responde `CUPO_CON_POSICIONES`.
4. **CA-4** (caso borde CB-09) · **Dado** el último Administrador activo, **cuando** se intenta cambiar su rol, **entonces** responde `ULTIMO_ADMIN`; y sobre uno mismo, `AUTO_ACCION`.
5. **CA-5** (permiso) · **Dado** un Usuario o un Analista, **cuando** llama `cambiar_rol`, **entonces** recibe `NO_AUTORIZADO`.

---

### Casos borde (Edge Cases)

- **CB-09** · Intento de suspender, dar de baja o cambiar de rol al último admin, o de aplicarse la acción a sí mismo. `ULTIMO_ADMIN` / `AUTO_ACCION` (`docs/12` §1; fuente: RN-50, RN-51). Lo comprueba CA-4.
- **CB-10** · Cambio de rol con cosas vivas: Usuario con posiciones pasa a Analista; analista con una 1ª aprobación pendiente pasa a otro rol. `CUPO_CON_POSICIONES` (primero se liquida); la 1ª aprobación se anula y la sugerencia vuelve a `pendiente` (`docs/12` §1; fuente: RN-54, RN-56). Lo comprueba CA-3.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-033**: El sistema debe permitir al Administrador cambiar el rol de una cuenta: al dejar de ser Usuario, exigir el cupo sin posiciones ni órdenes vivas, devolver su efectivo a `usuarios_comun` y cerrar el cupo; al pasar a Usuario, crear un cupo en 0. *(Cambio de rol · actores: Administrador · fuente: PM-51 · RN-54 · RN-55 · CB-10)*
- **FR-034**: Al recibir `perfil_actualizado`, la app debe renovar el token y rearmar la navegación de inmediato. *(Navegación actualizada al cambiar el rol · actores: Usuario, Analista y Administrador · fuente: 04 §8 · 09 §7)*
- **FR-032**: El sistema debe rechazar con `ULTIMO_ADMIN` suspender, dar de baja o cambiar de rol al último Administrador activo, y con `AUTO_ACCION` que una persona se aplique esas acciones a sí misma. *(Protección del último administrador y de la acción sobre uno mismo · actores: Administrador · fuente: RN-50 · RN-51 · CB-09)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa dos (`docs/06` §5.1 y §4):

- **Perfil**: la persona dentro de la plataforma, con su correo, su nombre, su rol y su estado (activo, suspendido o baja). El cambio de rol actualiza su rol.
- **Subcuenta de cupo**: el dinero asignado a un Usuario. Se crea en 0 cuando alguien pasa a Usuario y se cierra cuando deja de serlo.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: La persona cuyo rol cambia ve la navegación de su rol nuevo de inmediato, sin volver a ingresar.
- **SC-002**: Quien pasa a Usuario recibe un cupo en 0; quien deja de serlo devuelve su efectivo a la bolsa común y su cupo se cierra.
- **SC-003**: No se puede cambiar el rol de un Usuario con posiciones u órdenes vivas, ni el del último Administrador, ni el propio.

## Supuestos (Assumptions)

- Depende de HU-001 · Perfiles, rol actual y lecturas por rol: cambia `perfiles.rol`.
- Depende de HU-017 · Cupo al aceptar la invitación: usa `private.crear_cupo` y el cierre del cupo.
- Depende de HU-084 · Gestor de tiempo real en la app: la app escucha `perfil_actualizado`.
- Depende de HU-107 · Bitácora inmutable con cadena de hash: registra `cuenta.rol_cambiado`.
- RN-56 (anular la primera aprobación del Analista que cambia de rol) se completa en HU-065, cuando existen las sugerencias.
- La pantalla está en HU-098.

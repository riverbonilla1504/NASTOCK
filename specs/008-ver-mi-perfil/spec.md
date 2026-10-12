# Especificación de funcionalidad (Feature Specification): HU-008 · Ver mi perfil

**Feature Branch**: `008-ver-mi-perfil`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-008 · Ver mi perfil", en [`backlog/E-02-identidad-y-acceso/HU-008-ver-mi-perfil.md`](../../backlog/E-02-identidad-y-acceso/HU-008-ver-mi-perfil.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Ver mi perfil (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** ver mi nombre, mi correo, mi rol y el estado de mi cuenta, **para** confirmar con qué cuenta y con qué permisos estoy usando la plataforma.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Baja y pertenece a la entrega R1 · Ver el mercado en vivo. Ver el perfil propio es un permiso de los tres roles (PM-02) y la forma en que cada persona accede a sus datos personales (`docs/11` §6). El correo no se edita: es la identidad de Google (RN-58). Habilita dos historias: HU-068 (el interruptor vive en la pantalla de perfil) y HU-089 (las preferencias viven en la pantalla de perfil).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de la pantalla de perfil que nombra la historia. No tiene escenario E2E propio. Entrega a cada persona la confirmación de con qué cuenta y con qué permisos usa la plataforma.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una persona con sesión, **cuando** abre Perfil, **entonces** ve su nombre, su correo, su rol y su estado.
2. **CA-2** · **Dado** el perfil, **cuando** la persona busca editar el correo, **entonces** no existe esa opción: el correo es su identidad de Google.
3. **CA-3** · **Dado** un Usuario, **cuando** consulta `perfiles` por la API, **entonces** solo recibe su propia fila.

---

### Casos borde (Edge Cases)

HU-008 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-024**: El sistema debe permitir a cada persona ver su nombre, correo, rol y estado, y no debe permitir editar el correo. *(Consulta del perfil propio · actores: Usuario, Analista y Administrador · fuente: PM-02 · RN-58 · 11 §6)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §5.1:

- **Perfil**: la persona dentro de la plataforma. La pantalla muestra su nombre, su correo, su rol y su estado. El correo no se edita.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Cada persona ve su nombre, su correo, su rol y el estado de su cuenta.
- **SC-002**: No existe ninguna opción para editar el correo.
- **SC-003**: Un Usuario no ve el perfil de otra persona.

## Supuestos (Assumptions)

- Depende de HU-006 · Navegación y guardas según el rol: la pantalla cuelga del menú por rol.
- Las preferencias de notificación de esta pantalla llegan con HU-089.
- El nombre se corrige en Google Workspace (`docs/11` §6).
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

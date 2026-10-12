# Especificación de funcionalidad (Feature Specification): HU-004 · Primer administrador por configuración de despliegue

**Feature Branch**: `004-primer-administrador`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-004 · Primer administrador por configuración de despliegue", en [`backlog/E-02-identidad-y-acceso/HU-004-primer-administrador-por-configuracion-de-despliegue.md`](../../backlog/E-02-identidad-y-acceso/HU-004-primer-administrador-por-configuracion-de-despliegue.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Primer administrador por configuración de despliegue (Prioridad: P1)

**Como** Administrador, **quiero** que mi primera invitación la cree el despliegue a partir de un correo configurado, **para** poder entrar sin que existan credenciales de administrador en el código.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. Sin un Administrador nadie puede invitar a nadie, y el arranque se resuelve en el despliegue, nunca con credenciales en el código de la app (`docs/04` §9). No habilita otras historias.

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos que nombra la historia: el arranque crea la invitación cuando no hay administradores y no hace nada cuando ya hay uno. No tiene escenario E2E propio. Entrega la primera invitación de Administrador, con la que esa persona entra con Google.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** que no existe ningún Administrador y `ADMIN_INICIAL_EMAIL` tiene un correo, **cuando** se aplica la migración de arranque, **entonces** existe una invitación pendiente de Administrador para ese correo con vencimiento a 7 días.
2. **CA-2** · **Dado** que ya existe al menos un Administrador, **cuando** la migración se aplica otra vez, **entonces** no crea ninguna invitación.
3. **CA-3** · **Dada** esa invitación, **cuando** la persona ingresa con Google, **entonces** queda como Administrador activo.
4. **CA-4** · **Dado** el código de la app y del repositorio, **cuando** se revisa, **entonces** no contiene ningún usuario ni contraseña de administrador.

---

### Casos borde (Edge Cases)

HU-004 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-017**: La migración de arranque debe crear una invitación de Administrador para el correo de `ADMIN_INICIAL_EMAIL` solo cuando no existe ningún Administrador, sin credenciales en el código de la app. *(Primer administrador por configuración de despliegue · actores: Sistema · fuente: 04 §9 · Q-08)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §5.1:

- **Invitación**: el registro previo sin el cual nadie entra por primera vez. Atributos clave: correo, rol, cupo inicial, estado (pendiente, aceptada, revocada o vencida) y fecha de vencimiento (7 días por defecto). La del primer Administrador es la única que no tiene a una persona como creadora.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Tras el primer despliegue, la persona del correo configurado entra con Google y queda como Administrador activo.
- **SC-002**: Desplegar de nuevo cuando ya existe un Administrador no crea otra invitación.
- **SC-003**: En el código de la app y del repositorio no hay ningún usuario ni contraseña de administrador.

## Supuestos (Assumptions)

- Depende de HU-002 · Alta solo con invitación vigente: usa la tabla `invitaciones` y el alta por invitación.
- Reemplaza el usuario fijo de administrador que tenía la versión anterior de la app (`docs/04` §9).
- **S1** (`docs/01` §5): RiTech usa Google Workspace con dominio propio. Si resulta falso: pantalla de consentimiento Externa en modo prueba (04 §1); el resto no cambia.
- **Q-08** (`docs/13` §2, abierta): Dominio de Google Workspace y correo del primer administrador. Sin valor provisional en `docs/13`. A esta historia le aplica el correo del primer administrador, que se configura en el despliegue.

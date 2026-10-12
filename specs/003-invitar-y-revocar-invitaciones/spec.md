# Especificación de funcionalidad (Feature Specification): HU-003 · Invitar a una persona y revocar invitaciones

**Feature Branch**: `003-invitar-y-revocar-invitaciones`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-003 · Invitar a una persona y revocar invitaciones", en [`backlog/E-02-identidad-y-acceso/HU-003-invitar-a-una-persona-y-revocar-invitaciones.md`](../../backlog/E-02-identidad-y-acceso/HU-003-invitar-a-una-persona-y-revocar-invitaciones.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Invitar a una persona y revocar invitaciones (Prioridad: P1)

**Como** Administrador, **quiero** invitar a una persona con su correo, su rol y su cupo inicial, y revocar una invitación, **para** decidir quién entra a la plataforma y con qué rol.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. Invitar y revocar invitaciones es un permiso exclusivo del Administrador (PM-50), y es la única puerta para que alguien entre: no existe registro abierto (`docs/04` §1). Habilita una historia: HU-098 (incluye el formulario y la lista de invitaciones).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-02, que esta historia extiende: invitar, entrar con la invitación y comprobar que una invitación revocada no deja entrar. Lo acompañan las pruebas de base de datos: invitación válida, duplicada, correo ya registrado, revocación y rol sin permiso. Entrega al Administrador la forma de decidir quién entra y con qué rol.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Administrador activo, **cuando** invita un correo con un rol y un cupo inicial, **entonces** se crea una invitación pendiente que vence en 7 días y se registra `cuenta.invitada`.
2. **CA-2** (caso borde CB-04) · **Dado** un correo con una invitación pendiente, **cuando** el Administrador lo invita de nuevo, **entonces** recibe `INVITACION_DUPLICADA`; puede revocar la vigente y crear otra.
3. **CA-3** (caso borde CB-03) · **Dado** un correo que ya tiene cuenta, **cuando** el Administrador lo invita, **entonces** recibe `CORREO_YA_REGISTRADO`.
4. **CA-4** · **Dada** una invitación pendiente, **cuando** el Administrador la revoca, **entonces** pasa a revocada, se registra `cuenta.invitacion_revocada` y ese correo ya no puede ingresar.
5. **CA-5** (permiso) · **Dado** un Usuario o un Analista, **cuando** llama `invitar_usuario` o `revocar_invitacion`, **entonces** recibe `NO_AUTORIZADO`.
6. **CA-6** (caso borde CB-02) · **Dada** una invitación pendiente con más de 7 días, **cuando** su correo intenta ingresar, **entonces** no puede entrar; y cuando el Administrador invita de nuevo ese correo, entonces la invitación anterior pasa a vencida y se crea una nueva.
7. **CA-7** (permiso) · **Dado** un Administrador suspendido con un token todavía vigente, **cuando** llama `invitar_usuario` o `revocar_invitacion`, **entonces** la función la rechaza por no tener una sesión activa.

---

### Casos borde (Edge Cases)

- **CB-02** · La invitación venció (7 días). Igual que CB-01. El admin crea una invitación nueva (`docs/12` §1; fuente: 04 §5). Lo comprueba CA-6.
- **CB-03** · El admin invita un correo que ya tiene cuenta. `CORREO_YA_REGISTRADO`. Si la cuenta está de baja, se ofrece reincorporar (CB-06) (`docs/12` §1; fuente: 06 §9). Lo comprueba CA-3.
- **CB-04** · El admin invita dos veces el mismo correo. `INVITACION_DUPLICADA`. Puede revocar la vigente y crear otra (`docs/12` §1; fuente: 06 §5.1). Lo comprueba CA-2.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-015**: El sistema debe permitir al Administrador crear una invitación con correo, rol y cupo inicial, con vencimiento a 7 días, y rechazar la invitación de un correo que ya tiene una invitación vigente o una cuenta. *(Invitación de una persona · actores: Administrador · fuente: PM-50 · 04 §4.1 · 06 §5.1 · CB-03 · CB-04)*
- **FR-016**: El sistema debe permitir al Administrador revocar una invitación pendiente y debe dejar de aceptar toda invitación con más de 7 días. *(Revocación y vencimiento de invitaciones · actores: Administrador · fuente: PM-50 · 08 §5 · CB-02)*
- **FR-019**: El sistema debe autorizar cada lectura y cada escritura consultando el rol y el estado en `perfiles`, no los claims del token, y debe negar todo acceso a una cuenta que no esté activa. *(Autorización por perfil activo · actores: Sistema · fuente: 03 §4.2 · 03 §1 (principios))*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §5.1:

- **Invitación**: el registro previo sin el cual nadie entra por primera vez. Atributos clave: correo, rol, cupo inicial, estado (pendiente, aceptada, revocada o vencida) y fecha de vencimiento (7 días por defecto). Está vigente mientras esté pendiente y no haya pasado su fecha de vencimiento (`docs/08` §5).

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Un Administrador invita a una persona con su correo, su rol y su cupo inicial, y esa persona puede entrar durante los 7 días siguientes.
- **SC-002**: Una invitación revocada o con más de 7 días no deja entrar, y el Administrador puede invitar de nuevo ese correo.
- **SC-003**: Un Usuario o un Analista no logra invitar ni revocar.
- **SC-004**: Cada invitación y cada revocación quedan registradas en la bitácora.
- **SC-005**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-02.

## Supuestos (Assumptions)

- Depende de HU-002 · Alta solo con invitación vigente: crea la tabla `invitaciones` y el hook que la consulta.
- Depende de HU-083 · Canales privados de tiempo real: publica el evento `invitacion` en el canal `admin`.
- El sistema no envía correos de invitación: el Administrador avisa por los canales internos (`docs/04` §4.1).
- El cupo inicial es solo una intención hasta que la persona acepta (`docs/02` §11).
- La pantalla completa de cuentas llega con HU-098.
- En R1, CA-7 se prueba con una cuenta de prueba ya suspendida, porque suspender una cuenta llega con HU-010 (R2).

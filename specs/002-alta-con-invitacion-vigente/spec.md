# Especificación de funcionalidad (Feature Specification): HU-002 · Alta solo con invitación vigente

**Feature Branch**: `002-alta-con-invitacion-vigente`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-002 · Alta solo con invitación vigente", en [`backlog/E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md`](../../backlog/E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Alta solo con invitación vigente (Prioridad: P1)

**Como** Administrador, **quiero** que solo pueda crearse una cuenta para un correo del dominio de RiTech que tenga una invitación vigente, **para** que nadie ajeno a la empresa o sin invitar entre a la plataforma.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. Nadie entra si el Administrador no lo invitó antes y no existe registro abierto (`docs/04` §1). El alta exige un proveedor y un dominio permitidos y una invitación vigente (`docs/04` §5), y el ingreso es solo con Google (D-12, PM-01). Habilita cinco historias: HU-003 (crea la tabla `invitaciones` y el hook que la consulta), HU-004 (usa la tabla `invitaciones` y el alta por invitación), HU-005 (el primer ingreso depende del hook y del trigger de alta), HU-017 (extiende el trigger de alta) y HU-033 (la tabla `parametros` nace con el hook de alta).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-02, que esta historia agrega: el invitado entra, y el no invitado y el proveedor no permitido son rechazados con su mensaje. Lo acompañan las pruebas de base de datos del alta: con y sin invitación, dominio, proveedor y vencimiento. Entrega el control que decide quién puede tener una cuenta.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un correo con una invitación pendiente y no vencida, **cuando** esa persona ingresa por primera vez, **entonces** se crea su perfil activo con el rol de la invitación, la invitación queda aceptada y se registra `cuenta.activada`.
2. **CA-2** (caso borde CB-01) · **Dado** un correo del dominio sin invitación, **cuando** intenta ingresar, **entonces** el usuario no se crea y recibe "Tu correo no tiene una invitación vigente. Pídele una al administrador."
3. **CA-3** (caso borde CB-02) · **Dada** una invitación con más de 7 días, **cuando** su correo intenta ingresar, **entonces** ocurre lo mismo que sin invitación.
4. **CA-4** · **Dado** un correo de un dominio que no está en `auth.dominios_permitidos`, **cuando** intenta ingresar, **entonces** el usuario no se crea y recibe "Solo se admiten cuentas corporativas de RiTech."
5. **CA-5** (caso borde CB-92) · **Dado** `auth.proveedores_permitidos` con solo `google`, **cuando** alguien intenta darse de alta con correo y contraseña, **entonces** el usuario no se crea y recibe "Solo puedes ingresar con tu cuenta de Google de RiTech."
6. **CA-6** (caso borde CB-05) · **Dado** que Workspace cambió el correo de una cuenta, **cuando** esa persona vuelve a ingresar, **entonces** `perfiles.email` se actualiza y el cambio queda en la bitácora.
7. **CA-7** · **Dado** el entorno local o de CI con la semilla aplicada, **cuando** un usuario de prueba ingresa con correo y contraseña, **entonces** el ingreso se acepta.

---

### Casos borde (Edge Cases)

- **CB-01** · Un empleado del dominio sin invitación intenta entrar. El hook de alta rechaza; no se crea el usuario; mensaje "Tu correo no tiene una invitación vigente…" (`docs/12` §1; fuente: 04 §5). Lo comprueba CA-2.
- **CB-02** · La invitación venció (7 días). Igual que CB-01. El admin crea una invitación nueva (`docs/12` §1; fuente: 04 §5). Lo comprueba CA-3.
- **CB-05** · Workspace cambia el correo de un empleado. La identidad está ligada al identificador de Google, no al correo. En el siguiente ingreso Supabase actualiza `auth.users` y un trigger sincroniza `perfiles.email` y lo audita (`docs/12` §1; fuente: RN-58). Lo comprueba CA-6.
- **CB-92** · El proveedor de correo queda habilitado en la nube. El hook lo rechaza (`auth.proveedores_permitidos` = `["google"]`) y la prueba de humo lo detecta (`docs/12` §11; fuente: 04 §5). Lo comprueba CA-5.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-013**: En el primer ingreso, el sistema debe crear la cuenta solo si el proveedor está en `auth.proveedores_permitidos`, el dominio está en `auth.dominios_permitidos` y existe una invitación pendiente y no vencida para ese correo; en otro caso debe rechazar el alta con el mensaje definido y no crear el usuario. *(Alta solo con invitación vigente · actores: Google Workspace y Sistema (hook de alta) · fuente: 04 §5 · CB-01 · CB-02 · CB-92)*
- **FR-014**: Al crearse el usuario, el sistema debe crear su perfil en estado activo con el rol de la invitación, marcar la invitación como aceptada y registrar `cuenta.activada` en la bitácora. *(Perfil activo al aceptar la invitación · actores: Sistema · fuente: 04 §6 · 08 §5)*
- **FR-025**: Cuando Google informa un correo nuevo para una cuenta existente, el sistema debe actualizar `perfiles.email` y registrar el cambio en la bitácora. *(Sincronización del correo cambiado en Workspace · actores: Google Workspace y Sistema · fuente: CB-05 · RN-58)*
- **FR-007**: El sistema debe permitir el ingreso con correo y contraseña únicamente a los usuarios de prueba que crea la semilla en local y CI, y no debe aplicarla nunca en la nube. *(Usuarios de prueba solo en local y CI · actores: Sistema · fuente: 04 §1 · 15 §3 · D-48)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega dos entidades y usa una que ya existe (`docs/06` §5.1 y §5.6):

- **Invitación**: el registro previo sin el cual nadie entra por primera vez. Atributos clave: correo, rol, cupo inicial, estado (pendiente, aceptada, revocada o vencida) y fecha de vencimiento (7 días por defecto). Solo puede haber una pendiente por correo.
- **Parámetro**: un valor configurable del sistema, con su clave, su valor y su descripción. Esta historia usa dos: los proveedores de ingreso permitidos y los dominios permitidos.
- **Perfil**: la persona dentro de la plataforma. Nace activo, con el rol de su invitación, cuando esa persona ingresa por primera vez.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Una persona invitada entra por primera vez y queda con su cuenta activa y con el rol de su invitación.
- **SC-002**: Una persona sin invitación vigente, de un dominio no permitido o con un proveedor no permitido no logra crear una cuenta y ve el mensaje definido para su caso.
- **SC-003**: El alta de cada cuenta queda registrada en la bitácora.
- **SC-004**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-02.

## Supuestos (Assumptions)

- Depende de HU-001 · Perfiles, rol actual y lecturas por rol: el trigger crea la fila de `perfiles`.
- Depende de HU-107 · Bitácora inmutable con cadena de hash: el alta registra `cuenta.activada`.
- Depende de TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba: los usuarios de prueba viven en `seed.sql`.
- Depende de TT-06 · Arnés E2E de backend y de la app: agrega el escenario E2E-02.
- El control de alta y lo que ocurre al crearse el usuario se registran también en el proyecto de la nube (`docs/04` §3, paso 7).
- La migración nunca agrega el correo a los proveedores permitidos: los usuarios de prueba con correo y contraseña existen solo en local y en CI (D-48).
- **S1** (`docs/01` §5): RiTech usa Google Workspace con dominio propio. Si resulta falso: pantalla de consentimiento Externa en modo prueba (04 §1); el resto no cambia.
- **Q-22** (`docs/13` §2, abierta): ¿RiTech tiene organización de Google Workspace, o se usa la pantalla Externa en modo prueba? Valor provisional: Workspace.
- **Q-08** (`docs/13` §2, abierta): Dominio de Google Workspace y correo del primer administrador. Sin valor provisional en `docs/13`. A esta historia le aplica el dominio, que es el valor de los dominios permitidos.

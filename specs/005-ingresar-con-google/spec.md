# Especificación de funcionalidad (Feature Specification): HU-005 · Ingresar con Google en Android y web

**Feature Branch**: `005-ingresar-con-google`

**Created**: 2026-10-10

**Status**: Draft

**Input**: Historia de usuario: "HU-005 · Ingresar con Google en Android y web", en [`backlog/E-02-identidad-y-acceso/HU-005-ingresar-con-google-en-android-y-web.md`](../../backlog/E-02-identidad-y-acceso/HU-005-ingresar-con-google-en-android-y-web.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Ingresar con Google en Android y web (Prioridad: P1)

**Como** Usuario, Analista o Administrador invitado, **quiero** entrar a la app con mi cuenta de Google de RiTech desde Android o desde el navegador, **para** usar la plataforma sin crear ni recordar otra contraseña.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. El ingreso con Google es la única forma de entrar a la plataforma (D-12) y la primera acción que la matriz de permisos da a los tres roles (PM-01). Habilita seis historias: HU-006 (necesita una sesión con rol), HU-007 (cierra la sesión que abre el ingreso), HU-009 (protege la sesión que abre el ingreso), HU-084 (abre los canales al iniciar sesión), HU-087 (registra el token al iniciar sesión) y HU-111 (el aviso se presenta tras el primer ingreso).

**Prueba independiente (Independent Test)**: Se demuestra sola con la prueba manual de `docs/04` §3, paso 10, hecha en Android y en el navegador con tres cuentas: la cuenta invitada entra y queda con la sesión iniciada en la pantalla de inicio; la cuenta del dominio que no fue invitada es rechazada; y la cuenta personal de Gmail la rechaza Google. Entrega una persona invitada con la sesión iniciada. No tiene escenario E2E propio, porque el ingreso con Google no se puede automatizar (`docs/04` §1).

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una persona invitada, **cuando** toca "Entrar con Google" en Android, **entonces** el ingreso nativo entrega el `id_token` a Supabase y la persona queda con la sesión iniciada en la pantalla de inicio.
2. **CA-2** · **Dada** una persona invitada, **cuando** entra desde la web, **entonces** la redirección OAuth con PKCE preselecciona la cuenta corporativa y vuelve a la app con la sesión iniciada.
3. **CA-3** · **Dada** una cuenta suspendida o de baja, **cuando** intenta ingresar, **entonces** ve "Tu cuenta está suspendida. Comunícate con el administrador."
4. **CA-4** · **Dado** un dispositivo sin conexión, **cuando** intenta ingresar, **entonces** ve "No hay conexión. Revisa tu internet e inténtalo de nuevo."; y si cierra la ventana de Google, vuelve a la pantalla de ingreso sin mensaje.
5. **CA-5** (caso borde CB-01) · **Dado** un correo del dominio sin una invitación vigente, **cuando** intenta ingresar, **entonces** ve "Tu correo no tiene una invitación vigente. Pídele una al administrador."
6. **CA-6** · **Dado** un error inesperado al iniciar sesión, **cuando** ocurre, **entonces** ve "No pudimos iniciar tu sesión. Inténtalo de nuevo." y el detalle queda en el registro técnico, no en la pantalla.
7. **CA-7** · **Dada** una cuenta de Google de fuera del Workspace de RiTech (por ejemplo, una personal de Gmail), **cuando** intenta ingresar, **entonces** Google la rechaza.

---

### Casos borde (Edge Cases)

- **CB-01** · Un empleado del dominio sin invitación intenta entrar. El hook de alta rechaza; no se crea el usuario; mensaje "Tu correo no tiene una invitación vigente…" (`docs/12` §1; fuente: 04 §5). Lo comprueba CA-5.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-012**: El sistema debe permitir iniciar sesión únicamente con una cuenta de Google del dominio permitido: con ingreso nativo en Android y con redirección OAuth con PKCE en web. *(Inicio de sesión con Google · actores: Usuario, Analista y Administrador · fuente: PM-01 · D-12 · 04 §1 · 04 §4.3 · 04 §4.4)*
- **FR-022**: La app debe mostrar el mensaje definido para cada fallo de ingreso: sin invitación vigente, cuenta suspendida o de baja, sin conexión y error inesperado; si la persona cierra la ventana de Google, debe volver a la pantalla de ingreso sin mensaje. *(Mensajes de error de ingreso · actores: Usuario, Analista y Administrador · fuente: 04 §11)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa estas dos, ya definidas en `docs/06` §5.1:

- **Perfil**: la persona dentro de la plataforma, unida a su cuenta de Google. Atributos clave: correo, nombre, rol (usuario, analista o administrador) y estado (activo, suspendido o baja). El estado decide si puede entrar; el rol lo usa HU-006 para el menú.
- **Invitación**: el registro previo sin el cual nadie entra por primera vez. Atributos clave: correo, rol, estado (pendiente, aceptada, revocada o vencida) y fecha de vencimiento. Una invitación aceptada origina un perfil.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Una persona invitada y activa, de cualquiera de los tres roles, entra desde Android y desde el navegador con su cuenta de Google de RiTech y queda con la sesión iniciada en la pantalla de inicio, sin crear ni escribir ninguna contraseña propia de la plataforma.
- **SC-002**: La prueba manual de `docs/04` §3, paso 10, da sus tres resultados: la cuenta invitada entra, la cuenta del dominio sin invitación es rechazada y la cuenta personal de Gmail la rechaza Google.
- **SC-003**: En cada una de las situaciones de fallo de `docs/04` §11, la persona ve exactamente el mensaje definido, o ninguno si cerró la ventana de Google, y nunca un detalle técnico en pantalla.
- **SC-004**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se mantiene: la historia no agrega un escenario propio y E2E-01 sigue en verde con el ingreso por correo del modo pruebas.

## Supuestos (Assumptions)

- Depende de TT-04 · Esqueleto de la app Flutter para Android y web: la pantalla se construye sobre el esqueleto de la app.
- Depende de TT-02 · Cuentas, conexiones y secretos de los servicios externos: necesita los clientes OAuth de Google y el proveedor configurado en Supabase.
- Depende de HU-002 · Alta solo con invitación vigente: el primer ingreso depende del hook y del trigger de alta.
- La historia no necesita entidades de datos nuevas.
- El ingreso nativo en Android se construye con la guía oficial vigente de Supabase en el momento de implementarlo, porque la API del componente de ingreso de Google cambió en su versión 7 (`docs/04` §4.4).
- El ingreso con Google no se puede automatizar (`docs/04` §1): las pruebas automáticas usan el ingreso con correo del modo pruebas, que existe solo en local y en CI.
- En R1, CA-3 se prueba con una cuenta de prueba ya suspendida, porque suspender una cuenta llega con HU-010 (R2).
- **S1** (`docs/01` §5): RiTech usa Google Workspace con dominio propio. Si resulta falso: pantalla de consentimiento Externa en modo prueba (04 §1); el resto no cambia.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.
- **Q-22** (`docs/13` §2, abierta): ¿RiTech tiene organización de Google Workspace, o se usa la pantalla Externa en modo prueba? Valor provisional: Workspace.
- **Q-08** (`docs/13` §2, abierta): Dominio de Google Workspace y correo del primer administrador. Sin valor provisional en `docs/13`. A esta historia le aplica el dominio, que es el que se usa para preseleccionar la cuenta corporativa en la web (CA-2).

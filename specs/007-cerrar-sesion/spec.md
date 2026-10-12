# Especificación de funcionalidad (Feature Specification): HU-007 · Cerrar sesión

**Feature Branch**: `007-cerrar-sesion`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-007 · Cerrar sesión", en [`backlog/E-02-identidad-y-acceso/HU-007-cerrar-sesion.md`](../../backlog/E-02-identidad-y-acceso/HU-007-cerrar-sesion.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Cerrar sesión (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** cerrar mi sesión, **para** que nadie más use la app con mi cuenta en ese dispositivo.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Media y pertenece a la entrega R1 · Ver el mercado en vivo. Cerrar sesión es parte del ciclo de vida de la conexión: la app cierra sus canales en vivo y revoca la sesión (`docs/04` §4.5 y `docs/09` §7). Habilita una historia: HU-087 (borra el token al cerrar sesión).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de pantalla del cierre de sesión que nombra la historia. No tiene escenario E2E propio. Entrega la forma de dejar un dispositivo sin acceso a la cuenta.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una sesión abierta, **cuando** la persona cierra sesión, **entonces** la app cancela sus suscripciones de tiempo real y llama `signOut()`, que revoca el refresh token.
2. **CA-2** · **Dado** un cierre de sesión en Android, **cuando** la persona vuelve a entrar, **entonces** Google le permite elegir cuenta.
3. **CA-3** · **Dado** un cierre de sesión, **cuando** termina, **entonces** la app queda en `/ingreso` y no conserva en pantalla datos de la sesión anterior.

---

### Casos borde (Edge Cases)

HU-007 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-023**: Al cerrar sesión, la app debe cancelar sus suscripciones de tiempo real, eliminar el token de push del dispositivo, revocar la sesión en Supabase y cerrar la sesión de Google. *(Cierre de sesión · actores: Usuario, Analista y Administrador · fuente: 04 §4.5 · 09 §7)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no maneja entidades de datos de `docs/06`: actúa sobre la sesión, que administra el servicio de autenticación (`docs/04` §1).

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Después de cerrar sesión, la app queda en la pantalla de ingreso y no muestra datos de la sesión anterior.
- **SC-002**: Después de cerrar sesión, la app deja de recibir actualizaciones en vivo y la sesión no se puede renovar.
- **SC-003**: En Android, al volver a entrar se puede elegir otra cuenta de Google.

## Supuestos (Assumptions)

- Depende de HU-005 · Ingresar con Google en Android y web: cierra la sesión que abre el ingreso.
- El borrado del token de push al cerrar sesión (`docs/04` §4.5, paso 2) llega con HU-087.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

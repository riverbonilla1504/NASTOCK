# Especificación de funcionalidad (Feature Specification): HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles

**Feature Branch**: `009-sesion-segura-y-confirmacion`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles", en [`backlog/E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md`](../../backlog/E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Sesión segura, bloqueo biométrico y confirmación de acciones sensibles (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** que la app guarde mi sesión de forma segura, se bloquee al volver de segundo plano y me pida confirmar cada acción sensible, **para** que nadie decida sobre el dinero con mi teléfono desatendido.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. La sesión se guarda en el almacenamiento seguro del dispositivo, la app se bloquea al volver de segundo plano y toda decisión sobre dinero exige confirmación (`docs/04` §8). En nada que toque dinero hay actualización optimista (`docs/08` §9.3). Habilita seis historias: HU-062 (exige la confirmación biométrica), HU-063 (exige la confirmación de la acción), HU-075 (exige la confirmación biométrica), HU-090 (pide biometría antes de mostrar datos), HU-099 (confirma los movimientos de dinero) y HU-100 (confirma los movimientos de dinero).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de pantalla del componente de confirmación y del bloqueo que nombra la historia. No tiene escenario E2E propio. Entrega una app que nadie más puede usar para decidir sobre el dinero con el teléfono desatendido.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** la app en Android, **cuando** guarda la sesión, **entonces** usa el almacenamiento seguro del sistema y no preferencias planas.
2. **CA-2** · **Dada** la app en segundo plano por más de `app.minutos_bloqueo` minutos, **cuando** vuelve a primer plano, **entonces** pide biometría o el PIN del dispositivo antes de mostrar datos.
3. **CA-3** · **Dada** una acción sensible (aprobar o rechazar una sugerencia, crear una orden manual o registrar un movimiento de dinero), **cuando** la persona la inicia en móvil, **entonces** la app exige confirmación biométrica; en web muestra un diálogo que repite monto y símbolo.
4. **CA-4** · **Dada** una confirmación que la persona cancela, **cuando** la descarta, **entonces** la acción no se envía.
5. **CA-5** (caso borde CB-08) · **Dado** un teléfono perdido con la app instalada, **cuando** alguien lo abre, **entonces** el bloqueo impide ver los datos.

---

### Casos borde (Edge Cases)

- **CB-08** · Un empleado pierde el teléfono. Biometría y bloqueo protegen la app. El admin suspende la cuenta (o el admin de Workspace cierra sus sesiones de Google) y la reactiva cuando tenga otro dispositivo (`docs/12` §1; fuente: 04 §8). Lo comprueba CA-5.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-026**: La app móvil debe guardar la sesión en el almacenamiento seguro del sistema operativo y no en preferencias planas. *(Sesión en almacenamiento seguro · actores: Usuario, Analista y Administrador · fuente: 04 §8)*
- **FR-027**: La app móvil debe pedir biometría o el PIN del dispositivo antes de mostrar datos cuando vuelve de segundo plano después de `app.minutos_bloqueo` minutos. *(Bloqueo biométrico de la app · actores: Usuario, Analista y Administrador · fuente: 04 §8 · CB-08)*
- **FR-028**: La app debe exigir confirmación biométrica en móvil, o un diálogo que repite monto y símbolo en web, antes de aprobar o rechazar una sugerencia, crear una orden manual o registrar un movimiento de dinero. *(Confirmación de acciones sensibles · actores: Usuario, Analista y Administrador · fuente: 04 §8 · 08 §9.3)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no maneja entidades de datos de `docs/06`: protege la sesión en el dispositivo.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Al volver de segundo plano después del tiempo configurado (5 minutos por defecto), la app pide biometría o el PIN del dispositivo antes de mostrar datos.
- **SC-002**: Ninguna acción sensible se envía sin confirmación; si la persona la cancela, no se envía.
- **SC-003**: En el móvil, la sesión no queda guardada en preferencias planas.
- **SC-004**: Quien abre un teléfono perdido con la app instalada no ve los datos.

## Supuestos (Assumptions)

- Depende de HU-005 · Ingresar con Google en Android y web: protege la sesión que abre el ingreso.
- El bloqueo es una protección local, no de servidor (`docs/04` §8).
- En web la sesión queda en el almacenamiento del navegador y se mitiga con la sesión corta de 15 minutos.
- No hay actualización optimista en nada que toque dinero.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

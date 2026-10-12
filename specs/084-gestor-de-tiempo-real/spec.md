# Especificación de funcionalidad (Feature Specification): HU-084 · Gestor de tiempo real en la app

**Feature Branch**: `084-gestor-de-tiempo-real`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-084 · Gestor de tiempo real en la app", en [`backlog/E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md`](../../backlog/E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Gestor de tiempo real en la app (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** que las pantallas se actualicen solas y me avisen si pierdo la conexión, **para** confiar en que lo que veo está al día.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. Las pantallas se actualizan con el patrón de foto y eventos: la foto se pide por la API y cada evento solo avisa qué cambió (`docs/08` §9.2). La app abre los canales de su rol al iniciar sesión y pide las fotos otra vez al reconectar (`docs/09` §7). Habilita nueve historias: HU-010 (la app escucha su canal para cerrar la sesión), HU-011 (la app escucha `perfil_actualizado`), HU-019 (se actualiza con el patrón foto y eventos), HU-020 (se actualiza con el patrón foto y eventos), HU-030 (consume el canal `mercado` y usa el reloj corregido), HU-048 (se actualiza con el patrón foto y eventos), HU-061 (se actualiza con el patrón foto y eventos), HU-064 (se actualiza con el canal `supervision`) y HU-086 (la bandeja se actualiza con el patrón foto y eventos).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas unitarias que nombra la historia: el descarte por versión, la reconexión y el reloj corregido. No tiene escenario E2E propio; la ejercita E2E-03. Entrega pantallas que se actualizan solas y avisan cuando se pierde la conexión.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una sesión iniciada, **cuando** la app arranca, **entonces** abre los canales de su rol: todos abren `mercado`, `fondo` y `usuario:{id}`; el Analista, además, `supervision`; y el Administrador, además, `supervision` y `admin`.
2. **CA-2** · **Dado** un evento con una versión menor o igual a la que la app ya tiene, **cuando** llega, **entonces** se ignora; con una versión mayor, la app pide ese registro por la API.
3. **CA-3** (caso borde CB-66) · **Dada** una pérdida de conexión, **cuando** ocurre, **entonces** la app muestra "Reconectando…" con los datos atenuados y, al reconectar, pide otra vez las fotos completas.
4. **CA-4** · **Dado** el estado sin conexión, **cuando** la persona ve una pantalla con decisiones, **entonces** los botones de decisión quedan deshabilitados.
5. **CA-5** (caso borde CB-70) · **Dado** un teléfono con el reloj desfasado, **cuando** se muestra una cuenta regresiva, **entonces** usa el desfase medido contra el servidor.
6. **CA-6** · **Dada** una pantalla con datos en vivo, **cuando** se monta, **entonces** la app pide la foto por la API y se suscribe al canal.

---

### Casos borde (Edge Cases)

- **CB-66** · Realtime se desconecta. La app reconecta y pide fotos; el push cubre lo urgente (`docs/12` §8; fuente: 09 §7). Lo comprueba CA-3.
- **CB-70** · El reloj del teléfono está desfasado. Las cuentas regresivas usan el desfase medido contra el servidor; las decisiones las valida el servidor (`docs/12` §8; fuente: 08 §9.1). Lo comprueba CA-5.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-188**: La app debe pedir la foto por la API al abrir cada pantalla, pedir por la API el registro de cada evento que llega, ignorar los eventos con versión no mayor a la que tiene y pedir la foto completa al reconectar. *(Actualización en vivo con foto y eventos · actores: Usuario, Analista y Administrador · fuente: 08 §9.2 · 09 §7)*
- **FR-189**: La app debe mostrar "Reconectando…" con los datos atenuados mientras reconecta y, sin conexión, debe deshabilitar los botones de decisión. *(Indicador de conexión · actores: Usuario, Analista y Administrador · fuente: 08 §9.4 · CB-66)*
- **FR-190**: La app debe calcular las cuentas regresivas con el desfase medido entre el reloj del dispositivo y el del servidor. *(Reloj corregido con el servidor · actores: Usuario, Analista y Administrador · fuente: 08 §9.1 · CB-70)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no maneja entidades de datos de `docs/06`: administra la conexión en vivo de la app y lee cada dato por la API.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Las pantallas con datos en vivo se actualizan solas, sin recargar.
- **SC-002**: Al perder la conexión, la app muestra "Reconectando…" con los datos atenuados; sin conexión, los botones de decisión quedan deshabilitados.
- **SC-003**: Al reconectar, la app vuelve a pedir los datos completos.
- **SC-004**: Las cuentas regresivas son correctas aunque el reloj del dispositivo esté desfasado.

## Supuestos (Assumptions)

- Depende de HU-083 · Canales privados de tiempo real: se suscribe a los canales privados.
- Depende de TT-04 · Esqueleto de la app Flutter para Android y web: vive en `lib/core/` de la app.
- Depende de HU-005 · Ingresar con Google en Android y web: abre los canales al iniciar sesión.
- Los eventos avisan, no informan: el dato siempre se lee por la API, donde se aplican los permisos (`docs/09` §4).
- Al renovarse la sesión no hay que volver a suscribirse.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.
- **S4** (`docs/01` §5): Pocos usuarios concurrentes (decenas, no miles). Si resulta falso: revisar límites de Realtime y el plan de datos de mercado.

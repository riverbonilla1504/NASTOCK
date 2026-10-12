# Especificación de funcionalidad (Feature Specification): HU-083 · Canales privados de tiempo real

**Feature Branch**: `083-canales-privados-de-tiempo-real`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-083 · Canales privados de tiempo real", en [`backlog/E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md`](../../backlog/E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Canales privados de tiempo real (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** que cada persona solo pueda escuchar los canales en vivo de su rol y que los eventos no lleven montos, **para** ver los cambios al instante sin que nadie reciba información que no le toca.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. Los avisos en la app llegan en tiempo real (D-14). Todos los canales son privados y solo la base de datos publica en ellos (`docs/09` §3), y los eventos solo avisan qué cambió, sin montos (D-32). Habilita ocho historias: HU-003 (publica el evento `invitacion` en el canal `admin`), HU-010 (publica `sesion_revocada` en el canal de la persona), HU-014 (publica el evento `capital` en el canal `admin`), HU-028 (publica en el canal `mercado`), HU-033 (publica `parametro` en el canal `admin`), HU-034 (publica `interruptor` en el canal `admin`), HU-084 (se suscribe a los canales privados) y HU-085 (publica el evento `alerta`).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos que nombra la historia: cada canal por rol, cuenta no activa y publicación de clientes bloqueada. No tiene escenario E2E propio; la ejercitan E2E-03 y E2E-08. Entrega los canales en vivo, cada uno abierto solo a quien le corresponde.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una persona activa, **cuando** se suscribe a `mercado`, a `fondo` y a `usuario:{su id}`, **entonces** la suscripción se acepta.
2. **CA-2** (aislamiento) · **Dado** un Usuario, **cuando** intenta suscribirse a `usuario:{otro id}`, a `supervision` o a `admin`, **entonces** la suscripción se rechaza; un Analista y un Administrador entran a `supervision`, y solo un Administrador entra a `admin`.
3. **CA-3** (permiso) · **Dado** un cliente con sesión, **cuando** intenta publicar en cualquier canal, **entonces** se rechaza: solo la base de datos publica.
4. **CA-4** · **Dado** un evento de entidad, **cuando** se publica, **entonces** su carga trae solo tabla, id, versión y estado, sin montos.
5. **CA-5** · **Dada** una cuenta suspendida, **cuando** intenta suscribirse, **entonces** todas las suscripciones se rechazan.

---

### Casos borde (Edge Cases)

HU-083 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-186**: El sistema debe publicar eventos solo desde la base de datos y en canales privados: `mercado` y `fondo` para toda persona activa, `usuario:{id}` solo para su dueño, `supervision` para Analistas y Administradores y `admin` solo para Administradores; ningún cliente puede publicar. *(Canales privados por rol · actores: Sistema · fuente: 09 §3 · 03 §4.6)*
- **FR-187**: El sistema debe enviar en cada evento de entidad solo la tabla, el id, la versión y el estado, y nunca montos; la única excepción son los precios del canal `mercado`. *(Eventos sin montos · actores: Sistema · fuente: 09 §4 · D-32)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades de `docs/06`. Define los cinco canales de `docs/09` §3: mercado y fondo para toda persona activa, el canal de cada persona solo para ella, supervisión para Analistas y Administradores, y administración solo para Administradores.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Una persona activa recibe en vivo lo de mercado, lo del fondo y lo suyo; un Analista recibe además lo de supervisión, y un Administrador lo de supervisión y lo de administración.
- **SC-002**: Un Usuario no logra escuchar el canal de otra persona, ni el de supervisión, ni el de administración.
- **SC-003**: Nadie logra publicar desde la app: solo publica la base de datos.
- **SC-004**: Ningún evento de entidad lleva montos.
- **SC-005**: Una cuenta suspendida no logra suscribirse a ningún canal.

## Supuestos (Assumptions)

- Depende de HU-001 · Perfiles, rol actual y lecturas por rol: las políticas usan `private.rol_actual()` y `private.es_supervisor()`.
- Cada historia que cambia algo visible en vivo publica su evento en el canal que le corresponde (`docs/14` §6).
- Los mensajes de tiempo real se borran a las 72 horas.
- **S4** (`docs/01` §5): Pocos usuarios concurrentes (decenas, no miles). Si resulta falso: revisar límites de Realtime y el plan de datos de mercado.

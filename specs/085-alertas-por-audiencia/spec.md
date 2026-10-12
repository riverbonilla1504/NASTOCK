# Especificación de funcionalidad (Feature Specification): HU-085 · Alertas del sistema por audiencia

**Feature Branch**: `085-alertas-por-audiencia`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-085 · Alertas del sistema por audiencia", en [`backlog/E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md`](../../backlog/E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Alertas del sistema por audiencia (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** ver las alertas que me corresponden sin que se repitan, **para** enterarme de lo importante una sola vez.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Ver las alertas dirigidas a todos es un permiso de los tres roles (PM-05). Una alerta se avisa una sola vez y se rearma al resolverse, con la lógica que viene de la versión anterior (`docs/05` §11). Habilita nueve historias: HU-013 (la verificación diaria crea una alerta), HU-015 (alerta al Administrador si el aporte no se confirma), HU-017 (crea la alerta `cupo_inicial_no_asignado`), HU-035 (crea la alerta de integración caída), HU-049 (guarda y muestra las alertas por audiencia), HU-050 (alerta al Administrador), HU-078 (alerta cuando la protección no está siendo vigilada), HU-086 (las alertas generan notificaciones) y HU-110 (crea la alerta crítica).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas que nombra la historia: las de base de datos (audiencias, deduplicación, rearme y lectura por rol) y la de pantalla. No tiene escenario E2E propio. Entrega a cada persona las alertas que le corresponden, una sola vez.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una alerta con audiencia `todos`, **cuando** cualquier persona activa abre Alertas, **entonces** la ve; con audiencia `analistas` la ven Analistas y Administradores; con `administradores`, solo los Administradores; y con `usuario`, solo esa persona.
2. **CA-2** · **Dada** una alerta activa con una clave de deduplicación, **cuando** el sistema detecta lo mismo otra vez, **entonces** no crea otra.
3. **CA-3** · **Dada** una alerta resuelta, **cuando** su causa vuelve a ocurrir, **entonces** se crea una alerta nueva.
4. **CA-4** (aislamiento) · **Dado** un Usuario, **cuando** consulta `alertas`, **entonces** no recibe las de audiencia `analistas` o `administradores` ni las dirigidas a otra persona.
5. **CA-5** · **Dado** un símbolo de la lista blanca que deja de ser negociable, **cuando** la sincronización diaria lo detecta, **entonces** se crea una alerta para el Administrador.

---

### Casos borde (Edge Cases)

HU-085 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-191**: El sistema debe mostrar a cada persona las alertas de su audiencia (todos, analistas, administradores o dirigidas a ella) y no debe repetir una alerta activa con la misma clave. *(Alertas por audiencia · actores: Usuario, Analista y Administrador · fuente: PM-05 · 06 §5.5 · 03 §4.3)*
- **FR-065**: El sistema debe sincronizar a diario si cada símbolo de la lista blanca es negociable y fraccionable, y debe desactivar y alertar al Administrador el que deje de ser negociable. *(Atributos de los activos · actores: Sistema y Broker (Alpaca) · fuente: 10 §5 · 10 §10 · 10 §12)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega una entidad, definida en `docs/06` §5.5:

- **Alerta**: un aviso del sistema. Atributos clave: severidad, audiencia (todos, analistas, administradores o una persona) y la clave que impide repetirla mientras sigue activa.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Cada persona ve solo las alertas de su audiencia.
- **SC-002**: Lo mismo detectado dos veces no crea dos alertas activas.
- **SC-003**: Resuelta una alerta, si su causa vuelve a ocurrir se crea una nueva.
- **SC-004**: El Administrador recibe una alerta cuando un símbolo de la lista blanca deja de ser negociable.

## Supuestos (Assumptions)

- Depende de HU-001 · Perfiles, rol actual y lecturas por rol: las audiencias se resuelven con el rol de `perfiles`.
- Depende de HU-083 · Canales privados de tiempo real: publica el evento `alerta`.
- Depende de HU-006 · Navegación y guardas según el rol: la pantalla cuelga del menú de los tres roles.
- Depende de HU-027 · Calendario, reloj y estado del mercado: conecta la alerta de símbolo no negociable.
- `docs/14` §4 ubica las alertas en R3, pero R2 ya las necesita (CB-11 y CB-15); las alertas de la IA llegan en R3 (HU-049).
- El evento de alerta va solo al canal de supervisión (`docs/09` §3): un Usuario se entera en vivo por su notificación, que llega con HU-086.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

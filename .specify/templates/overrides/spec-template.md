<!--
  PLANTILLA DE SPEC DEL PROYECTO, en español. Sustituye a .specify/templates/spec-template.md.
  Al escribir la spec, quita este bloque y todos los comentarios.

  ENTRADA    Una historia de backlog/ (HU-xxx). Una spec por historia. Las tareas técnicas (TT) no llevan spec.
  CARPETA    specs/<número de la historia en 3 dígitos>-<nombre-corto>, igual a la rama (docs/15 §7).
             Se pasa como SPECIFY_FEATURE_DIRECTORY; no se usa el consecutivo del kit.
  QUÉ LEER   Solo la historia, los FR que cita y las secciones de docs/ que nombra en "Reglas" y en sus
             casos borde. Además, lo que aplique de docs/06 (entidades), docs/01 §5 y §6 y docs/13 §2.
  NO INVENTAR  Nada de supuestos razonables ni de estándares de la industria. Todo sale de la historia,
             del catálogo de FR o de docs/. Lo que docs/ no define, no se escribe.
  QUÉ, NO CÓMO  No se copia la sección "Tareas" ni se nombran funciones, tablas o archivos de código.
             Excepción: los criterios de aceptación, la descripción de cada FR, el texto de los casos
             borde de docs/12 y los motivos de "Relaciones" se copian tal cual.
  MARCADORES   FR-xxx, SC-001, P1 y [NEEDS CLARIFICATION: …] quedan literales.
  [NEEDS CLARIFICATION: …]  Solo para lo que la historia trae en "Documentación a actualizar" cuando no
             dice "Ninguna". Si son más de tres, van los tres de mayor impacto y el resto a Supuestos.
  LISTA DE CALIDAD  checklists/requirements.md va en español. Si un punto falla solo porque un criterio
             o un FR copiado nombra tecnología, no se reescribe el criterio: se anota en las notas.
-->

# Especificación de funcionalidad (Feature Specification): [HU-xxx · Título de la historia]

**Feature Branch**: `[NNN-nombre-corto]`

**Created**: [AAAA-MM-DD]

**Status**: Draft

**Input**: Historia de usuario: "[HU-xxx · Título de la historia]", en [`backlog/[carpeta de la épica]/[archivo de la historia]`](../../backlog/[carpeta de la épica]/[archivo de la historia])

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

<!-- Una sola historia por spec, siempre con prioridad P1. -->

### Historia de usuario 1 (User Story 1) - [Título de la historia] (Prioridad: P1)

<!-- La narrativa de la sección "Historia", en una línea. -->
**Como** [rol], **quiero** [acción], **para** [beneficio].

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad [prioridad] y pertenece a la entrega [entrega]. [La regla o decisión de docs/ que la hace necesaria.] Habilita [n] historias: [HU-xxx (motivo de "Relaciones")], […].

**Prueba independiente (Independent Test)**: [Cómo se demuestra sola: su escenario E2E o, si no tiene uno propio, la prueba que nombra la historia; y qué entrega.]

**Escenarios de aceptación (Acceptance Scenarios)**:

<!-- Todos los criterios de la historia, uno por uno, con su CA-n y su marca: (caso borde CB-xx),
     (permiso) o (aislamiento). El mismo texto de la historia; solo se resaltan Dado/Dada, cuando y entonces. -->

1. **CA-1** · **Dado** [estado inicial], **cuando** [acción], **entonces** [resultado].
2. **CA-2** (caso borde CB-xx) · **Dado** [estado inicial], **cuando** [acción], **entonces** [resultado].

---

### Casos borde (Edge Cases)

<!-- Los CB del campo "Casos borde" de la historia, con lo que hace el sistema según docs/12 y el
     criterio que lo comprueba. Si la historia no cita ninguno, se dice en una línea; no se inventan. -->

- **CB-xx** · [Situación]. [Lo que hace el sistema, con el texto de `docs/12`] (`docs/12` §[n]; fuente: [fuente]). Lo comprueba CA-[n].

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

<!-- Los FR que cita la historia, sin renumerar. La descripción, tal cual; entre paréntesis el
     nombre, los actores y la fuente. Si la historia no cita ninguno, se dice en una línea. -->

- **FR-xxx**: [Descripción del catálogo] *([Nombre] · actores: [rol o actor] · fuente: [fuente])*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

<!-- Primero, si la historia agrega entidades o usa las que ya existen. Después, las entidades de
     docs/06 que toca, en lenguaje del negocio: qué representa cada una y sus atributos clave.
     Si la historia no maneja datos, se dice en una línea. -->

- **[Entidad]**: [Qué representa y sus atributos clave, según `docs/06`].

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

<!-- Resultados que una persona puede comprobar, derivados de la narrativa, los criterios y la prueba
     independiente. Incluye los indicadores de docs/01 §6 que apliquen. No se inventan metas
     numéricas que docs/ no define. -->

- **SC-001**: [Resultado comprobable]
- **SC-002**: [Resultado comprobable]

## Supuestos (Assumptions)

<!-- En este orden:
     1. Cada "Depende de" de la sección "Relaciones", con su motivo.
     2. Los supuestos de las "Notas técnicas" y del "Escenario E2E" de la historia.
     3. Los supuestos de docs/01 §5 que apliquen: identificador, texto y qué pasa si resultan falsos.
     4. Las preguntas abiertas de docs/13 §2 que apliquen: identificador, pregunta y valor provisional. -->

- Depende de [ítem · título]: [motivo].
- [Supuesto de las notas de la historia].
- **S[n]** (`docs/01` §5): [supuesto]. Si resulta falso: [consecuencia].
- **Q-xx** (`docs/13` §2, abierta): [pregunta]. Valor provisional: [valor].

# Especificación de funcionalidad (Feature Specification): HU-116 · Tema, estilos, widgets y fuentes de la v2

**Feature Branch**: `116-tema-y-estilos-de-la-v2`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-116 · Tema, estilos, widgets y fuentes de la v2", en [`backlog/E-13-transicion-desde-la-v2/HU-116-tema-estilos-widgets-y-fuentes-de-la-v2.md`](../../backlog/E-13-transicion-desde-la-v2/HU-116-tema-estilos-widgets-y-fuentes-de-la-v2.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Tema, estilos, widgets y fuentes de la v2 (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** que la app nueva conserve la identidad visual de la v2, **para** reconocer la plataforma y que todas las pantallas se vean consistentes.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Baja y pertenece a la entrega R1 · Ver el mercado en vivo. La interfaz, el tema y las fuentes de la versión anterior están entre las piezas que se pueden copiar a la nueva (`docs/05` §11). No habilita otras historias.

**Prueba independiente (Independent Test)**: Se demuestra sola revisando que el tema, los estilos, los componentes comunes y la fuente quedan en la app nueva y que el análisis estático no deja advertencias. No tiene escenario E2E propio. Entrega la base visual que usan todas las pantallas.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dados** `app_theme.dart`, `app_styles.dart`, los widgets comunes y la fuente Poppins de la v2, **cuando** se copian, **entonces** quedan en `lib/app/`, `lib/shared/` y `assets/fonts/`.
2. **CA-2** · **Dada** cualquier pantalla nueva, **cuando** se construye, **entonces** usa el tema y los widgets comunes.
3. **CA-3** · **Dado** el código copiado, **cuando** corre `flutter analyze`, **entonces** no deja advertencias.

---

### Casos borde (Edge Cases)

HU-116 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

HU-116 no cita requisitos funcionales. La historia dice: "Ninguno: este ítem no agrega un requisito funcional del producto."

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no maneja entidades de datos.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: La app nueva conserva el tema, los estilos, los componentes comunes y la fuente de la versión anterior.
- **SC-002**: Toda pantalla nueva usa ese tema y esos componentes.
- **SC-003**: El código copiado no deja advertencias en el análisis estático.

## Supuestos (Assumptions)

- Depende de TT-04 · Esqueleto de la app Flutter para Android y web: se copia dentro del esqueleto de la app.
- No agrega un requisito funcional: es la base visual que usan todas las pantallas.
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

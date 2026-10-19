# Especificación de funcionalidad (Feature Specification): HU-115 · Motor ×2 teórico de la v2 con sus pruebas

**Feature Branch**: `115-motor-x2-teorico`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-115 · Motor ×2 teórico de la v2 con sus pruebas", en [`backlog/E-13-transicion-desde-la-v2/HU-115-motor-x2-teorico-de-la-v2-con-sus-pruebas.md`](../../backlog/E-13-transicion-desde-la-v2/HU-115-motor-x2-teorico-de-la-v2-con-sus-pruebas.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Motor ×2 teórico de la v2 con sus pruebas (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** que la línea ×2 teórico se calcule con el motor ya probado de la v2, **para** comparar el fondo con la referencia que RiTech ya conoce.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Media y pertenece a la entrega R1 · Ver el mercado en vivo. La versión nueva conserva la fórmula ×2 como referencia teórica (`docs/01` §7) y copia del repositorio anterior el motor que la calcula, con su prueba (`docs/05` §11). Habilita una historia: HU-031 (usa el motor ×2 copiado de la v2).

**Prueba independiente (Independent Test)**: Se demuestra sola con la prueba que viene con el motor, que debe pasar en la app nueva. No tiene escenario E2E propio. Entrega el cálculo de la línea ×2 teórico que usa la comparación de HU-031.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** el repositorio v2, **cuando** se copia `performance_engine.dart` con su prueba, **entonces** queda en la app nueva y su prueba pasa en `flutter test`.
2. **CA-2** · **Dada** una serie de barras diarias de QQQ, **cuando** se calcula ×2 teórico, **entonces** es dos veces la variación acumulada desde el inicio del periodo.
3. **CA-3** · **Dado** el código copiado, **cuando** se revisa, **entonces** no arrastra los controladores en memoria, el login con contraseña ni la bitácora en memoria de la v2.

---

### Casos borde (Edge Cases)

HU-115 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-227**: El sistema debe calcular la serie ×2 teórico como dos veces la variación acumulada de QQQ desde el inicio del periodo, con barras diarias. *(Línea ×2 teórico · actores: Sistema · fuente: 02 §13 · 05 §11)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no maneja entidades de datos de `docs/06`: calcula una serie a partir de las barras diarias de QQQ (`docs/02` §13).

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El motor copiado calcula ×2 teórico como dos veces la variación acumulada de QQQ desde el inicio del periodo.
- **SC-002**: La prueba que viene con el motor pasa en la app nueva.
- **SC-003**: El código copiado no trae los controladores en memoria, el ingreso con contraseña ni la bitácora en memoria de la versión anterior.

## Supuestos (Assumptions)

- Depende de TT-04 · Esqueleto de la app Flutter para Android y web: se copia dentro del esqueleto de la app.
- El origen es el repositorio de la versión anterior de la app (`docs/05` §11).
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.

# Especificación de funcionalidad (Feature Specification): HU-029 · Barra diaria tras el cierre y retención de barras de minuto

**Feature Branch**: `029-barra-diaria-y-retencion`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-029 · Barra diaria tras el cierre y retención de barras de minuto", en [`backlog/E-04-datos-de-mercado/HU-029-barra-diaria-tras-el-cierre-y-retencion-de-barras-de-minuto.md`](../../backlog/E-04-datos-de-mercado/HU-029-barra-diaria-tras-el-cierre-y-retencion-de-barras-de-minuto.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Barra diaria tras el cierre y retención de barras de minuto (Prioridad: P1)

**Como** Analista, **quiero** que el sistema guarde la barra diaria de cada símbolo al cierre y conserve las de minuto solo lo necesario, **para** que las gráficas y las métricas de la IA tengan historia sin llenar la base de datos.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Media y pertenece a la entrega R1 · Ver el mercado en vivo. Las barras diarias se guardan siempre y las de minuto solo 5 días, para no acercarse al límite de la base de datos del plan gratuito (`docs/06` §10). La barra diaria la agrega el cierre de cada día (`docs/10` §12). Habilita cinco historias: HU-021 (reutiliza la función `cierre-diario` y su trabajo programado), HU-031 (usa las barras diarias de QQQ y de QLD), HU-044 (usa las barras diarias del universo), HU-056 (usa las barras diarias y la función `cierre-diario`) y HU-112 (extiende el trabajo `limpieza`).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas que nombra la historia: las del cierre diario y las de la condición del trabajo programado con el reloj fijado. No tiene escenario E2E propio. Entrega la historia diaria de cada símbolo sin llenar la base de datos.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** que el mercado cerró hoy, **cuando** corre `cierre-diario`, **entonces** cada símbolo del universo tiene su barra de hoy en `barras_diarias`.
2. **CA-2** · **Dado** que `cierre-diario` ya corrió hoy, **cuando** el trabajo programado vuelve a preguntar, **entonces** no corre otra vez.
3. **CA-3** · **Dadas** barras de minuto con más de 5 días, **cuando** corre la limpieza, **entonces** se borran; y solo se guardan las de los ETFs y las de los símbolos con posiciones.
4. **CA-4** · **Dado** un día sin sesión de mercado, **cuando** el trabajo programado pregunta, **entonces** `cierre-diario` no corre.

---

### Casos borde (Edge Cases)

HU-029 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-070**: El sistema debe agregar la barra diaria de cada símbolo tras el cierre y conservar barras de minuto por 5 días solo para los ETFs y los símbolos con posiciones. *(Barras diarias y de minuto · actores: Sistema · fuente: 06 §5.2 · 06 §10 · 10 §12)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega una entidad y usa otra (`docs/06` §5.2):

- **Barra de minuto**: el resumen de un minuto de mercado de un símbolo. Se guarda 5 días y solo para los ETFs y los símbolos con posiciones.
- **Barra diaria**: el resumen de un día de mercado de un símbolo. Se guarda siempre.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Después de cada cierre de mercado, cada símbolo del universo tiene su barra de ese día.
- **SC-002**: El cierre diario corre una sola vez por día de mercado y no corre en un día sin sesión.
- **SC-003**: Las barras de minuto con más de 5 días se borran, y solo existen las de los ETFs y las de los símbolos con posiciones.

## Supuestos (Assumptions)

- Depende de HU-026 · Universo del NASDAQ-100 y carga histórica de barras: guarda las barras de los símbolos del universo.
- Depende de HU-027 · Calendario, reloj y estado del mercado: sabe si el mercado ya cerró por el calendario.
- El cierre diario crece con otras historias: fotos de patrimonio (HU-021), rebalanceo (HU-024), evaluación de la IA (HU-056) y renovación de protecciones (HU-082).
- El resto de la retención de `docs/06` §10 está en HU-112.
- **S6** (`docs/01` §5): El plan gratuito de Supabase alcanza para el MVP (límites y cómo se manejan en 05 §3.4). Si resulta falso: pasar a un plan pago requiere aprobación (D-45).

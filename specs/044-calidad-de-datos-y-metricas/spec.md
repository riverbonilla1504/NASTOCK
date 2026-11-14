# Especificación de funcionalidad (Feature Specification): HU-044 · Calidad de datos, métricas y puntaje cuantitativo

**Feature Branch**: `044-calidad-de-datos-y-metricas`

**Created**: 2026-11-14

**Status**: Implementada (corte de demo D-70 y cierre D-72; especificación escrita después de construir)

**Input**: Historia de usuario: "HU-044 · Calidad de datos, métricas y puntaje cuantitativo", en [`backlog/E-06-ia-contexto-y-decision/HU-044-calidad-de-datos-metricas-y-puntaje-cuantitativo.md`](../../backlog/E-06-ia-contexto-y-decision/HU-044-calidad-de-datos-metricas-y-puntaje-cuantitativo.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Calidad de datos, métricas y puntaje cuantitativo (Prioridad: P1)

**Como** Analista, **quiero** que la IA principal verifique los datos de cada acción y calcule sus métricas antes de analizar, **para** que ninguna decisión se base en datos incompletos, viejos o anómalos.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R3 · La IA analiza. Habilita HU-045 · Adaptador de JEV y estado en etiquetas, HU-046 · Ciclo del agente: programación, uno a la vez y omisiones.

**Prueba independiente (Independent Test)**: Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-07.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una acción con menos de 60 barras diarias, con la última barra distinta de la sesión anterior, con un precio en vivo de más de 60 segundos o con un salto de más de ±25 % sin suspensión informada, **cuando** se verifica, **entonces** queda excluida del ciclo con su motivo.
2. **CA-2** (caso borde CB-87) · **Dado** que QQQ falla la verificación, **cuando** empieza el ciclo, **entonces** el ciclo completo queda omitido.
3. **CA-3** · **Dado** un símbolo con datos válidos, **cuando** se calculan sus métricas, **entonces** se obtienen los rendimientos a 1, 5, 20 y 60 días, la volatilidad de 20 y 60 días, el ATR y el RSI de 14 días, la posición frente a las medias de 20, 50 y 200 días, la caída desde el máximo de 52 semanas, el volumen relativo y la regla de tendencia de la v2.
4. **CA-4** · **Dado** el universo con sus métricas, **cuando** se calcula Q, **entonces** es el percentil de `0,6·ra20 + 0,4·ra60`, con 0,1 de bonificación si está sobre la media de 50 días y tope 1.
5. **CA-5** · **Dado** Q, **cuando** se eligen las candidatas, **entonces** son las `ia.candidatos_max` mejores de Arriesgadas, todos los símbolos activos de Usuarios y todo símbolo con posición abierta.

---

### Casos borde (Edge Cases)

- **CB-87** · Una acción del universo tiene datos incompletos o un salto anómalo. Se excluye del ciclo con el motivo; si es QQQ, el ciclo se omite. (`docs/12` §10; fuente: 07 §4.1). Lo comprueba CA-2.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-102**: El sistema debe excluir del ciclo, con el motivo registrado, toda candidata que incumpla completitud, actualidad, valores válidos, saltos anómalos o coherencia del precio, y debe omitir el ciclo si falla QQQ. *(Verificación de calidad de datos · actores: Sistema (IA principal) · fuente: 07 §4.1 · CB-87)*
- **FR-103**: El sistema debe calcular por símbolo rendimientos a 1, 5, 20 y 60 días, volatilidad de 20 y 60 días, ATR y RSI de 14 días, posición frente a las medias de 20, 50 y 200 días, caída desde el máximo de 52 semanas, volumen relativo y la regla de tendencia de la v2, y con ellos el puntaje cuantitativo Q. *(Métricas y puntaje cuantitativo · actores: Sistema (IA principal) · fuente: 07 §4.1 · 05 §11)*
- **FR-104**: El sistema debe evaluar en cada ciclo las `ia.candidatos_max` mejores por Q de Arriesgadas, todos los símbolos activos de la lista de Usuarios y todo símbolo con posición abierta. *(Selección de candidatas · actores: Sistema (IA principal) · fuente: 07 §4.1)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

- **Barra diaria** (`barras_diarias`): apertura, máximo, mínimo, cierre y volumen de cada símbolo por sesión (docs/06 §3).
- **Cotización** (`cotizaciones`): último precio en vivo y su hora de recepción, para la antigüedad.
- **Evaluación de candidata** (`evaluaciones_candidatos`): guarda la calidad de datos, las métricas y el puntaje cuantitativo de cada símbolo en cada ciclo (docs/06 §5.3).

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Queda excluida del ciclo con su motivo (CA-1).
- **SC-002**: El ciclo completo queda omitido (CA-2).
- **SC-003**: Se obtienen los rendimientos a 1, 5, 20 y 60 días, la volatilidad de 20 y 60 días, el ATR y el RSI de 14 días, la posición frente a las medias de 20, 50 y 200 días, la caída desde el máximo de 52 semanas, el volumen relativo y la regla de tendencia de la v2 (CA-3).
- **SC-004**: Es el percentil de `0,6·ra20 + 0,4·ra60`, con 0,1 de bonificación si está sobre la media de 50 días y tope 1 (CA-4).
- **SC-005**: Son las `ia.candidatos_max` mejores de Arriesgadas, todos los símbolos activos de Usuarios y todo símbolo con posición abierta (CA-5).

## Supuestos (Assumptions)

- Depende de HU-029 · Barra diaria tras el cierre y retención de barras de minuto: Usa las barras diarias del universo.
- Depende de HU-028 · Ingesta de precios cada 15 segundos: Usa el precio en vivo y su antigüedad.
- CA-5: los símbolos con posición abierta ya quedan incluidos, porque las órdenes manuales solo se crean en el bolsillo de Usuarios (D-64) y el ciclo evalúa todos sus símbolos activos (D-72).
- Con la bolsa cerrada la calidad exige la última barra diaria disponible y no un precio en vivo de menos de 60 s (D-70, punto 3).
- Sin contexto ni noticias (D-59): la IA decide con estas métricas y con JEV.

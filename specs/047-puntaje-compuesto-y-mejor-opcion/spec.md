# Especificación de funcionalidad (Feature Specification): HU-047 · Puntaje compuesto y elección de la mejor opción

**Feature Branch**: `047-puntaje-compuesto-y-mejor-opcion`

**Created**: 2026-11-14

**Status**: Implementada (corte de demo D-70 y cierre D-72; especificación escrita después de construir)

**Input**: Historia de usuario: "HU-047 · Puntaje compuesto y elección de la mejor opción", en [`backlog/E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md`](../../backlog/E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Puntaje compuesto y elección de la mejor opción (Prioridad: P1)

**Como** Analista, **quiero** que el sistema combine en código los datos y las respuestas de JEV y elija la mejor opción de cada bolsillo solo si supera los umbrales, **para** que la decisión sea reproducible y pese el riesgo tanto como la ganancia.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R3 · La IA analiza. Sin contexto (D-59, [docs/14 §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)): - CA-2 se cumple siempre: toda candidata queda "sin contexto", con C, S y T en 0,5. - CA-7: la evaluación guarda el contexto vacío. - La dependencia de HU-043 no aplica. - Las señales se registran y **no** se convierten en sugerencias (D-65). Lo que las notas técnicas dicen de HU-058 y HU-059 queda para la fase siguiente. D-72: sin señales ni validación con el motor de políticas (CA-5 y CA-6 quedan para la fase siguiente; con D-65 nadie las usa). Cada evaluación lleva un nivel: favorable, vigilar o desfavorable (07 §6.3). Habilita HU-048 · Pantalla Oportunidades con la explicación de cada evaluación, HU-049 · Alertas de contradicción y de mercado, HU-052 · Opinión de la IA sobre una orden manual, HU-053 · Señales de venta de posiciones abiertas, HU-054 · Versiones del prompt de contexto y de la configuración de decisión, HU-058 · Sugerencia de compra para Arriesgadas, HU-112 · Retención de datos y vigilancia del tamaño de la base.

**Prueba independiente (Independent Test)**: E2E-07 (nuevo)

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dadas** las respuestas de JEV de una candidata, **cuando** se calcula el puntaje, **entonces** es `wQ·Q + wC·C + wS·S + wT·T + wV·(1−V) + wE·(1−E) + wR·(1−R)` con los pesos del bolsillo, que suman 1.
2. **CA-2** · **Dado** un contexto ausente, viejo o con `context_grounded` menor que 0,5, **cuando** se calcula, **entonces** C, S y T valen 0,5 y la evaluación queda marcada "sin contexto".
3. **CA-3** · **Dadas** varias candidatas elegibles de un bolsillo, **cuando** se elige, **entonces** gana la de mayor puntaje; (caso borde) CB-86: en empate gana la de mayor confianza y luego la de menor volatilidad.
4. **CA-4** (caso borde CB-85) · **Dado** que ninguna candidata cumple `buy_now`, confianza, contradicción y puntaje mínimos, **cuando** termina el ciclo, **entonces** queda completado sin señales.
5. **CA-5** (caso borde CB-60) · **Dada** una señal viva del mismo símbolo en el bolsillo, **cuando** vuelve a salir elegida, **entonces** no se crea otra. *Fuera de la entrega (D-72): queda para la fase siguiente.*
6. **CA-6** · **Dada** una señal que viola una regla del motor de políticas, **cuando** se valida, **entonces** no se crea y queda en `propuestas_descartadas` con su regla. *Fuera de la entrega (D-72): queda para la fase siguiente.*
7. **CA-7** · **Dado** cualquier ciclo, **cuando** termina, **entonces** cada candidata tiene su fila en `evaluaciones_candidatos` con métricas, etiquetas, contexto, respuestas de JEV, puntajes, versiones y resultado.

---

### Casos borde (Edge Cases)

- **CB-60** · La misma candidata sale elegida en cada ciclo. No se crea otra señal mientras haya una viva (RR-10). (`docs/12` §7; fuente: 07 §6.3). Lo comprueba CA-5.
- **CB-85** · JEV responde con confianza baja para todas las candidatas. No se propone nada. Queda registrado como ciclo completado sin señales. (`docs/12` §10; fuente: 07 §6.3). Lo comprueba CA-4.
- **CB-86** · Empate de puntaje entre dos candidatas. Gana la de mayor confianza de JEV; si persiste, la de menor volatilidad. (`docs/12` §10; fuente: 07 §6.3). Lo comprueba CA-3.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-113**: El sistema debe combinar en código el puntaje cuantitativo, el respaldo del contexto, el sentimiento, el sector, la volatilidad, el riesgo de evento y el de reversión con los pesos del bolsillo; con contexto ausente o no confiable debe fijar contexto, sentimiento y sector en 0,5 y marcar la evaluación. *(Puntaje compuesto · actores: Sistema (IA principal) · fuente: 07 §6.2 · D-41 · Q-21)*
- **FR-114**: El sistema debe convertir en señal de compra solo la candidata elegible con mayor puntaje de cada bolsillo (desempate por mayor confianza y luego menor volatilidad) que cumpla: calidad de datos, `entry_timing = buy_now`, confianza mayor o igual a `jev.confianza_minima`, contradicción menor que `jev.umbral_contradiccion`, puntaje mayor o igual a `jev.puntaje_minimo` y ninguna señal viva del símbolo; si ninguna cumple, no debe proponer nada. *(Reglas de decisión de compra · actores: Sistema (IA principal) · fuente: 07 §6.3 · CB-60 · CB-85 · CB-86)*
- **FR-115**: El sistema debe fijar en código el porcentaje del disponible según el tramo de confianza, el stop como múltiplo del ATR acotado al rango del bolsillo y el objetivo como múltiplo del stop. *(Tamaño, stop y objetivo de la señal · actores: Sistema (IA principal) · fuente: 07 §7.1 · 02 §6.1)*
- **FR-116**: El sistema debe emitir como máximo una señal de compra por bolsillo en cada ciclo. *(Una señal de compra por bolsillo por ciclo · actores: Sistema (IA principal) · fuente: 07 §12)*
- **FR-117**: El sistema debe pasar toda señal por el motor de políticas antes de crearla y guardar las rechazadas con la regla que violaron. *(Señales validadas por el motor de políticas · actores: Sistema (IA principal) · fuente: 07 §3 · 06 §5.3 · 01 §2 (P3))*
- **FR-118**: El sistema debe guardar por cada candidata de cada ciclo sus métricas, las etiquetas enviadas, el contexto usado, las respuestas completas de JEV, los puntajes, la versión del modelo y de la configuración y su resultado: elegida, elegible no elegida, descartada por una regla o excluida por un motivo. *(Registro de cada evaluación · actores: Sistema (IA principal) · fuente: 07 §3 · 06 §5.3)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

- **Evaluación de candidata** (`evaluaciones_candidatos`): puntaje compuesto, aportes por dimensión, confianza, contradicción, resultado (`elegida`, `elegible_no_elegida`, `no_elegible:<motivo>`, `excluida:<motivo>`) y explicación con su nivel (docs/07 §6.3, D-72).

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Es `wQ·Q + wC·C + wS·S + wT·T + wV·(1−V) + wE·(1−E) + wR·(1−R)` con los pesos del bolsillo, que suman 1 (CA-1).
- **SC-002**: C, S y T valen 0,5 y la evaluación queda marcada "sin contexto" (CA-2).
- **SC-003**: Gana la de mayor puntaje; (caso borde) CB-86: en empate gana la de mayor confianza y luego la de menor volatilidad (CA-3).
- **SC-004**: Queda completado sin señales (CA-4).
- **SC-005**: Cada candidata tiene su fila en `evaluaciones_candidatos` con métricas, etiquetas, contexto, respuestas de JEV, puntajes, versiones y resultado (CA-7).

## Supuestos (Assumptions)

- Depende de HU-046 · Ciclo del agente: programación, uno a la vez y omisiones: La decisión corre dentro del ciclo.
- Depende de HU-045 · Adaptador de JEV y estado en etiquetas: Usa las respuestas de JEV.
- Depende de HU-037 · Motor de políticas: reglas de la propuesta: Toda señal pasa por `validar_operacion`.
- Depende de TT-06 · Arnés E2E de backend y de la app: Agrega el escenario E2E-07.
- Sin contexto (D-59): C, S y T valen siempre 0,5 y toda evaluación queda marcada "sin contexto" (CA-2).
- Sin sugerencias (D-65): la mejor candidata de cada bolsillo queda como recomendación (`elegida`) y no se crean señales.
- Cada evaluación lleva un nivel coherente con su puntaje: favorable, vigilar o desfavorable (docs/07 §6.3, D-72).

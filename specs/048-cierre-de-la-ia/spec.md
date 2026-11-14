# Especificación de funcionalidad (Feature Specification): HU-048 · Pantalla Oportunidades con la explicación de cada evaluación

**Feature Branch**: `048-cierre-de-la-ia`

**Created**: 2026-11-14

**Status**: Implementada (corte de demo D-70 y cierre D-72; especificación escrita después de construir)

**Input**: Historia de usuario: "HU-048 · Pantalla Oportunidades con la explicación de cada evaluación", en [`backlog/E-06-ia-contexto-y-decision/HU-048-pantalla-oportunidades-con-la-explicacion-de-cada-evaluacion.md`](../../backlog/E-06-ia-contexto-y-decision/HU-048-pantalla-oportunidades-con-la-explicacion-de-cada-evaluacion.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Pantalla Oportunidades con la explicación de cada evaluación (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** ver qué acciones está evaluando la IA y por qué eligió o descartó cada una, **para** entender y poder juzgar lo que propone.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R3 · La IA analiza. Sin contexto (D-59, [docs/14 §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)): - CA-1: sin el resumen del contexto. - CA-3: sin los titulares usados ni sus enlaces. - CA-4: toda candidata lleva la advertencia "sin contexto". - Tareas: la RPC `oportunidades(bolsillo)` y el detalle de la app van sin contexto ni titulares. E2E-06 queda así: ciclo con JEV simulado → Oportunidades con explicación, y toda candidata sale "sin contexto" (15 §4). - La candidata elegida se muestra como **recomendación**, sin botón para aprobarla: la persona decide creando una orden manual (D-65). D-72: cada candidata muestra su nivel (favorable, vigilar o desfavorable) y lo que respondió JEV: probabilidades de comprar ahora, esperar y evitar, y sus juicios de riesgo en palabras (07 §14). Habilita HU-049 · Alertas de contradicción y de mercado, HU-051 · Análisis bajo demanda de un símbolo.

**Prueba independiente (Independent Test)**: E2E-06 (nuevo)

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un ciclo completado, **cuando** un Analista abre Oportunidades, **entonces** ve las candidatas de todos los bolsillos con su puntaje, su confianza, los aportes por dimensión, las advertencias y el resumen del contexto.
2. **CA-2** (aislamiento) · **Dado** un Usuario, **cuando** llama `oportunidades('arriesgadas')`, **entonces** no recibe candidatas: solo ve las del bolsillo de Usuarios.
3. **CA-3** · **Dada** la candidata elegida, **cuando** se abre su detalle, **entonces** muestra por qué ganó (las tres dimensiones que más aportaron), qué la frena y los titulares usados con su enlace.
4. **CA-4** · **Dada** una candidata evaluada "sin contexto", excluida o descartada, **cuando** se muestra, **entonces** lleva el motivo visible.
5. **CA-5** · **Dado** un ciclo nuevo, **cuando** termina, **entonces** Analistas y Administradores ven la pantalla actualizarse con el evento `ciclo_agente`.

---

### Casos borde (Edge Cases)

Ninguno propio.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-119**: La app debe mostrar las candidatas del último ciclo con puntaje, confianza, aportes por dimensión, advertencias y resumen del contexto; al Usuario solo las del bolsillo de Usuarios. *(Pantalla Oportunidades · actores: Usuario, Analista y Administrador · fuente: PM-35 · 06 §6 · 03 §3)*
- **FR-120**: El sistema debe armar en código la explicación de cada decisión con piezas verificables: qué se propone, por qué ganó, qué la frena, el contexto con sus titulares enlazados y las advertencias. *(Explicación de cada decisión · actores: Sistema (IA principal) · fuente: 07 §14 · D-42)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

- **Oportunidad**: lo que devuelve la RPC `oportunidades(bolsillo)` por cada candidata del último ciclo completado: puntaje, confianza, aportes, métricas y explicación (qué, por qué, qué la frena, advertencias, nivel y lo que respondió JEV).

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Ve las candidatas de todos los bolsillos con su puntaje, su confianza, los aportes por dimensión, las advertencias y el resumen del contexto (CA-1).
- **SC-002**: No recibe candidatas: solo ve las del bolsillo de Usuarios (CA-2).
- **SC-003**: Muestra por qué ganó (las tres dimensiones que más aportaron), qué la frena y los titulares usados con su enlace (CA-3).
- **SC-004**: Lleva el motivo visible (CA-4).
- **SC-005**: Analistas y Administradores ven la pantalla actualizarse con el evento `ciclo_agente` (CA-5).

## Supuestos (Assumptions)

- Depende de HU-047 · Puntaje compuesto y elección de la mejor opción: Muestra las evaluaciones del último ciclo.
- Depende de HU-006 · Navegación y guardas según el rol: La pantalla cuelga del menú de los tres roles.
- Depende de HU-084 · Gestor de tiempo real en la app: Se actualiza con el patrón foto y eventos.
- Depende de TT-06 · Arnés E2E de backend y de la app: Agrega el escenario E2E-06.
- Sin contexto (D-59): no hay resumen del contexto ni titulares; la explicación lo advierte.
- CA-5: la pantalla se actualiza sola cada minuto y al deslizar hacia abajo; todavía no escucha el evento `ciclo_agente`, que el servidor ya publica en el canal `supervision`.
- No hay candidatas descartadas por el motor de políticas, porque no hay señales (D-72).

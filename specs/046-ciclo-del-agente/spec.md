# Especificación de funcionalidad (Feature Specification): HU-046 · Ciclo del agente: programación, uno a la vez y omisiones

**Feature Branch**: `046-ciclo-del-agente`

**Created**: 2026-11-14

**Status**: Implementada (corte de demo D-70 y cierre D-72; especificación escrita después de construir)

**Input**: Historia de usuario: "HU-046 · Ciclo del agente: programación, uno a la vez y omisiones", en [`backlog/E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md`](../../backlog/E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Ciclo del agente: programación, uno a la vez y omisiones (Prioridad: P1)

**Como** Analista, **quiero** que la IA corra un ciclo de decisión a intervalos regulares, uno a la vez, y que se omita cuando no debe correr, **para** que el análisis sea constante y nunca corra en condiciones en las que no debe.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R3 · La IA analiza. Sin contexto (D-59, [docs/14 §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)): el ciclo no busca contexto ni encola su regeneración (paso 4 de 07 §3). Cada candidata pasa a JEV "sin contexto". Los criterios de aceptación no cambian. D-72: el ciclo respeta `ia_activa` (CA-3, motivo `ia_apagada`) y el Administrador lanza ciclos con `lanzar_ciclo()` (CA-5). Con la bolsa cerrada evalúa con la última sesión y JEV juzga para la próxima sesión (D-70, D-72). Sin ciclo por evento de QQQ (CA-4 queda para la fase siguiente). Habilita HU-047 · Puntaje compuesto y elección de la mejor opción, HU-050 · Presupuesto mensual de IA.

**Prueba independiente (Independent Test)**: Sin escenario propio en el catálogo de 15 §4. Lo ejercitan E2E-06 y E2E-07.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dados** la ventana de compras abierta, `ia_activa` encendido y `ia.minutos_entre_ciclos` minutos desde el último ciclo, **cuando** el trabajo programado pregunta, **entonces** despierta a `agente` y se registra un ciclo `en_curso`.
2. **CA-2** · **Dado** un ciclo `en_curso` de menos de 5 minutos, **cuando** se intenta otro, **entonces** no empieza; (caso borde) CB-62: si el ciclo en curso tiene más de 5 minutos, se marca `fallido` y el nuevo sigue.
3. **CA-3** · **Dado** el mercado cerrado, `ia_activa` apagado, el fondo sin capital o los datos desactualizados, **cuando** llega el ciclo, **entonces** queda `omitido` con su motivo.
4. **CA-4** (caso borde CB-55) · **Dado** que QQQ se movió al menos `ia.umbral_evento_qqq_pct` desde el último ciclo y este fue hace más de 3 minutos, **cuando** se publican las cotizaciones, **entonces** se dispara un ciclo extra. *Fuera de la entrega (D-72): queda para la fase siguiente.*
5. **CA-5** (permiso) · **Dado** un Administrador, **cuando** llama `lanzar_ciclo()`, **entonces** corre un ciclo con disparador `manual`; un Usuario o un Analista reciben `NO_AUTORIZADO`.

---

### Casos borde (Edge Cases)

- **CB-55** · QQQ se mueve bruscamente (≥ umbral de evento). Ciclo extra del agente. Si la caída del día supera 3 %, alerta crítica del sistema a todos. (`docs/12` §6; fuente: 07 §2). Lo comprueba CA-4.
- **CB-62** · Un ciclo se cuelga. El siguiente lo marca `fallido` y sigue. (`docs/12` §7; fuente: 07 §3). Lo comprueba CA-2.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-109**: El sistema debe correr un ciclo de decisión cada `ia.minutos_entre_ciclos` minutos dentro de la ventana de compras con `ia_activa` encendido, uno a la vez, y marcar como fallido un ciclo en curso de más de 5 minutos. *(Ciclo programado del agente · actores: Sistema (IA principal) · fuente: 07 §2 · 07 §3 · CB-62 · Q-16)*
- **FR-110**: El sistema debe correr un ciclo extra cuando QQQ se mueve al menos `ia.umbral_evento_qqq_pct` desde el último ciclo y ese ciclo fue hace más de 3 minutos. *(Ciclo por evento de mercado · actores: Sistema (IA principal) · fuente: 07 §2 · CB-55)*
- **FR-111**: El sistema debe dejar el ciclo como omitido con su motivo cuando el mercado está cerrado, la IA está pausada, el presupuesto está agotado, el fondo no tiene capital o los datos están desactualizados. *(Omisión del ciclo · actores: Sistema (IA principal) · fuente: 07 §2)*
- **FR-112**: El sistema debe permitir al Administrador lanzar un ciclo de decisión en cualquier momento. *(Ciclo manual · actores: Administrador · fuente: PM-58 · 07 §2)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

- **Ciclo del agente** (`ciclos_agente`): disparador (`programado`, `manual`), estado (`en_curso`, `completado`, `omitido`, `fallido`), motivo de omisión, conteos y duración (docs/06 §5.3).

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Despierta a `agente` y se registra un ciclo `en_curso` (CA-1).
- **SC-002**: No empieza; (caso borde) CB-62: si el ciclo en curso tiene más de 5 minutos, se marca `fallido` y el nuevo sigue (CA-2).
- **SC-003**: Queda `omitido` con su motivo (CA-3).
- **SC-004**: Corre un ciclo con disparador `manual`; un Usuario o un Analista reciben `NO_AUTORIZADO` (CA-5).

## Supuestos (Assumptions)

- Depende de HU-044 · Calidad de datos, métricas y puntaje cuantitativo: El ciclo empieza por la verificación de calidad.
- Depende de HU-034 · Encender y apagar los interruptores del fondo: No corre con `ia_activa` apagado ni con el fondo sin capital.
- Depende de HU-033 · Parámetros configurables con rango e historial: Lee la frecuencia y los umbrales del catálogo.
- Depende de HU-027 · Calendario, reloj y estado del mercado: Solo corre en la ventana de compras.
- Depende de HU-028 · Ingesta de precios cada 15 segundos: El evento de QQQ se detecta al publicar cotizaciones.
- Con la bolsa cerrada el ciclo no se omite: evalúa con la última sesión cada 6 h y JEV juzga para la próxima sesión regular (D-70, D-72). Es una excepción del MVP a CA-1 y CA-3.
- El fondo sin capital se cubre con `ia_activa`: no se puede encender sin un aporte confirmado (RN-11, HU-034).
- No hay presupuesto de IA en el MVP (HU-050 fuera); el ciclo no se omite por presupuesto.

# Especificación de funcionalidad (Feature Specification): HU-045 · Adaptador de JEV y estado en etiquetas

**Feature Branch**: `045-adaptador-de-jev`

**Created**: 2026-11-14

**Status**: Implementada (corte de demo D-70 y cierre D-72; especificación escrita después de construir)

**Input**: Historia de usuario: "HU-045 · Adaptador de JEV y estado en etiquetas", en [`backlog/E-06-ia-contexto-y-decision/HU-045-adaptador-de-jev-y-estado-en-etiquetas.md`](../../backlog/E-06-ia-contexto-y-decision/HU-045-adaptador-de-jev-y-estado-en-etiquetas.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Adaptador de JEV y estado en etiquetas (Prioridad: P1)

**Como** Analista, **quiero** que el sistema consulte a JEV con etiquetas en inglés y una versión fijada del modelo, por TypeSafe o por Cloudflare, **para** obtener decisiones tipadas con confianza calibrada sin depender de un solo proveedor.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R3 · La IA analiza. D-72: sin Cloudflare como respaldo de JEV (CA-4 queda para la fase siguiente). Habilita HU-047 · Puntaje compuesto y elección de la mejor opción, HU-052 · Opinión de la IA sobre una orden manual.

**Prueba independiente (Independent Test)**: Sin escenario propio en el catálogo de 15 §4. Lo ejercitan E2E-06 y E2E-07.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dadas** las métricas de una candidata, **cuando** se arma el estado, **entonces** contiene solo etiquetas semánticas en inglés (por ejemplo "strong gain") y ninguna cifra ni fecha para comparar.
2. **CA-2** · **Dados** el estado y el contexto, **cuando** los revisa la prueba automática, **entonces** no contienen correos, nombres ni identificadores de personas o de subcuentas.
3. **CA-3** · **Dada** una candidata, **cuando** se consulta a JEV, **entonces** va una sola llamada con todas las preguntas y con `ia.modelo_jev` fijado, y se guarda el `model` que devuelve.
4. **CA-4** (caso borde CB-90) · **Dado** `JEV_PROVEEDOR=cloudflare`, **cuando** se consulta, **entonces** el adaptador usa Cloudflare Workers AI con la misma interfaz. *Fuera de la entrega (D-72): queda para la fase siguiente.*
5. **CA-5** · **Dada** una respuesta 429 o 529, **cuando** ocurre, **entonces** el adaptador reintenta con espera exponencial y, si falla, la candidata se omite; y si JEV no responde en `ia.timeout_jev_seg` segundos, corta la espera.

---

### Casos borde (Edge Cases)

- **CB-89** · TypeSafe cambia `jev-latest`. No afecta: la versión está fijada (`ia.modelo_jev`); pasar a otra versión es un cambio de configuración probado en sombra. (`docs/12` §10; fuente: 07 §5).
- **CB-90** · El acceso a JEV (acceso anticipado) aún no se concede. Se usa el mismo modelo por Cloudflare Workers AI (`JEV_PROVEEDOR=cloudflare`); mientras tanto el desarrollo usa el JEV simulado. (`docs/12` §10; fuente: 07 §5). Lo comprueba CA-4.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-105**: El sistema debe entregar a JEV un estado en inglés compuesto solo por etiquetas semánticas y afirmaciones respaldadas, sin cifras ni fechas para comparar. *(Estado en etiquetas para JEV · actores: Sistema (IA principal) y JEV · fuente: 07 §4.3 · D-40)*
- **FR-106**: El sistema no debe enviar a DeepSeek ni a JEV nombres, correos, identificadores de personas o de subcuentas, montos de cupos ni notas de usuarios, y debe comprobarlo con una prueba automática. *(Sin datos personales hacia las IAs · actores: Sistema · fuente: 07 §4.5 · 07 §12 · 11 §2 · 11 §6)*
- **FR-107**: El sistema debe hacer una llamada a JEV por candidata con todas las preguntas de la configuración activa, con la versión del modelo fijada, por TypeSafe o por Cloudflare según `JEV_PROVEEDOR`, y guardar el modelo que devuelve cada respuesta. *(Consulta a JEV · actores: Sistema (IA principal) y JEV · fuente: 07 §5 · 07 §6.1 · D-43 · CB-89 · CB-90)*
- **FR-108**: Ante una respuesta 429 o 529 de JEV, el sistema debe reintentar con espera exponencial y omitir la candidata si falla; con JEV caído no debe crear sugerencias nuevas y debe mantener órdenes manuales sin opinión, ventas, protecciones y alertas de código. *(Reacción a fallos de JEV · actores: Sistema · fuente: 07 §10 · CB-57)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

- **Configuración de decisión** (`configuraciones_decision`): preguntas a JEV en inglés, cortes de las etiquetas, pesos y umbrales; una sola activa (docs/06 §5.3).
- **Evaluación de candidata** (`evaluaciones_candidatos`): guarda el estado enviado, las respuestas de JEV y el `model` que devolvió.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Contiene solo etiquetas semánticas en inglés (por ejemplo "strong gain") y ninguna cifra ni fecha para comparar (CA-1).
- **SC-002**: No contienen correos, nombres ni identificadores de personas o de subcuentas (CA-2).
- **SC-003**: Va una sola llamada con todas las preguntas y con `ia.modelo_jev` fijado, y se guarda el `model` que devuelve (CA-3).
- **SC-004**: El adaptador reintenta con espera exponencial y, si falla, la candidata se omite; y si JEV no responde en `ia.timeout_jev_seg` segundos, corta la espera (CA-5).

## Supuestos (Assumptions)

- Depende de HU-044 · Calidad de datos, métricas y puntaje cuantitativo: Las etiquetas se derivan de las métricas.
- Depende de TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba: El proveedor de JEV se elige con `_shared/proveedores.ts`.
- Depende de HU-035 · Salud de las integraciones: Registra la salud de `jev`.
- El proveedor se elige con `PROVEEDOR_JEV`: `simulado` en local y CI, `typesafe` en la nube. Sin llave, la evaluación sigue "sin JEV" y lo dice.
- Solo se envían las tres preguntas que no requieren contexto (`entry_timing`, `reversal_risk`, `event_risk`); las de contexto esperan a DeepSeek (D-59).

# Plan: HU-047 · Puntaje compuesto y elección de la mejor opción

**Rama**: `demo-ia-oportunidades` (D-70, #171), cierre en `048-cierre-de-la-ia` (D-72, #196) · **Módulos**: M-07 · **Fuentes**: `docs/07` §6.2, §6.3, §14 · D-41 · D-42.

- **Decisión** (`supabase/functions/_shared/decision.ts`): `evaluar` calcula `wQ·Q + wC·C + wS·S + wT·T + wV·(1−V) + wE·(1−E) + wR·(1−R)` con los pesos del bolsillo y aplica las reglas de 07 §6.3 que no dependen del motor de políticas; `elegirMejor` desempata por confianza y luego por menor volatilidad (CB-86); `nivelDe` da favorable, vigilar o desfavorable (D-72); `armarExplicacion` arma qué, por qué, qué la frena, advertencias y lo que respondió JEV.
- **Guardado** (`private.registrar_evaluaciones`): una fila por candidata en `evaluaciones_candidatos`, con métricas, estado enviado, respuestas de JEV, puntajes, aportes, resultado y explicación.

Decisiones sin regla explícita en `docs/`:
- Sin contexto (D-59), C, S y T valen 0,5 y no explican nada.
- Sin señales (D-65, D-72): la mejor de cada bolsillo queda `elegida` como recomendación.

Pruebas: `deno test _shared/decision_test.ts` (8) y `agente/manejador_test.ts` (nivel y explicación) · E2E-06.

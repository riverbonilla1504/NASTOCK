# Plan: HU-045 · Adaptador de JEV y estado en etiquetas

**Rama**: `demo-ia-oportunidades` (D-70, #171), cierre en `048-cierre-de-la-ia` (D-72, #196) · **Módulos**: M-07 · **Fuentes**: `docs/07` §4.3, §4.5, §5, §6.1, §10 · D-40 · D-43.

- **Adaptador** (`supabase/functions/_shared/ia/`): `jev.ts` elige el proveedor con `PROVEEDOR_JEV` (`_shared/proveedores.ts`); `typesafe.ts` llama `POST /v1/systemone` con todas las preguntas en una llamada, reintenta 429 y 529 con espera exponencial y corta en `ia.timeout_jev_seg`; `simulado.ts` responde de forma determinista según las etiquetas, con escenarios `confianza_baja`, `contradiccion` y `sin_respuesta`; `tipos.ts` valida la respuesta con zod.
- **Estado en etiquetas** (`etiquetas.ts`): lista cerrada de campos (símbolo, sector, etiquetas), sin cifras, fechas ni datos de personas; los cortes salen de la configuración de decisión activa. Con la bolsa cerrada, JEV juzga para la próxima sesión regular (D-72).
- **Configuración** (migración `20261108200000_agente_ciclos_y_evaluaciones.sql`): `configuraciones_decision` v1 con las preguntas en inglés, los cortes, los pesos y los umbrales.

Decisiones sin regla explícita en `docs/`:
- Sin llave, la evaluación sigue "sin JEV" y lo dice; el ciclo no falla.
- Solo se envían las preguntas que no requieren contexto (D-59).

Pruebas: `deno test _shared/ia/jev_test.ts` (9) · E2E-06 (backend).

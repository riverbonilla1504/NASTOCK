# Plan: HU-044 · Calidad de datos, métricas y puntaje cuantitativo

**Rama**: se construyó en `demo-ia-oportunidades` (D-70, #171) y se cerró en `048-cierre-de-la-ia` (D-72, #196) · **Módulos**: M-07 · **Fuentes**: `docs/07` §4.1, §15 · D-38.

- **Funciones** (`supabase/functions/_shared/indicadores.ts`): `verificarCalidad` (menos de 60 barras, última barra distinta de la sesión, valores inválidos, salto de más de ±25 %, precio en vivo de más de 60 s), `calcularMetricas` (rendimientos a 1, 5, 20 y 60 días, volatilidad, ATR y RSI de 14 días, medias de 20, 50 y 200 días, distancia al máximo de 52 semanas, volumen relativo), `puntajesCuantitativos` (Q y percentil de volatilidad) y `elegirCandidatas`.
- **Lecturas de la base** (migración `20261108200000_agente_ciclos_y_evaluaciones.sql`): `private.universo_del_agente`, `private.barras_del_agente(dias)` y `private.cotizaciones_del_agente`, solo para el agente.
- **En el ciclo** (`agente/manejador.ts`, pasos 1 y 2): sin QQQ válido el ciclo queda `omitido` (`qqq_sin_datos`); cada símbolo excluido se guarda con `excluida:<motivo>`.

Decisiones sin regla explícita en `docs/`:
- Con la bolsa cerrada se exige la última barra diaria disponible y no un precio en vivo (D-70, punto 3).
- Usuarios evalúa todos sus símbolos activos; Arriesgadas, las `ia.candidatos_max` mejores por Q. Los símbolos con posición ya están en Usuarios (D-64, D-72).

Pruebas: `deno test _shared/indicadores_test.ts` (11, series con valores calculados a mano) · E2E-07 (`supabase/tests/e2e/07_calidad_de_datos_test.ts`).

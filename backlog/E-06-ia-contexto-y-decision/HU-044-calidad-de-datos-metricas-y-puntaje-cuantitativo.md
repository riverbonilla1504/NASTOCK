# HU-044 · Calidad de datos, métricas y puntaje cuantitativo

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-07 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-07` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** que la IA principal verifique los datos de cada acción y calcule sus métricas antes de analizar,  
**para** que ninguna decisión se base en datos incompletos, viejos o anómalos.

## Requisitos funcionales

- [FR-102 · Verificación de calidad de datos](../requisitos-funcionales/FR-102-verificacion-de-calidad-de-datos.md)
- [FR-103 · Métricas y puntaje cuantitativo](../requisitos-funcionales/FR-103-metricas-y-puntaje-cuantitativo.md)
- [FR-104 · Selección de candidatas](../requisitos-funcionales/FR-104-seleccion-de-candidatas.md)

## Reglas

07 §4.1 · 07 §15 · D-38

## Criterios de aceptación

- **CA-1** Dada una acción con menos de 60 barras diarias, con la última barra distinta de la sesión anterior, con un precio en vivo de más de 60 segundos o con un salto de más de ±25 % sin suspensión informada, cuando se verifica, entonces queda excluida del ciclo con su motivo.
- **CA-2** (caso borde) CB-87: Dado que QQQ falla la verificación, cuando empieza el ciclo, entonces el ciclo completo queda omitido.
- **CA-3** Dado un símbolo con datos válidos, cuando se calculan sus métricas, entonces se obtienen los rendimientos a 1, 5, 20 y 60 días, la volatilidad de 20 y 60 días, el ATR y el RSI de 14 días, la posición frente a las medias de 20, 50 y 200 días, la caída desde el máximo de 52 semanas, el volumen relativo y la regla de tendencia de la v2.
- **CA-4** Dado el universo con sus métricas, cuando se calcula Q, entonces es el percentil de `0,6·ra20 + 0,4·ra60`, con 0,1 de bonificación si está sobre la media de 50 días y tope 1.
- **CA-5** Dado Q, cuando se eligen las candidatas, entonces son las `ia.candidatos_max` mejores de Arriesgadas, todos los símbolos activos de Usuarios y todo símbolo con posición abierta.

## Casos borde

CB-87

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-07.

## Tareas

- [ ] Funciones: `_shared/indicadores.ts` con los controles de calidad, las métricas y el puntaje Q.
- [ ] Selección de candidatas y parámetro `ia.candidatos_max`.
- [ ] Pruebas `deno test` de `indicadores.ts` con series conocidas y valores esperados calculados a mano.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-029 · Barra diaria tras el cierre y retención de barras de minuto](../E-04-datos-de-mercado/HU-029-barra-diaria-tras-el-cierre-y-retencion-de-barras-de-minuto.md) | Usa las barras diarias del universo. |
| Depende de | [HU-028 · Ingesta de precios cada 15 segundos](../E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md) | Usa el precio en vivo y su antigüedad. |
| Habilita | [HU-045 · Adaptador de JEV y estado en etiquetas](HU-045-adaptador-de-jev-y-estado-en-etiquetas.md) | HU-045: las etiquetas se derivan de las métricas. |
| Habilita | [HU-046 · Ciclo del agente: programación, uno a la vez y omisiones](HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) | HU-046: el ciclo empieza por la verificación de calidad. |

## Notas técnicas

Es código determinista: todo lo que hace es reproducible (D-38). La regla de tendencia de la v2 (±2 % en 30 días) pasa a ser una métrica más (05 §11).

## Documentación a actualizar

Ninguna.

## Definición de terminado

Lista de `docs/14` §6, la misma del formulario de historia:

- [ ] Criterios de aceptación y casos borde cumplidos
- [ ] `scripts/verificar.sh` completo en verde (incluye E2E) y CI en verde
- [ ] Escenario E2E agregado o actualizado
- [ ] RLS y pruebas pgTAP si toca datos; escrituras solo por RPC
- [ ] `docs/` actualizada (y historial 13 §4) si cambió una regla
- [ ] `docs/17` actualizado si cambiaron rutas, tablas o funciones
- [ ] Error no trivial registrado en `docs/errores-conocidos.md`
- [ ] Desplegada en el proyecto MVP con la prueba de humo en verde

# HU-047 · Puntaje compuesto y elección de la mejor opción

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
**quiero** que el sistema combine en código los datos y las respuestas de JEV y elija la mejor opción de cada bolsillo solo si supera los umbrales,  
**para** que la decisión sea reproducible y pese el riesgo tanto como la ganancia.

## Requisitos funcionales

- [FR-113 · Puntaje compuesto](../requisitos-funcionales/FR-113-puntaje-compuesto.md)
- [FR-114 · Reglas de decisión de compra](../requisitos-funcionales/FR-114-reglas-de-decision-de-compra.md)
- [FR-115 · Tamaño, stop y objetivo de la señal](../requisitos-funcionales/FR-115-tamano-stop-y-objetivo-de-la-senal.md)
- [FR-116 · Una señal de compra por bolsillo por ciclo](../requisitos-funcionales/FR-116-una-senal-de-compra-por-bolsillo-por-ciclo.md)
- [FR-117 · Señales validadas por el motor de políticas](../requisitos-funcionales/FR-117-senales-validadas-por-el-motor-de-politicas.md)
- [FR-118 · Registro de cada evaluación](../requisitos-funcionales/FR-118-registro-de-cada-evaluacion.md)

## Reglas

07 §3 · 07 §6 · 07 §7.1 · RR-09 · RR-10 · D-41 · Q-21

## Criterios de aceptación

- **CA-1** Dadas las respuestas de JEV de una candidata, cuando se calcula el puntaje, entonces es `wQ·Q + wC·C + wS·S + wT·T + wV·(1−V) + wE·(1−E) + wR·(1−R)` con los pesos del bolsillo, que suman 1.
- **CA-2** Dado un contexto ausente, viejo o con `context_grounded` menor que 0,5, cuando se calcula, entonces C, S y T valen 0,5 y la evaluación queda marcada "sin contexto".
- **CA-3** Dadas varias candidatas elegibles de un bolsillo, cuando se elige, entonces gana la de mayor puntaje; (caso borde) CB-86: en empate gana la de mayor confianza y luego la de menor volatilidad.
- **CA-4** (caso borde) CB-85: Dado que ninguna candidata cumple `buy_now`, confianza, contradicción y puntaje mínimos, cuando termina el ciclo, entonces queda completado sin señales.
- **CA-5** (caso borde) CB-60: Dada una señal viva del mismo símbolo en el bolsillo, cuando vuelve a salir elegida, entonces no se crea otra.
- **CA-6** Dada una señal que viola una regla del motor de políticas, cuando se valida, entonces no se crea y queda en `propuestas_descartadas` con su regla.
- **CA-7** Dado cualquier ciclo, cuando termina, entonces cada candidata tiene su fila en `evaluaciones_candidatos` con métricas, etiquetas, contexto, respuestas de JEV, puntajes, versiones y resultado.

## Casos borde

CB-60, CB-85, CB-86

## Escenario E2E

E2E-07 (nuevo)

## Tareas

- [ ] Migración: tablas `configuraciones_decision`, `evaluaciones_candidatos`, `senales` y `propuestas_descartadas` (06 §5.3) con RLS, y la configuración de decisión v1 activa (preguntas en inglés, cortes de etiquetas, pesos y umbrales de 07 §6).
- [ ] Migración: `private.configuracion_activa()`, `private.registrar_evaluacion(...)`, `private.crear_senal(...)` y `private.registrar_propuesta_descartada(...)`.
- [ ] Funciones: `_shared/decision.ts` con el puntaje compuesto, las reglas de decisión, el desempate y el cálculo de tamaño, stop y objetivo (07 §7.1).
- [ ] Función `agente`: una llamada a JEV por candidata, puntaje, elección por bolsillo, `validar_operacion` y creación de la señal.
- [ ] Migración: parámetros `jev.*`, `ia.pct_base.*`, `ia.stop_atr_multiplo`, `ia.relacion_objetivo_stop` e `ia.horizonte.*`.
- [ ] Pruebas `deno test` de `decision.ts`: puntaje, sin contexto, empate, umbrales y tamaño.
- [ ] E2E-07: una candidata con datos incompletos se excluye y, sin QQQ, el ciclo se omite.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-046 · Ciclo del agente: programación, uno a la vez y omisiones](HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) | La decisión corre dentro del ciclo. |
| Depende de | [HU-045 · Adaptador de JEV y estado en etiquetas](HU-045-adaptador-de-jev-y-estado-en-etiquetas.md) | Usa las respuestas de JEV. |
| Depende de | [HU-043 · Vigencia y regeneración del contexto](HU-043-vigencia-y-regeneracion-del-contexto.md) | Usa el contexto vigente o evalúa sin contexto. |
| Depende de | [HU-037 · Motor de políticas: reglas de la propuesta](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) | Toda señal pasa por `validar_operacion`. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-07. |
| Habilita | [HU-048 · Pantalla Oportunidades con la explicación de cada evaluación](HU-048-pantalla-oportunidades-con-la-explicacion-de-cada-evaluacion.md) | HU-048: muestra las evaluaciones del último ciclo. |
| Habilita | [HU-049 · Alertas de contradicción y de mercado](HU-049-alertas-de-contradiccion-y-de-mercado.md) | HU-049: la contradicción se evalúa al decidir. |
| Habilita | [HU-052 · Opinión de la IA sobre una orden manual](HU-052-opinion-de-la-ia-sobre-una-orden-manual.md) | HU-052: usa la configuración activa y sus preguntas. |
| Habilita | [HU-053 · Señales de venta de posiciones abiertas](HU-053-senales-de-venta-de-posiciones-abiertas.md) | HU-053: extiende las reglas de decisión del ciclo. |
| Habilita | [HU-054 · Versiones del prompt de contexto y de la configuración de decisión](HU-054-versiones-del-prompt-de-contexto-y-de-la-configuracion-de-decision.md) | HU-054: versiona la configuración que usa el ciclo. |
| Habilita | [HU-058 · Sugerencia de compra para Arriesgadas](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md) | HU-058: convierte las señales del ciclo. |
| Habilita | [HU-112 · Retención de datos y vigilancia del tamaño de la base](../E-12-seguridad-auditoria-y-cumplimiento/HU-112-retencion-de-datos-y-vigilancia-del-tamano-de-la-base.md) | HU-112: limpia las evaluaciones de candidatas. |

## Notas técnicas

En R3 las señales se registran para medir a la IA; se convierten en sugerencias desde R4 ([HU-058](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md) y [HU-059](../E-07-sugerencias-y-decisiones/HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md)). Hay como máximo una señal de compra por bolsillo por ciclo. Los pesos y umbrales iniciales se ajustan con datos de R3 (Q-21). Las señales de venta están en [HU-053](HU-053-senales-de-venta-de-posiciones-abiertas.md).

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

# HU-051 · Análisis bajo demanda de un símbolo

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Analista |
| Prioridad | Media |
| Módulos afectados | M-07, M-06 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-07` · `M-06` · `prioridad-media` |

## Historia

**Como** Analista,  
**quiero** pedirle a la IA el análisis de un símbolo de la lista de Arriesgadas,  
**para** evaluar una idea propia con el mismo criterio que usa el sistema.

## Requisitos funcionales

- [FR-124 · Análisis bajo demanda](../requisitos-funcionales/FR-124-analisis-bajo-demanda.md)

## Reglas

PM-22 · 07 §2 · D-21 · Q-05

## Criterios de aceptación

- **CA-1** Dado un Analista, cuando pide el análisis de un símbolo de la lista blanca de Arriesgadas, entonces se genera un contexto fresco y un ciclo con disparador `analisis` que evalúa ese símbolo.
- **CA-2** Dado el análisis terminado, cuando el Analista lo abre, entonces ve la evaluación completa con su explicación.
- **CA-3** Dado un símbolo que no está en la lista blanca de Arriesgadas, cuando se pide, entonces la función lo rechaza.
- **CA-4** (permiso) Dado un Usuario o un Administrador, cuando pide un análisis, entonces recibe `NO_AUTORIZADO`.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Función `agente` en modo análisis: valida el JWT y el rol de Analista, encola el contexto del símbolo y lo evalúa con `simbolo_foco`.
- [ ] App: acción "Analizar" en `lib/features/oportunidades/` para el Analista y vista del resultado.
- [ ] Pruebas `deno test` del modo análisis y de sus permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-048 · Pantalla Oportunidades con la explicación de cada evaluación](HU-048-pantalla-oportunidades-con-la-explicacion-de-cada-evaluacion.md) | El resultado se muestra con la misma explicación. |
| Depende de | [HU-043 · Vigencia y regeneración del contexto](HU-043-vigencia-y-regeneracion-del-contexto.md) | Pide un contexto fresco del símbolo. |

## Notas técnicas

Los analistas no crean órdenes manuales en Arriesgadas: piden análisis (D-21, Q-05). Desde R4, un análisis elegible puede producir una sugerencia con origen `ia_analisis` ([HU-058](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md)).

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

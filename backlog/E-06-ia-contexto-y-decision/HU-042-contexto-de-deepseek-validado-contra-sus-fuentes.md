# HU-042 · Contexto de DeepSeek validado contra sus fuentes

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-06 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-06` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** que DeepSeek explique qué pasa alrededor de cada candidata usando solo las noticias que le entregamos y citando cuáles usó,  
**para** entender el contexto de los números y poder comprobar de dónde sale cada afirmación.

## Requisitos funcionales

- [FR-097 · Generación del contexto con DeepSeek](../requisitos-funcionales/FR-097-generacion-del-contexto-con-deepseek.md)
- [FR-098 · Validación del contexto contra sus fuentes](../requisitos-funcionales/FR-098-validacion-del-contexto-contra-sus-fuentes.md)
- [FR-106 · Sin datos personales hacia las IAs](../requisitos-funcionales/FR-106-sin-datos-personales-hacia-las-ias.md)

## Reglas

07 §4.2 · 07 §12 · 07 §13 · D-37 · D-39 · RSG-16

## Criterios de aceptación

- **CA-1** Dadas las noticias de un símbolo, cuando corre `contexto-ia`, entonces `contextos_ia` guarda un resumen en español, el contexto en inglés con sus afirmaciones y `news_ids`, el modelo, la versión del prompt, los tokens y el costo.
- **CA-2** (caso borde) CB-59: Dada una afirmación que cita una noticia que no se envió, cuando se valida, entonces se elimina; si se elimina más de la mitad, el contexto queda `no_confiable`.
- **CA-3** (caso borde) CB-83: Dado un símbolo sin noticias en la ventana, cuando se genera, entonces el contexto queda `sin_noticias`.
- **CA-4** Dado lo que se envía a DeepSeek, cuando lo revisa la prueba automática, entonces no contiene correos, nombres ni identificadores de personas o de subcuentas.
- **CA-5** (permiso) Dada una llamada a `contexto-ia` sin el secreto interno ni un JWT de Analista o de Administrador, cuando llega, entonces la función la rechaza.

## Casos borde

CB-59, CB-83

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-06.

## Tareas

- [ ] Migración: tablas `prompts_agente` y `contextos_ia` (06 §5.3) con RLS para Analista y Administrador, `private.guardar_contexto(...)` y el prompt de contexto v1 de 07 §13 activo.
- [ ] Funciones: adaptador de contexto en `_shared/ia/` con `deepseek.ts` (modo JSON) y `simulado.ts` (contextos pregrabados, uno de ellos con afirmaciones sin respaldo).
- [ ] Función `contexto-ia`: descarga las noticias, llama a DeepSeek con el prompt activo, valida el esquema con zod y los `news_ids`, y guarda.
- [ ] Migración: parámetros `ia.modelo_contexto` e `ia.timeout_contexto_seg`.
- [ ] Pruebas `deno test` de `contexto-ia`: validación, afirmaciones sin respaldo, sin noticias y ausencia de datos personales.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-041 · Noticias de las candidatas](HU-041-noticias-de-las-candidatas.md) | El contexto se arma con las noticias descargadas. |
| Habilita | [HU-043 · Vigencia y regeneración del contexto](HU-043-vigencia-y-regeneracion-del-contexto.md) | HU-043: decide cuándo sirve y cuándo se regenera el contexto. |
| Habilita | [HU-050 · Presupuesto mensual de IA](HU-050-presupuesto-mensual-de-ia.md) | HU-050: suma el costo de DeepSeek. |
| Habilita | [HU-054 · Versiones del prompt de contexto y de la configuración de decisión](HU-054-versiones-del-prompt-de-contexto-y-de-la-configuracion-de-decision.md) | HU-054: versiona el prompt de contexto. |

## Notas técnicas

`contexto-ia` no importa `_shared/broker/` (invariante). Las instrucciones van primero y las noticias al final para aprovechar la caché de DeepSeek (07 §9). El contexto apoya a los datos y nunca los reemplaza.

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

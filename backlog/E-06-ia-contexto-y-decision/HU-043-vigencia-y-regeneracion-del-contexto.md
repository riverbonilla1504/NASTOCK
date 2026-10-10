# HU-043 · Vigencia y regeneración del contexto

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
**quiero** que el contexto de cada candidata tenga vigencia y se regenere solo,  
**para** que nunca se mezcle un contexto viejo con precios nuevos sin que quede dicho.

## Requisitos funcionales

- [FR-099 · Vigencia del contexto](../requisitos-funcionales/FR-099-vigencia-del-contexto.md)
- [FR-100 · Regeneración programada y a pedido del contexto](../requisitos-funcionales/FR-100-regeneracion-programada-y-a-pedido-del-contexto.md)
- [FR-101 · Tolerancia a fallos de noticias y de DeepSeek](../requisitos-funcionales/FR-101-tolerancia-a-fallos-de-noticias-y-de-deepseek.md)

## Reglas

07 §2 · 07 §4.2 · 07 §10 · 05 §7 · 05 §8 · 08 §6

## Criterios de aceptación

- **CA-1** (caso borde) CB-82: Dado un contexto con más de `ia.contexto_max_minutos` minutos o con noticias más nuevas que él, cuando se consulta `contexto_vigente`, entonces no hay contexto vigente y se encola su regeneración.
- **CA-2** Dado que faltan 30 minutos para la apertura, cuando corre el trabajo de preapertura, entonces se encola el contexto de las candidatas del día una sola vez.
- **CA-3** (caso borde) CB-58: Dado que DeepSeek devuelve una respuesta vacía o un JSON inválido, cuando ocurre, entonces se reintenta una vez; si vuelve a fallar, se conserva el contexto anterior si está vigente o la candidata queda "sin contexto".
- **CA-4** Dado un mensaje de la cola que falla 2 veces, cuando se agotan los reintentos, entonces la candidata sigue "sin contexto" y se alerta.
- **CA-5** (permiso) Dado un Analista o un Administrador, cuando llama `lanzar_contexto(simbolos)`, entonces se encola la regeneración; un Usuario recibe `NO_AUTORIZADO`.

## Casos borde

CB-58, CB-82

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-06.

## Tareas

- [ ] Migración: cola `contexto_por_generar`, `private.contexto_vigente(simbolo)` y `private.encolar_contexto(simbolos)`, y parámetro `ia.contexto_max_minutos`.
- [ ] Migración: trabajos `barrer_contexto` y `contexto_preapertura` de `pg_cron`.
- [ ] RPC `lanzar_contexto(simbolos)` para Analista y Administrador.
- [ ] Función `contexto-ia`: consumo de la cola, un reintento ante un fallo y registro de la salud de `deepseek`.
- [ ] Pruebas: pgTAP de la vigencia con el reloj fijado y `deno test` de los reintentos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-042 · Contexto de DeepSeek validado contra sus fuentes](HU-042-contexto-de-deepseek-validado-contra-sus-fuentes.md) | Decide cuándo sirve y cuándo se regenera el contexto. |
| Depende de | [HU-027 · Calendario, reloj y estado del mercado](../E-04-datos-de-mercado/HU-027-calendario-reloj-y-estado-del-mercado.md) | La preapertura se calcula con el calendario. |
| Habilita | [HU-047 · Puntaje compuesto y elección de la mejor opción](HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | HU-047: usa el contexto vigente o evalúa sin contexto. |
| Habilita | [HU-051 · Análisis bajo demanda de un símbolo](HU-051-analisis-bajo-demanda-de-un-simbolo.md) | HU-051: pide un contexto fresco del símbolo. |
| Habilita | [HU-052 · Opinión de la IA sobre una orden manual](HU-052-opinion-de-la-ia-sobre-una-orden-manual.md) | HU-052: usa el último contexto vigente. |

## Notas técnicas

Estados del contexto: `vigente`, `viejo`, `no_confiable` y `sin_noticias` (08 §6). DeepSeek nunca bloquea el ciclo de decisión (07 §10).

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

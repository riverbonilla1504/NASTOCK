# HU-055 · Modo sombra de una configuración candidata

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-07 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-07` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** correr una configuración candidata en sombra, en paralelo con la activa,  
**para** comparar sus resultados con datos reales antes de activarla.

## Requisitos funcionales

- [FR-131 · Modo sombra](../requisitos-funcionales/FR-131-modo-sombra.md)

## Reglas

PM-59 · 07 §11 · 08 §6

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando llama `poner_en_sombra(id)`, entonces esa configuración pasa a sombra y solo puede haber una en sombra.
- **CA-2** Dada una configuración en sombra, cuando corre un ciclo, entonces las mismas candidatas se evalúan también con ella y sus filas quedan con `es_sombra = true`.
- **CA-3** Dada una evaluación en sombra, cuando elige una candidata, entonces no se crea señal, sugerencia ni alerta.
- **CA-4** Dadas al menos 10 sesiones en sombra, cuando se consulta el desempeño, entonces se puede comparar la sombra con la activa por versión.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `poner_en_sombra(id)`, y `private.configuracion_activa()` devolviendo también la de sombra.
- [ ] Función `agente`: segunda evaluación con la configuración en sombra, sin publicar nada.
- [ ] Pruebas `deno test` (la sombra no publica) y pgTAP de los estados.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-054 · Versiones del prompt de contexto y de la configuración de decisión](HU-054-versiones-del-prompt-de-contexto-y-de-la-configuracion-de-decision.md) | La sombra es un estado de una versión de configuración. |
| Habilita | [HU-106 · Pantalla de prompts y configuraciones de decisión](../E-11-administracion/HU-106-pantalla-de-prompts-y-configuraciones-de-decision.md) | HU-106: pone una configuración en sombra. |

## Notas técnicas

Como JEV cuesta casi nada, correr la sombra es barato (07 §11). La comparación se ve en [HU-057](HU-057-desempeno-y-calibracion-de-la-ia.md).

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

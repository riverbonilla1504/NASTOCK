# HU-052 · Opinión de la IA sobre una orden manual

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-07 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-07` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** conocer la opinión de la IA antes de enviar mi orden manual,  
**para** decidir con más información, sin que la IA decida por mí.

## Requisitos funcionales

- [FR-125 · Opinión sobre una orden manual](../requisitos-funcionales/FR-125-opinion-sobre-una-orden-manual.md)
- [FR-126 · La opinión no bloquea la orden](../requisitos-funcionales/FR-126-la-opinion-no-bloquea-la-orden.md)

## Reglas

07 §8 · 08 §7.5 · D-15

## Criterios de aceptación

- **CA-1** Dado un Usuario que arma una orden en su cupo, cuando pide la opinión, entonces recibe en menos de 1 segundo un veredicto favorable, neutral o desfavorable con su confianza, sus banderas y un comentario armado por el código.
- **CA-2** Dada una orden que viola una regla de riesgo, cuando se pide la opinión, entonces la respuesta indica la regla violada.
- **CA-3** (caso borde) CB-57: Dado que JEV no responde en `ia.timeout_jev_seg` segundos, cuando se pide la opinión, entonces el veredicto es `sin_opinion` y el Usuario puede continuar.
- **CA-4** Dado un veredicto desfavorable, cuando el Usuario decide seguir, entonces puede enviar la orden: la opinión no bloquea.
- **CA-5** (permiso) Dado un Usuario que pide la opinión sobre el cupo de otra persona, cuando llama `opinion-ia`, entonces recibe `NO_AUTORIZADO`.

## Casos borde

CB-57

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-11.

## Tareas

- [ ] Migración: tipos `veredicto_opinion` y `lado` (si aún no existe) y tabla `opiniones_ia` (06 §5.3) con RLS: las propias y, para los supervisores, todas.
- [ ] Función `opinion-ia`: verifica el JWT y que el cupo es de quien llama, corre `validar_operacion`, arma el estado con el último contexto vigente, consulta a JEV (`entry_timing` o `exit_timing` según el lado) y guarda la opinión.
- [ ] Veredicto, banderas (contradicción, evento próximo, riesgo de reversión alto y sin contexto) y comentario en español armado por el código.
- [ ] Pruebas `deno test` de `opinion-ia`: veredictos, tiempo de espera, regla violada y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-047 · Puntaje compuesto y elección de la mejor opción](HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | Usa la configuración activa y sus preguntas. |
| Depende de | [HU-045 · Adaptador de JEV y estado en etiquetas](HU-045-adaptador-de-jev-y-estado-en-etiquetas.md) | Consulta a JEV con el mismo adaptador. |
| Depende de | [HU-043 · Vigencia y regeneración del contexto](HU-043-vigencia-y-regeneracion-del-contexto.md) | Usa el último contexto vigente. |
| Depende de | [HU-037 · Motor de políticas: reglas de la propuesta](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) | Corre `validar_operacion` antes de opinar. |
| Habilita | [HU-075 · Crear una orden manual en mi cupo](../E-08-ejecucion-y-broker/HU-075-crear-una-orden-manual-en-mi-cupo.md) | HU-075: muestra la opinión de la IA antes de confirmar. |

## Notas técnicas

`opinion-ia` no importa `_shared/broker/` (invariante). No espera a DeepSeek: usa el último contexto vigente. La pantalla que la muestra es la de la orden manual ([HU-075](../E-08-ejecucion-y-broker/HU-075-crear-una-orden-manual-en-mi-cupo.md)).

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

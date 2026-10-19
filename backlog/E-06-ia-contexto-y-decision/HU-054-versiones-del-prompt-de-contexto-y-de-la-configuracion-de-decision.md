# HU-054 · Versiones del prompt de contexto y de la configuración de decisión

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-07, M-06 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-07` · `M-06` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** crear versiones nuevas del prompt de contexto y de la configuración de decisión y activar la que elija,  
**para** ajustar la IA con datos y volver a la versión anterior si algo empeora.

## Requisitos funcionales

- [FR-128 · Versiones del prompt de contexto](../requisitos-funcionales/FR-128-versiones-del-prompt-de-contexto.md)
- [FR-129 · Versiones de la configuración de decisión](../requisitos-funcionales/FR-129-versiones-de-la-configuracion-de-decision.md)
- [FR-130 · Modelos de la lista permitida](../requisitos-funcionales/FR-130-modelos-de-la-lista-permitida.md)

## Reglas

PM-59 · 07 §5 · 07 §11 · 08 §6 · 15 §9 · D-43

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando crea un prompt de contexto y lo activa, entonces queda exactamente un prompt activo, el anterior se conserva y se registran `prompt.creado` y `prompt.activado`.
- **CA-2** Dada una configuración nueva cuyos pesos no suman 1, cuando se intenta crear, entonces la función la rechaza.
- **CA-3** Dada una configuración en borrador o en sombra, cuando el Administrador la activa, entonces pasa a activa y la anterior a retirada: siempre hay exactamente una activa.
- **CA-4** (caso borde) CB-63: Dada una versión activa defectuosa, cuando el Administrador reactiva la anterior, entonces vuelve a ser la activa: ninguna versión se borra.
- **CA-5** (caso borde) CB-79: Dado un modelo que no está en la lista permitida, cuando se intenta poner en `ia.modelo_contexto` o en `ia.modelo_jev`, entonces el cambio se rechaza.
- **CA-6** (permiso) Dado un Analista, cuando llama una de estas funciones, entonces recibe `NO_AUTORIZADO`; puede leer las versiones.

## Casos borde

CB-63, CB-79

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `crear_prompt(proposito, texto, esquema, notas)` y `activar_prompt(id)`.
- [ ] RPC `crear_configuracion(preguntas, etiquetas, pesos, umbrales, notas)` y `activar_configuracion(id)` con la validación de los pesos y la transición de estados de 08 §6.
- [ ] Validación de la lista permitida de modelos en `actualizar_parametro`.
- [ ] Auditoría y pruebas pgTAP: una sola activa, pesos, reactivar una anterior y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-047 · Puntaje compuesto y elección de la mejor opción](HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | Versiona la configuración que usa el ciclo. |
| Depende de | [HU-042 · Contexto de DeepSeek validado contra sus fuentes](HU-042-contexto-de-deepseek-validado-contra-sus-fuentes.md) | Versiona el prompt de contexto. |
| Depende de | [HU-033 · Parámetros configurables con rango e historial](../E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md) | Los modelos se cambian como parámetros. |
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Registra `prompt.creado` y `prompt.activado`. |
| Habilita | [HU-055 · Modo sombra de una configuración candidata](HU-055-modo-sombra-de-una-configuracion-candidata.md) | HU-055: la sombra es un estado de una versión de configuración. |
| Habilita | [HU-106 · Pantalla de prompts y configuraciones de decisión](../E-11-administracion/HU-106-pantalla-de-prompts-y-configuraciones-de-decision.md) | HU-106: crea y activa versiones. |

## Notas técnicas

Cada evaluación guarda la versión que usó. La pantalla está en [HU-106](../E-11-administracion/HU-106-pantalla-de-prompts-y-configuraciones-de-decision.md).

## Documentación a actualizar

11 §4.1 solo nombra `prompt.creado` y `prompt.activado`: no hay acciones de auditoría para crear, poner en sombra o activar una configuración de decisión. Precisarlo en `docs/`.

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

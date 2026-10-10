# HU-106 · Pantalla de prompts y configuraciones de decisión

| Campo | Valor |
|---|---|
| Épica | [E-11 · Administración](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-16, M-07 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-11` · `M-16` · `M-07` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** ver y gestionar las versiones del prompt de contexto y de la configuración de decisión,  
**para** ajustar la IA sin desplegar código y con rastro de cada cambio.

## Requisitos funcionales

- [FR-217 · Pantalla de prompts y configuraciones](../requisitos-funcionales/FR-217-pantalla-de-prompts-y-configuraciones.md)

## Reglas

PM-59 · 07 §11 · 07 §13 · 05 §9.1

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando abre Prompts, entonces ve las versiones del prompt de contexto y de la configuración de decisión con su estado (borrador, sombra, activa o retirada), su autor y su fecha.
- **CA-2** Dada una versión, cuando la abre, entonces ve su contenido: el texto del prompt, o las preguntas, los cortes de etiquetas, los pesos y los umbrales.
- **CA-3** Dado el formulario, cuando crea una versión, la pone en sombra o la activa, entonces la app pide confirmación y muestra el resultado.
- **CA-4** (permiso) Dado un Analista, cuando abre las configuraciones en la sección de IA, entonces las ve en solo lectura.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: pantalla de versiones en `lib/features/admin/` y vista de solo lectura en `lib/features/ia/`.
- [ ] App: formularios para crear, poner en sombra y activar, con confirmación.
- [ ] Pruebas de widget por rol.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-097 · Sección de Administración y guía de primeros pasos](HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) | Es una entrada de la sección de Administración. |
| Depende de | [HU-054 · Versiones del prompt de contexto y de la configuración de decisión](../E-06-ia-contexto-y-decision/HU-054-versiones-del-prompt-de-contexto-y-de-la-configuracion-de-decision.md) | Crea y activa versiones. |
| Depende de | [HU-055 · Modo sombra de una configuración candidata](../E-06-ia-contexto-y-decision/HU-055-modo-sombra-de-una-configuracion-candidata.md) | Pone una configuración en sombra. |

## Notas técnicas

Sin notas adicionales.

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

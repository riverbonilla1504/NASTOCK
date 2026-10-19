# HU-103 · Pantalla de salud e integraciones

| Campo | Valor |
|---|---|
| Épica | [E-11 · Administración](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-16, M-18 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-11` · `M-16` · `M-18` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** ver el estado de cada integración en una pantalla,  
**para** saber de un vistazo si el sistema puede operar.

## Requisitos funcionales

- [FR-214 · Pantalla de salud e integraciones](../requisitos-funcionales/FR-214-pantalla-de-salud-e-integraciones.md)

## Reglas

PM-34 · 05 §13 · 08 §6

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando abre Salud e integraciones, entonces ve cada integración (Alpaca trading, Alpaca datos, Alpaca noticias, DeepSeek, JEV y FCM) con su estado, su último éxito, su último fallo y su último error.
- **CA-2** Dado un cambio de estado, cuando ocurre, entonces la pantalla se actualiza con el evento `salud`.
- **CA-3** (aislamiento) Dado un Analista, cuando consulta `salud_integraciones`, entonces la lee, pero no puede modificarla.
- **CA-4** (permiso) Dado un Usuario, cuando consulta `salud_integraciones`, entonces no recibe filas.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: `lib/features/admin/salud/` con el estado de cada integración.
- [ ] App: actualización con el evento `salud` del canal `supervision`.
- [ ] Pruebas de widget de cada estado.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-097 · Sección de Administración y guía de primeros pasos](HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) | Es una entrada de la sección de Administración. |
| Depende de | [HU-035 · Salud de las integraciones](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) | Muestra la salud que registra el sistema. |
| Habilita | [HU-104 · Pantalla de conciliaciones](HU-104-pantalla-de-conciliaciones.md) | HU-104: vive junto a la pantalla de salud. |

## Notas técnicas

Sin notas adicionales.

## Documentación a actualizar

PM-34 da al Analista lectura de la salud y de las conciliaciones, pero 03 §3 solo las muestra dentro de Administración, que el Analista no tiene. Precisar en `docs/` en qué pantalla las ve.

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

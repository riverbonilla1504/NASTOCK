# HU-105 · Pantalla de rebalanceos

| Campo | Valor |
|---|---|
| Épica | [E-11 · Administración](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-16, M-04 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-11` · `M-16` · `M-04` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** ver el peso de cada bolsillo y las propuestas de rebalanceo y decidirlas,  
**para** mantener el fondo cerca de sus porcentajes objetivo.

## Requisitos funcionales

- [FR-216 · Pantalla de rebalanceos](../requisitos-funcionales/FR-216-pantalla-de-rebalanceos.md)

## Reglas

PM-43 · RN-33 · 02 §8

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando abre Rebalanceos, entonces ve el peso actual y el peso objetivo de cada bolsillo y las sugerencias de rebalanceo con sus transferencias y su explicación.
- **CA-2** Dada una sugerencia pendiente, cuando la aprueba o la rechaza tras la confirmación, entonces ve el resultado y los pesos actualizados.
- **CA-3** Dada una propuesta parcial, cuando se muestra, entonces explica por qué no llega al objetivo.
- **CA-4** (permiso) Dado un Usuario o un Analista, cuando abre esta pantalla, entonces el enrutador lo lleva a `/inicio`.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: pantalla de rebalanceos en `lib/features/admin/` con los pesos y las sugerencias.
- [ ] App: aprobar y rechazar con confirmación, y actualización con el evento `rebalanceo`.
- [ ] Pruebas de widget de la pantalla y de las decisiones.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-097 · Sección de Administración y guía de primeros pasos](HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) | Es una entrada de la sección de Administración. |
| Depende de | [HU-071 · Aprobar o rechazar un rebalanceo](../E-07-sugerencias-y-decisiones/HU-071-aprobar-o-rechazar-un-rebalanceo.md) | Decide las sugerencias de rebalanceo. |

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

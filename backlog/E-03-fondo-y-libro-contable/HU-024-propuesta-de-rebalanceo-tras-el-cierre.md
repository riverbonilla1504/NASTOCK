# HU-024 · Propuesta de rebalanceo tras el cierre

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-04 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-04` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** que el sistema me proponga un rebalanceo cuando un bolsillo se aleja de su peso objetivo,  
**para** mantener el fondo cerca del 50/25/25 sin vigilarlo a mano.

## Requisitos funcionales

- [FR-059 · Propuesta de rebalanceo](../requisitos-funcionales/FR-059-propuesta-de-rebalanceo.md)

## Reglas

RN-33 · RN-34 · RN-35 · 02 §8

## Criterios de aceptación

- **CA-1** Dado un fondo con Reserva 54 %, Arriesgadas 19 % y Usuarios 27 %, cuando corre el cierre diario, entonces se crea una sugerencia de rebalanceo "Mover 600,00 de Reserva a Arriesgadas" para el Administrador, y Usuarios no se toca por estar dentro de la tolerancia.
- **CA-2** Dado que ningún bolsillo se desvía más de `rebalanceo.desviacion_pp` puntos, cuando corre el cierre, entonces no se crea ninguna sugerencia.
- **CA-3** Dado que el efectivo disponible no alcanza para llegar al objetivo, cuando se propone, entonces la sugerencia trae el movimiento parcial posible y lo explica.
- **CA-4** Dada una propuesta, cuando se calcula, entonces solo mueve efectivo disponible entre `reserva`, `arriesgadas` y `usuarios_comun`: nunca vende posiciones ni toca cupos individuales.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: `private.proponer_rebalanceo()`, que crea la sugerencia de tipo `rebalanceo` con `decide_rol = administrador` y las transferencias en `detalle`.
- [ ] Función `cierre-diario`: llama `proponer_rebalanceo` después de la foto de patrimonio.
- [ ] Migración: parámetro `rebalanceo.desviacion_pp`.
- [ ] Pruebas pgTAP: desviación, tolerancia, propuesta parcial y exclusión de cupos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-021 · Foto diaria de patrimonio y rendimiento TWR](HU-021-foto-diaria-de-patrimonio-y-rendimiento-twr.md) | Usa el patrimonio por bolsillo tras el cierre. |
| Depende de | [HU-058 · Sugerencia de compra para Arriesgadas](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md) | La propuesta se guarda en la tabla `sugerencias`. |
| Habilita | [HU-071 · Aprobar o rechazar un rebalanceo](../E-07-sugerencias-y-decisiones/HU-071-aprobar-o-rechazar-un-rebalanceo.md) | HU-071: decide la propuesta del sistema. |

## Notas técnicas

La decisión del Administrador está en [HU-071](../E-07-sugerencias-y-decisiones/HU-071-aprobar-o-rechazar-un-rebalanceo.md) y la pantalla en [HU-105](../E-11-administracion/HU-105-pantalla-de-rebalanceos.md). El peso se calcula sobre el patrimonio del fondo, no sobre el efectivo.

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

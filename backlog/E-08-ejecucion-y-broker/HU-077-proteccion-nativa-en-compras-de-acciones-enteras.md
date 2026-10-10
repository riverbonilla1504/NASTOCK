# HU-077 · Protección nativa en compras de acciones enteras

| Campo | Valor |
|---|---|
| Épica | [E-08 · Ejecución y broker](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-11, M-10 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-08` · `M-11` · `M-10` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** que mi compra de acciones enteras quede protegida en el broker con stop-loss y take-profit,  
**para** que mi posición esté protegida aunque la plataforma se caiga.

## Requisitos funcionales

- [FR-172 · Protección nativa](../requisitos-funcionales/FR-172-proteccion-nativa.md)
- [FR-173 · Venta de una posición con protección nativa](../requisitos-funcionales/FR-173-venta-de-una-posicion-con-proteccion-nativa.md)
- [FR-175 · Protecciones sin aprobación ni freno](../requisitos-funcionales/FR-175-protecciones-sin-aprobacion-ni-freno.md)

## Reglas

RN-21 · RR-08 · 08 §3 · 08 §7.4 · 10 §5 · 10 §6 · D-09 · D-25

## Criterios de aceptación

- **CA-1** Dada una compra bracket llena, cuando se aplica el llenado, entonces existe una protección `nativa` activa con el stop y el objetivo calculados sobre el precio de referencia y con los ids de sus patas en el broker.
- **CA-2** Dado que el precio toca el objetivo, cuando el broker llena esa pata, entonces la sincronización lo detecta, se aplica la venta, la posición queda cerrada, la protección `disparada` y el dueño recibe `proteccion_disparada`.
- **CA-3** (caso borde) CB-43: Dado que el mercado abre por debajo del stop, cuando se ejecuta, entonces se vende al precio disponible y se informa la diferencia.
- **CA-4** (caso borde) CB-46: Dado un dueño suspendido o `trading_activo` apagado, cuando se dispara la protección, entonces se vende igual y el dinero vuelve a su cupo.
- **CA-5** Dada una venta sugerida o manual de una posición con protección nativa, cuando se envía, entonces primero se cancelan sus patas en el broker, se espera la confirmación y luego se envía la venta.
- **CA-6** Dada una compra que no se llenó, cuando termina la orden, entonces su protección queda `cancelada`.

## Casos borde

CB-43, CB-46

## Escenario E2E

E2E-08 (actualizado)

## Tareas

- [ ] Migración: en la aprobación y en `private.aplicar_llenado`, protección `pendiente` al aprobar la compra, `activa` al llenarse y `cancelada` si no se llenó, con `broker_stop_id` y `broker_objetivo_id`.
- [ ] Función `sincronizar-ordenes`: detección de las patas llenadas con la consulta anidada, orden de venta con origen `proteccion` y protección `disparada`.
- [ ] Función `ejecutor-ordenes`: cancelación de las patas antes de una venta por otra vía.
- [ ] Notificación `proteccion_disparada`, auditoría `proteccion.disparada` y eventos `proteccion` y `posicion`.
- [ ] Pruebas pgTAP `protecciones_*` y `deno test` con el broker simulado: objetivo, stop y venta por otra vía.
- [ ] E2E-08 actualizado: protección activa → venta por objetivo.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | La protección se activa al aplicar el llenado de la compra. |
| Habilita | [HU-038 · Motor de políticas completo en los cuatro momentos](../E-05-motor-de-politicas-y-configuracion/HU-038-motor-de-politicas-completo-en-los-cuatro-momentos.md) | HU-038: RR-15 y RR-20 miran posiciones y ventas por stop. |
| Habilita | [HU-070 · Aprobar las ventas de liquidación](../E-07-sugerencias-y-decisiones/HU-070-aprobar-las-ventas-de-liquidacion.md) | HU-070: cancela las patas de la protección antes de vender. |
| Habilita | [HU-079 · Ajustar el stop y el objetivo de una posición](HU-079-ajustar-el-stop-y-el-objetivo-de-una-posicion.md) | HU-079: ajusta las patas de la protección nativa. |
| Habilita | [HU-082 · Renovar las protecciones nativas a los 80 días](HU-082-renovar-las-protecciones-nativas-a-los-80-dias.md) | HU-082: renueva las patas de la protección nativa. |
| Habilita | [HU-091 · Ver mis posiciones y sus protecciones](../E-10-cartera-y-reportes/HU-091-ver-mis-posiciones-y-sus-protecciones.md) | HU-091: muestra la protección de cada posición. |

## Notas técnicas

Una protección disparada no pide aprobación: se aprobó junto con la compra (D-09). Las patas apartan acciones en Alpaca: por eso hay que cancelarlas antes de vender (10 §3).

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

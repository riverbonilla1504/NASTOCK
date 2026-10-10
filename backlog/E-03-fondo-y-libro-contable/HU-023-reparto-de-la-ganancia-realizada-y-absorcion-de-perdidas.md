# HU-023 · Reparto de la ganancia realizada y absorción de pérdidas

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-04, M-10 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-04` · `M-10` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** que la ganancia de cada venta de mi cupo se reparta sola 50/25/25 y que mi parte vuelva a mi cupo,  
**para** que el resultado de mis decisiones se refleje en mi cupo y en el fondo según las reglas de RiTech.

## Requisitos funcionales

- [FR-057 · Reparto de la ganancia realizada](../requisitos-funcionales/FR-057-reparto-de-la-ganancia-realizada.md)
- [FR-058 · Costo y pérdida de una venta](../requisitos-funcionales/FR-058-costo-y-perdida-de-una-venta.md)

## Reglas

RN-26 · RN-27 · RN-28 · RN-29 · RN-30 · D-03 · D-04 · D-19 · Q-01

## Criterios de aceptación

- **CA-1** Dada una venta en un cupo con costo 110,20 y recibido 123,20, cuando se aplica el llenado, entonces el cupo recibe 123,20, `resultados` registra −13,00 y el reparto mueve 6,50 a la Reserva y 3,25 a Arriesgadas, dejando 3,25 en el cupo.
- **CA-2** Dada una venta con ganancia en Arriesgadas, cuando se aplica el llenado, entonces el 25 % de Usuarios va a `usuarios_comun`.
- **CA-3** Dada una venta con pérdida (costo 110,20 y recibido 103,40), cuando se aplica el llenado, entonces la subcuenta absorbe los 6,80 completos y no hay reparto.
- **CA-4** (caso borde) CB-18: Dada una ganancia de 0,03, cuando se reparte, entonces Arriesgadas recibe 0,00, el cupo 0,00 y la Reserva 0,03.
- **CA-5** (caso borde) CB-17: Dado un cambio de porcentajes con una venta en curso, cuando la venta se llena, entonces el reparto usa los porcentajes vigentes al llenarse y los guarda en el movimiento.

## Casos borde

CB-17, CB-18, CB-19

## Escenario E2E

E2E-08 (actualizado)

## Tareas

- [ ] Migración: dentro de `private.aplicar_llenado`, movimiento `venta` (el costo vuelve a la subcuenta y la contrapartida va a `resultados`) y movimiento `reparto_ganancia` con RN-26 y RN-30.
- [ ] Pruebas pgTAP `reparto_*`: cupo, Arriesgadas, pérdida, centavos y porcentajes vigentes.
- [ ] E2E-08 actualizado: venta por objetivo con el reparto visible en los tres bolsillos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | El reparto ocurre dentro de `private.aplicar_llenado`. |
| Habilita | [HU-070 · Aprobar las ventas de liquidación](../E-07-sugerencias-y-decisiones/HU-070-aprobar-las-ventas-de-liquidacion.md) | HU-070: reparte la ganancia de la venta. |
| Habilita | [HU-093 · Ver el historial de operaciones](../E-10-cartera-y-reportes/HU-093-ver-el-historial-de-operaciones.md) | HU-093: el historial incluye los repartos de ganancia. |

## Notas técnicas

El reparto es por operación cerrada, no neto por periodo (D-19, pendiente de validar en Q-01): un cupo que pierde y luego gana termina con menos (CB-19). 14 §4 ubica E-03 en R2, pero esta historia solo se puede probar de punta a punta con ventas, que llegan en R4.

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

# HU-074 · Sincronizar órdenes y aplicar llenados

| Campo | Valor |
|---|---|
| Épica | [E-08 · Ejecución y broker](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-10, M-11 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-08` · `M-10` · `M-11` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** que cada llenado de mi orden se refleje en mi cupo y en mi posición sin que yo haga nada,  
**para** ver lo que realmente compré o vendí y a qué precio.

## Requisitos funcionales

- [FR-165 · Sincronización de órdenes](../requisitos-funcionales/FR-165-sincronizacion-de-ordenes.md)
- [FR-166 · Aplicación de llenados](../requisitos-funcionales/FR-166-aplicacion-de-llenados.md)
- [FR-167 · Tiempo máximo de llenado](../requisitos-funcionales/FR-167-tiempo-maximo-de-llenado.md)
- [FR-168 · Cierre de la orden y de su sugerencia](../requisitos-funcionales/FR-168-cierre-de-la-orden-y-de-su-sugerencia.md)

## Reglas

RN-06 · RN-25 · 08 §2 · 08 §3 · 10 §7 · 02 §6.2 · 02 §7.1

## Criterios de aceptación

- **CA-1** Dada una compra aceptada que el broker llena por 1 acción a 110,20, cuando corre la sincronización, entonces el libro registra efectivo −110,20 e invertido +110,20, se crea la posición con costo promedio 110,20, se libera la retención y la sugerencia pasa a `ejecutada`.
- **CA-2** Dado el mismo llenado informado dos veces, cuando se aplica otra vez, entonces no cambia nada.
- **CA-3** Dada una posición de 6 acciones a 50,00, cuando se llenan 4 más a 60,00, entonces queda en 10 acciones con costo promedio 54,00; una venta no cambia el costo promedio de lo que queda.
- **CA-4** (caso borde) CB-35: Dada una compra que no se llena en `ejecucion.minutos_max_llenado` minutos, cuando se cumple el tiempo, entonces se cancela, la sugerencia queda `fallida` y se libera la retención.
- **CA-5** (caso borde) CB-34: Dado un llenado parcial y luego la cancelación o el vencimiento, cuando termina la orden, entonces la sugerencia queda `ejecutada_parcial`, el libro y la posición reflejan lo llenado y se libera el resto de la retención.
- **CA-6** (caso borde) CB-38: Dado el cierre del mercado con una orden `day` viva, cuando el broker la vence, entonces queda `vencida` y lo llenado se conserva.

## Casos borde

CB-34, CB-35, CB-38, CB-39

## Escenario E2E

E2E-08 (actualizado)

## Tareas

- [ ] Migración: tipos `estado_posicion`, `tipo_proteccion` y `estado_proteccion`, tablas `posiciones` y `protecciones` (06 §5.4) con RLS, y vista `posiciones_valoradas` (`security_invoker`).
- [ ] Migración: `private.aplicar_llenado(orden_id, cantidad_total, precio_promedio, estado_broker, comisiones)`: aplica la diferencia al libro (movimientos `compra` y `venta`), a la posición y a la retención, y cierra la orden y su sugerencia.
- [ ] Función `sincronizar-ordenes`: pasos de 10 §7, correspondencia de estados de 08 §2.1, cancelación por tiempo máximo y consulta de las órdenes `desconocida`.
- [ ] Migración: trabajo `sincronizar_ordenes` de `pg_cron` cada 10 segundos si hay órdenes vivas, y parámetro `ejecucion.minutos_max_llenado`.
- [ ] Notificaciones `orden_ejecutada` y `orden_fallida` y eventos `orden`, `posicion` y `cupo`.
- [ ] Pruebas pgTAP `llenados_*` (diferencias, idempotencia, costo promedio y parcial) y `deno test` de `sincronizar-ordenes`.
- [ ] E2E-08 actualizado: llenado → posición.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-073 · Enviar al broker las órdenes aprobadas](HU-073-enviar-al-broker-las-ordenes-aprobadas.md) | Sincroniza las órdenes que envía el ejecutor. |
| Habilita | [HU-023 · Reparto de la ganancia realizada y absorción de pérdidas](../E-03-fondo-y-libro-contable/HU-023-reparto-de-la-ganancia-realizada-y-absorcion-de-perdidas.md) | HU-023: el reparto ocurre dentro de `private.aplicar_llenado`. |
| Habilita | [HU-053 · Señales de venta de posiciones abiertas](../E-06-ia-contexto-y-decision/HU-053-senales-de-venta-de-posiciones-abiertas.md) | HU-053: evalúa las posiciones abiertas. |
| Habilita | [HU-056 · Evaluación de sugerencias y candidatas tras el cierre](../E-06-ia-contexto-y-decision/HU-056-evaluacion-de-sugerencias-y-candidatas-tras-el-cierre.md) | HU-056: toma del libro el rendimiento real de las ejecutadas. |
| Habilita | [HU-067 · Invalidación por precio y por cambio de situación](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md) | HU-067: invalida la venta cuando la posición ya se cerró. |
| Habilita | [HU-069 · Solicitar la liquidación de un cupo](../E-07-sugerencias-y-decisiones/HU-069-solicitar-la-liquidacion-de-un-cupo.md) | HU-069: liquida las posiciones abiertas del cupo. |
| Habilita | [HU-076 · Ver mis órdenes y cancelar una que no se ha llenado](HU-076-ver-mis-ordenes-y-cancelar-una-que-no-se-ha-llenado.md) | HU-076: una orden ya llena no se cancela. |
| Habilita | [HU-077 · Protección nativa en compras de acciones enteras](HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) | HU-077: la protección se activa al aplicar el llenado de la compra. |
| Habilita | [HU-078 · Protección virtual en compras fraccionales](HU-078-proteccion-virtual-en-compras-fraccionales.md) | HU-078: la protección se activa al aplicar el llenado de la compra. |
| Habilita | [HU-080 · Conciliación completa con pausa automática](HU-080-conciliacion-completa-con-pausa-automatica.md) | HU-080: compara posiciones y órdenes del libro. |
| Habilita | [HU-091 · Ver mis posiciones y sus protecciones](../E-10-cartera-y-reportes/HU-091-ver-mis-posiciones-y-sus-protecciones.md) | HU-091: muestra las posiciones que crean los llenados. |
| Habilita | [HU-092 · Ver el detalle del fondo](../E-10-cartera-y-reportes/HU-092-ver-el-detalle-del-fondo.md) | HU-092: muestra posiciones y órdenes. |
| Habilita | [HU-093 · Ver el historial de operaciones](../E-10-cartera-y-reportes/HU-093-ver-el-historial-de-operaciones.md) | HU-093: el historial incluye compras, ventas y órdenes. |

## Notas técnicas

El estado crudo del broker se guarda siempre en `ordenes.broker_estado` y en `ordenes_eventos`. La protección de la compra está en [HU-077](HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) y [HU-078](HU-078-proteccion-virtual-en-compras-fraccionales.md); el reparto de la ganancia de una venta, en [HU-023](../E-03-fondo-y-libro-contable/HU-023-reparto-de-la-ganancia-realizada-y-absorcion-de-perdidas.md). Un activo en halt no se llena y se cancela por tiempo máximo (CB-39).

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

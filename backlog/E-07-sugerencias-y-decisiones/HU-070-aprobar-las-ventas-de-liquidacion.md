# HU-070 · Aprobar las ventas de liquidación

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Analista |
| Prioridad | Media |
| Módulos afectados | M-09, M-10 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `M-10` · `prioridad-media` |

## Historia

**Como** Analista,  
**quiero** aprobar o rechazar cada venta de liquidación de un cupo,  
**para** que la salida de un empleado se ejecute con control de riesgo.

## Requisitos funcionales

- [FR-156 · Decisión de las ventas de liquidación](../requisitos-funcionales/FR-156-decision-de-las-ventas-de-liquidacion.md)

## Reglas

PM-24 · RR-14 · 08 §6 · 08 §7.7 · 10 §5

## Criterios de aceptación

- **CA-1** Dada una sugerencia de liquidación, cuando un Analista la aprueba, entonces se crea una orden de venta a mercado por toda la posición, con origen `liquidacion`.
- **CA-2** Dada la venta llena, cuando se aplica, entonces el efectivo entra al cupo con el reparto normal si hubo ganancia.
- **CA-3** Dado `trading_activo` apagado, cuando un Analista aprueba una liquidación, entonces se ejecuta igual.
- **CA-4** Dadas todas las posiciones vendidas, cuando se consulta el cupo, entonces queda sin posiciones ni órdenes vivas, listo para la baja.
- **CA-5** (permiso) Dado un Administrador o un Usuario, cuando intenta aprobar una liquidación, entonces recibe `NO_AUTORIZADO`.

## Casos borde

—

## Escenario E2E

E2E-16 (actualizado)

## Tareas

- [ ] RPC `aprobar_sugerencia`: rama de liquidación (orden simple a mercado `day`, sin retención y exenta de RR-14).
- [ ] Función `ejecutor-ordenes`: cancelar las patas de la protección antes de vender y no mirar `trading_activo` en las liquidaciones.
- [ ] Pruebas pgTAP y `deno test`: liquidación con el trading apagado, reparto y permisos.
- [ ] E2E-16 actualizado: un Analista aprueba cada venta y el cupo queda vacío.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-069 · Solicitar la liquidación de un cupo](HU-069-solicitar-la-liquidacion-de-un-cupo.md) | Decide las sugerencias de liquidación. |
| Depende de | [HU-065 · Decidir en Arriesgadas con doble aprobación](HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) | Usa la decisión del Analista. |
| Depende de | [HU-077 · Protección nativa en compras de acciones enteras](../E-08-ejecucion-y-broker/HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) | Cancela las patas de la protección antes de vender. |
| Depende de | [HU-023 · Reparto de la ganancia realizada y absorción de pérdidas](../E-03-fondo-y-libro-contable/HU-023-reparto-de-la-ganancia-realizada-y-absorcion-de-perdidas.md) | Reparte la ganancia de la venta. |
| Habilita | [HU-012 · Dar de baja y reincorporar una cuenta](../E-02-identidad-y-acceso/HU-012-dar-de-baja-y-reincorporar-una-cuenta.md) | HU-012: la baja exige el cupo ya liquidado. |

## Notas técnicas

El efectivo del cupo pasa a `usuarios_comun` al cerrarlo en la baja ([HU-012](../E-02-identidad-y-acceso/HU-012-dar-de-baja-y-reincorporar-una-cuenta.md)).

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

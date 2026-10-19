# FR-059 · Propuesta de rebalanceo

| Campo | Valor |
|---|---|
| Identificador | FR-059 |
| Nombre | Propuesta de rebalanceo |
| Épica | [E-03 · Fondo y libro contable](../E-03-fondo-y-libro-contable/README.md) |

## Rol o actor

Sistema

## Descripción

Tras cada cierre, el sistema debe calcular el peso de cada bolsillo sobre el patrimonio del fondo y, si alguno se desvía más de `rebalanceo.desviacion_pp` puntos, crear una sugerencia de rebalanceo para el Administrador que solo mueve efectivo disponible entre `reserva`, `arriesgadas` y `usuarios_comun`, parcial y explicada si el efectivo no alcanza.

## Fuente

RN-33 · RN-34 · RN-35

## Historias que lo implementan

- [HU-024 · Propuesta de rebalanceo tras el cierre](../E-03-fondo-y-libro-contable/HU-024-propuesta-de-rebalanceo-tras-el-cierre.md) (R6)

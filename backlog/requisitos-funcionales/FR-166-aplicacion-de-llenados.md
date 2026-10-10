# FR-166 · Aplicación de llenados

| Campo | Valor |
|---|---|
| Identificador | FR-166 |
| Nombre | Aplicación de llenados |
| Épica | [E-08 · Ejecución y broker](../E-08-ejecucion-y-broker/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe aplicar cada llenado por diferencia contra lo ya aplicado, de forma idempotente: libro, posición con costo promedio ponderado, liberación de la retención y activación de la protección.

## Fuente

08 §2.2 · 02 §6.2 · RN-25 · RN-06

## Historias que lo implementan

- [HU-074 · Sincronizar órdenes y aplicar llenados](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) (R4)

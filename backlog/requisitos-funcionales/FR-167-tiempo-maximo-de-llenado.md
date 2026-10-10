# FR-167 · Tiempo máximo de llenado

| Campo | Valor |
|---|---|
| Identificador | FR-167 |
| Nombre | Tiempo máximo de llenado |
| Épica | [E-08 · Ejecución y broker](../E-08-ejecucion-y-broker/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe cancelar una compra aceptada o parcialmente llenada que supere `ejecucion.minutos_max_llenado` minutos, conservar lo llenado y liberar el resto de la retención.

## Fuente

08 §2.2 · CB-35 · CB-39

## Historias que lo implementan

- [HU-074 · Sincronizar órdenes y aplicar llenados](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) (R4)

# FR-165 · Sincronización de órdenes

| Campo | Valor |
|---|---|
| Identificador | FR-165 |
| Nombre | Sincronización de órdenes |
| Épica | [E-08 · Ejecución y broker](../E-08-ejecucion-y-broker/README.md) |

## Rol o actor

Sistema y Broker (Alpaca paper)

## Descripción

Mientras haya órdenes vivas, el sistema debe consultar cada 10 segundos su estado en el broker, traducirlo a los estados propios y guardar el estado crudo y cada evento.

## Fuente

10 §7 · 08 §2.1

## Historias que lo implementan

- [HU-074 · Sincronizar órdenes y aplicar llenados](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) (R4)

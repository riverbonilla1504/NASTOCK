# FR-161 · Envío idempotente

| Campo | Valor |
|---|---|
| Identificador | FR-161 |
| Nombre | Envío idempotente |
| Épica | [E-08 · Ejecución y broker](../E-08-ejecucion-y-broker/README.md) |

## Rol o actor

Sistema (ejecutor de órdenes)

## Descripción

El sistema debe enviar el id de la orden como `client_order_id` y, si no recibe respuesta, marcar la orden como desconocida y consultar al broker por ese id antes de reintentar, de modo que nunca envíe dos veces la misma orden.

## Fuente

08 §2.2 · CB-33

## Historias que lo implementan

- [HU-073 · Enviar al broker las órdenes aprobadas](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) (R4)

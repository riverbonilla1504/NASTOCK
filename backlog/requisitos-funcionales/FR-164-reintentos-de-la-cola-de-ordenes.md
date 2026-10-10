# FR-164 · Reintentos de la cola de órdenes

| Campo | Valor |
|---|---|
| Identificador | FR-164 |
| Nombre | Reintentos de la cola de órdenes |
| Épica | [E-08 · Ejecución y broker](../E-08-ejecucion-y-broker/README.md) |

## Rol o actor

Sistema

## Descripción

Si un mensaje de la cola de órdenes falla 5 veces, el sistema debe archivarlo, dejar la orden en error de envío y alertar al Administrador.

## Fuente

05 §8 · CB-67 · CB-68

## Historias que lo implementan

- [HU-073 · Enviar al broker las órdenes aprobadas](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) (R4)

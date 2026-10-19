# FR-160 · Envío de órdenes desde una cola

| Campo | Valor |
|---|---|
| Identificador | FR-160 |
| Nombre | Envío de órdenes desde una cola |
| Épica | [E-08 · Ejecución y broker](../E-08-ejecucion-y-broker/README.md) |

## Rol o actor

Sistema (ejecutor de órdenes)

## Descripción

El sistema debe tomar cada orden de la cola de envío, revalidarla (banda, mercado, políticas, interruptor y salud) y enviarla al broker; si la revalidación falla, debe dejar la sugerencia fallida con el motivo y liberar la retención.

## Fuente

08 §1 · 05 §6 · 05 §8 · CB-32

## Historias que lo implementan

- [HU-073 · Enviar al broker las órdenes aprobadas](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) (R4)

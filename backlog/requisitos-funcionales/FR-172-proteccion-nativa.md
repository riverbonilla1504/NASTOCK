# FR-172 · Protección nativa

| Campo | Valor |
|---|---|
| Identificador | FR-172 |
| Nombre | Protección nativa |
| Épica | [E-08 · Ejecución y broker](../E-08-ejecucion-y-broker/README.md) |

## Rol o actor

Sistema y Broker (Alpaca paper)

## Descripción

El sistema debe crear la protección de una compra de acciones enteras como las patas stop y take-profit del bracket en el broker, con precios calculados sobre el precio de referencia, y detectar su disparo en la sincronización.

## Fuente

10 §6 · 08 §3 · D-09 · D-25

## Historias que lo implementan

- [HU-077 · Protección nativa en compras de acciones enteras](../E-08-ejecucion-y-broker/HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) (R4)

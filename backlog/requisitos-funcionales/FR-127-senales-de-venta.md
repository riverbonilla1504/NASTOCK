# FR-127 · Señales de venta

| Campo | Valor |
|---|---|
| Identificador | FR-127 |
| Nombre | Señales de venta |
| Épica | [E-06 · IA: contexto y decisión](../E-06-ia-contexto-y-decision/README.md) |

## Rol o actor

Sistema (IA principal)

## Descripción

El sistema debe emitir una señal de venta de una posición abierta cuando `exit_timing` es `sell_now` (100 %) o `reduce` (50 %) con confianza mayor o igual a `jev.confianza_venta`, o cuando `thesis_broken` es mayor o igual a 0,7 (100 %).

## Fuente

07 §6.3 · 07 §6.1

## Historias que lo implementan

- [HU-053 · Señales de venta de posiciones abiertas](../E-06-ia-contexto-y-decision/HU-053-senales-de-venta-de-posiciones-abiertas.md) (R4)

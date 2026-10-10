# FR-121 · Alerta de contradicción entre datos y contexto

| Campo | Valor |
|---|---|
| Identificador | FR-121 |
| Nombre | Alerta de contradicción entre datos y contexto |
| Épica | [E-06 · IA: contexto y decisión](../E-06-ia-contexto-y-decision/README.md) |

## Rol o actor

Sistema (IA principal)

## Descripción

Cuando una candidata que por números está entre las 3 mejores tiene una contradicción mayor o igual a 0,5, el sistema no debe proponerla y debe crear una alerta para Analistas; si la contradicción está entre 0,3 y 0,5 y se propone, la sugerencia debe llevar una advertencia visible.

## Fuente

07 §6.3 · CB-84

## Historias que lo implementan

- [HU-049 · Alertas de contradicción y de mercado](../E-06-ia-contexto-y-decision/HU-049-alertas-de-contradiccion-y-de-mercado.md) (R3)

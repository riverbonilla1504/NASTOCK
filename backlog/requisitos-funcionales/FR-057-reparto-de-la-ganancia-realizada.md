# FR-057 · Reparto de la ganancia realizada

| Campo | Valor |
|---|---|
| Identificador | FR-057 |
| Nombre | Reparto de la ganancia realizada |
| Épica | [E-03 · Fondo y libro contable](../E-03-fondo-y-libro-contable/README.md) |

## Rol o actor

Sistema

## Descripción

Al aplicarse el llenado de una venta con ganancia, el sistema debe repartir la ganancia con los porcentajes vigentes en ese momento: 50 % a la Reserva, 25 % a Arriesgadas y 25 % al cupo que vendió, o a `usuarios_comun` si vendió Arriesgadas; las partes de 25 % se truncan a centavos y la Reserva recibe el resto.

## Fuente

RN-26 · RN-29 · RN-30 · CB-17 · CB-18 · D-03 · D-04

## Historias que lo implementan

- [HU-023 · Reparto de la ganancia realizada y absorción de pérdidas](../E-03-fondo-y-libro-contable/HU-023-reparto-de-la-ganancia-realizada-y-absorcion-de-perdidas.md) (R4)

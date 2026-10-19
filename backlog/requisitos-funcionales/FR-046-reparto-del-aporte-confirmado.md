# FR-046 · Reparto del aporte confirmado

| Campo | Valor |
|---|---|
| Identificador | FR-046 |
| Nombre | Reparto del aporte confirmado |
| Épica | [E-03 · Fondo y libro contable](../E-03-fondo-y-libro-contable/README.md) |

## Rol o actor

Sistema

## Descripción

Al confirmarse un aporte, el sistema debe repartirlo entre `reserva`, `arriesgadas` y `usuarios_comun` con los porcentajes vigentes, guardarlos en el movimiento, truncar a centavos las partes de Arriesgadas y Usuarios y asignar el resto a la Reserva.

## Fuente

RN-08 · RN-09 · CB-12 · D-03

## Historias que lo implementan

- [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) (R2)

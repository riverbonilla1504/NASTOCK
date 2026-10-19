# FR-086 · Reglas de riesgo de las compras

| Campo | Valor |
|---|---|
| Identificador | FR-086 |
| Nombre | Reglas de riesgo de las compras |
| Épica | [E-05 · Motor de políticas y configuración](../E-05-motor-de-politicas-y-configuracion/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe rechazar una compra cuyo símbolo no esté en la lista blanca activa del bolsillo (RR-01), cuyo monto supere el disponible (RR-03), el máximo por operación (RR-04) o la concentración por símbolo (RR-05), o cuyo stop-loss falte o esté fuera del rango del bolsillo (RR-08).

## Fuente

RR-01 · RR-03 · RR-04 · RR-05 · RR-08 · Q-03

## Historias que lo implementan

- [HU-037 · Motor de políticas: reglas de la propuesta](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) (R3)

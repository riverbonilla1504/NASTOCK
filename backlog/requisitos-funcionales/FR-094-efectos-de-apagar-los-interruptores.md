# FR-094 · Efectos de apagar los interruptores

| Campo | Valor |
|---|---|
| Identificador | FR-094 |
| Nombre | Efectos de apagar los interruptores |
| Épica | [E-05 · Motor de políticas y configuración](../E-05-motor-de-politicas-y-configuracion/README.md) |

## Rol o actor

Sistema

## Descripción

Con `ia_activa` apagado, el sistema no debe correr ciclos y debe conservar las sugerencias vivas; con `trading_activo` apagado, debe invalidar las sugerencias vivas salvo las de liquidación y no aprobar ni enviar órdenes nuevas, manteniendo protecciones y liquidaciones.

## Fuente

RR-14 · 08 §6 · CB-32

## Historias que lo implementan

- [HU-039 · Freno de emergencia](../E-05-motor-de-politicas-y-configuracion/HU-039-freno-de-emergencia.md) (R5)

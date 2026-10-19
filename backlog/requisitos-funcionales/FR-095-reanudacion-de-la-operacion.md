# FR-095 · Reanudación de la operación

| Campo | Valor |
|---|---|
| Identificador | FR-095 |
| Nombre | Reanudación de la operación |
| Épica | [E-05 · Motor de políticas y configuración](../E-05-motor-de-politicas-y-configuracion/README.md) |

## Rol o actor

Administrador

## Descripción

El sistema debe rechazar el encendido de `trading_activo` cuando la última conciliación no está en `ok` y el descuadre no está marcado como revisado.

## Fuente

PM-57 · CB-77 · 11 §8

## Historias que lo implementan

- [HU-040 · Reanudar el trading solo con la conciliación en ok](../E-05-motor-de-politicas-y-configuracion/HU-040-reanudar-el-trading-solo-con-la-conciliacion-en-ok.md) (R5)

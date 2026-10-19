# FR-080 · Encendido de un interruptor

| Campo | Valor |
|---|---|
| Identificador | FR-080 |
| Nombre | Encendido de un interruptor |
| Épica | [E-05 · Motor de políticas y configuración](../E-05-motor-de-politicas-y-configuracion/README.md) |

## Rol o actor

Administrador

## Descripción

El sistema debe permitir solo al Administrador encender `ia_activa` o `trading_activo`, y debe rechazar el encendido mientras el fondo no tenga un aporte confirmado.

## Fuente

PM-57 · RN-11 · 08 §7.6

## Historias que lo implementan

- [HU-034 · Encender y apagar los interruptores del fondo](../E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md) (R2)
- [HU-040 · Reanudar el trading solo con la conciliación en ok](../E-05-motor-de-politicas-y-configuracion/HU-040-reanudar-el-trading-solo-con-la-conciliacion-en-ok.md) (R5)

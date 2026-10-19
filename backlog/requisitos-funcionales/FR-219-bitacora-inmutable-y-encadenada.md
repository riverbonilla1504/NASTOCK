# FR-219 · Bitácora inmutable y encadenada

| Campo | Valor |
|---|---|
| Identificador | FR-219 |
| Nombre | Bitácora inmutable y encadenada |
| Épica | [E-12 · Seguridad, auditoría y cumplimiento](../E-12-seguridad-auditoria-y-cumplimiento/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe aceptar escrituras en la bitácora solo a través de `private.auditar()`, rechazar toda modificación o borrado y encadenar cada registro con el hash del anterior.

## Fuente

11 §4.3

## Historias que lo implementan

- [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) (R1)

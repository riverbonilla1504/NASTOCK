# FR-049 · Cupo al aceptar la invitación

| Campo | Valor |
|---|---|
| Identificador | FR-049 |
| Nombre | Cupo al aceptar la invitación |
| Épica | [E-03 · Fondo y libro contable](../E-03-fondo-y-libro-contable/README.md) |

## Rol o actor

Sistema

## Descripción

Cuando una persona con rol Usuario acepta su invitación, el sistema debe crear su cupo con el monto inicial indicado si `usuarios_comun` lo cubre; si no lo cubre, debe crearlo en 0 y generar la alerta `cupo_inicial_no_asignado`, sin impedir el ingreso.

## Fuente

RN-18 · 04 §6 · CB-15

## Historias que lo implementan

- [HU-017 · Cupo al aceptar la invitación](../E-03-fondo-y-libro-contable/HU-017-cupo-al-aceptar-la-invitacion.md) (R2)

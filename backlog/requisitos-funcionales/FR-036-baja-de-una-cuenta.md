# FR-036 · Baja de una cuenta

| Campo | Valor |
|---|---|
| Identificador | FR-036 |
| Nombre | Baja de una cuenta |
| Épica | [E-02 · Identidad y acceso](../E-02-identidad-y-acceso/README.md) |

## Rol o actor

Administrador

## Descripción

El sistema debe permitir al Administrador dar de baja una cuenta solo si su cupo no tiene posiciones ni órdenes vivas: devolver el efectivo a `usuarios_comun`, cerrar la subcuenta y bloquear la cuenta, conservando su historial.

## Fuente

PM-53 · 02 §11 · RN-40 · 08 §7.7

## Historias que lo implementan

- [HU-012 · Dar de baja y reincorporar una cuenta](../E-02-identidad-y-acceso/HU-012-dar-de-baja-y-reincorporar-una-cuenta.md) (R6)

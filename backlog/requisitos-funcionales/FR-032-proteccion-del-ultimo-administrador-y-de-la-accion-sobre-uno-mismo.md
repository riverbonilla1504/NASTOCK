# FR-032 · Protección del último administrador y de la acción sobre uno mismo

| Campo | Valor |
|---|---|
| Identificador | FR-032 |
| Nombre | Protección del último administrador y de la acción sobre uno mismo |
| Épica | [E-02 · Identidad y acceso](../E-02-identidad-y-acceso/README.md) |

## Rol o actor

Administrador

## Descripción

El sistema debe rechazar con `ULTIMO_ADMIN` suspender, dar de baja o cambiar de rol al último Administrador activo, y con `AUTO_ACCION` que una persona se aplique esas acciones a sí misma.

## Fuente

RN-50 · RN-51 · CB-09

## Historias que lo implementan

- [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) (R2)
- [HU-011 · Cambiar el rol de una cuenta](../E-02-identidad-y-acceso/HU-011-cambiar-el-rol-de-una-cuenta.md) (R2)
- [HU-012 · Dar de baja y reincorporar una cuenta](../E-02-identidad-y-acceso/HU-012-dar-de-baja-y-reincorporar-una-cuenta.md) (R6)

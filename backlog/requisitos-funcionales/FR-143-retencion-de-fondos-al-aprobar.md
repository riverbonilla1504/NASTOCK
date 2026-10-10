# FR-143 · Retención de fondos al aprobar

| Campo | Valor |
|---|---|
| Identificador | FR-143 |
| Nombre | Retención de fondos al aprobar |
| Épica | [E-07 · Sugerencias y decisiones](../E-07-sugerencias-y-decisiones/README.md) |

## Rol o actor

Sistema

## Descripción

En la aprobación final de una compra, el sistema debe retener `cantidad × precio_referencia × (1 + banda)` en la subcuenta, crear la orden y encolarla para su envío; si el disponible no alcanza, debe responder `FONDOS_INSUFICIENTES` y dejar la sugerencia pendiente.

## Fuente

RN-23 · 08 §1 · CB-29 · D-33

## Historias que lo implementan

- [HU-062 · Aprobar una sugerencia de mi cupo](../E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md) (R4)
- [HU-065 · Decidir en Arriesgadas con doble aprobación](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) (R4)

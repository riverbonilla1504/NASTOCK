# FR-148 · Doble aprobación

| Campo | Valor |
|---|---|
| Identificador | FR-148 |
| Nombre | Doble aprobación |
| Épica | [E-07 · Sugerencias y decisiones](../E-07-sugerencias-y-decisiones/README.md) |

## Rol o actor

Analista

## Descripción

En una sugerencia con doble aprobación, el sistema debe exigir dos aprobaciones de Analistas distintos: la primera la deja en `pendiente_segunda` y avisa a los demás Analistas, una segunda del mismo Analista devuelve `MISMO_ANALISTA` y un rechazo de cualquiera la rechaza.

## Fuente

RN-52 · RR-13 · 08 §7.2 · CB-23 · CB-24 · CB-26

## Historias que lo implementan

- [HU-065 · Decidir en Arriesgadas con doble aprobación](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) (R4)

# FR-126 · La opinión no bloquea la orden

| Campo | Valor |
|---|---|
| Identificador | FR-126 |
| Nombre | La opinión no bloquea la orden |
| Épica | [E-06 · IA: contexto y decisión](../E-06-ia-contexto-y-decision/README.md) |

## Rol o actor

Usuario

## Descripción

El sistema debe entregar el veredicto `sin_opinion` si JEV no responde en `ia.timeout_jev_seg` segundos y debe permitir continuar con la orden cualquiera que sea el veredicto.

## Fuente

07 §8 · CB-57

## Historias que lo implementan

- [HU-052 · Opinión de la IA sobre una orden manual](../E-06-ia-contexto-y-decision/HU-052-opinion-de-la-ia-sobre-una-orden-manual.md) (R4)

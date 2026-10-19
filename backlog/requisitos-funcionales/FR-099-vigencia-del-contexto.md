# FR-099 · Vigencia del contexto

| Campo | Valor |
|---|---|
| Identificador | FR-099 |
| Nombre | Vigencia del contexto |
| Épica | [E-06 · IA: contexto y decisión](../E-06-ia-contexto-y-decision/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe usar en un ciclo solo un contexto generado hace menos de `ia.contexto_max_minutos` minutos y sin noticias más nuevas que él; si no cumple, debe evaluar la candidata "sin contexto" y encolar su regeneración.

## Fuente

07 §4.2 · CB-82 · CB-83

## Historias que lo implementan

- [HU-043 · Vigencia y regeneración del contexto](../E-06-ia-contexto-y-decision/HU-043-vigencia-y-regeneracion-del-contexto.md) (R3)

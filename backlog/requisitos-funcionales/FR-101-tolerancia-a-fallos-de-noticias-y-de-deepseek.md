# FR-101 · Tolerancia a fallos de noticias y de DeepSeek

| Campo | Valor |
|---|---|
| Identificador | FR-101 |
| Nombre | Tolerancia a fallos de noticias y de DeepSeek |
| Épica | [E-06 · IA: contexto y decisión](../E-06-ia-contexto-y-decision/README.md) |

## Rol o actor

Sistema

## Descripción

Si Alpaca News o DeepSeek fallan o devuelven una respuesta vacía o inválida, el sistema debe reintentar una vez y, si el fallo persiste, conservar el contexto anterior vigente o evaluar "sin contexto", sin bloquear el ciclo.

## Fuente

07 §10 · CB-58 · CB-81 · Q-19

## Historias que lo implementan

- [HU-043 · Vigencia y regeneración del contexto](../E-06-ia-contexto-y-decision/HU-043-vigencia-y-regeneracion-del-contexto.md) (R3)

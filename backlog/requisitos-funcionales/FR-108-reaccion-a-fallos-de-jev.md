# FR-108 · Reacción a fallos de JEV

| Campo | Valor |
|---|---|
| Identificador | FR-108 |
| Nombre | Reacción a fallos de JEV |
| Épica | [E-06 · IA: contexto y decisión](../E-06-ia-contexto-y-decision/README.md) |

## Rol o actor

Sistema

## Descripción

Ante una respuesta 429 o 529 de JEV, el sistema debe reintentar con espera exponencial y omitir la candidata si falla; con JEV caído no debe crear sugerencias nuevas y debe mantener órdenes manuales sin opinión, ventas, protecciones y alertas de código.

## Fuente

07 §10 · CB-57

## Historias que lo implementan

- [HU-045 · Adaptador de JEV y estado en etiquetas](../E-06-ia-contexto-y-decision/HU-045-adaptador-de-jev-y-estado-en-etiquetas.md) (R3)

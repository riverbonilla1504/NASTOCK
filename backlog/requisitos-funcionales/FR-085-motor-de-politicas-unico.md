# FR-085 · Motor de políticas único

| Campo | Valor |
|---|---|
| Identificador | FR-085 |
| Nombre | Motor de políticas único |
| Épica | [E-05 · Motor de políticas y configuración](../E-05-motor-de-politicas-y-configuracion/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe validar toda operación con una sola función en la base de datos que devuelve la lista de reglas violadas, llamada al crear la propuesta, al aprobar, antes de enviar al broker y al dispararse una protección.

## Fuente

RN-38 · 02 §9 · 06 §8.2

## Historias que lo implementan

- [HU-037 · Motor de políticas: reglas de la propuesta](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) (R3)
- [HU-038 · Motor de políticas completo en los cuatro momentos](../E-05-motor-de-politicas-y-configuracion/HU-038-motor-de-politicas-completo-en-los-cuatro-momentos.md) (R4)

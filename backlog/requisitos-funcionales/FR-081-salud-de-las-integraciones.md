# FR-081 · Salud de las integraciones

| Campo | Valor |
|---|---|
| Identificador | FR-081 |
| Nombre | Salud de las integraciones |
| Épica | [E-05 · Motor de políticas y configuración](../E-05-motor-de-politicas-y-configuracion/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe registrar cada éxito y cada fallo de cada integración y calcular su estado: `ok`, `degradado` con 1 o 2 fallos seguidos y `caido` con 3 o más; un éxito lo devuelve a `ok`.

## Fuente

06 §5.6 · 08 §6

## Historias que lo implementan

- [HU-035 · Salud de las integraciones](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) (R3)

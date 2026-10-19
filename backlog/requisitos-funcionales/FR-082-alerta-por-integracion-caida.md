# FR-082 · Alerta por integración caída

| Campo | Valor |
|---|---|
| Identificador | FR-082 |
| Nombre | Alerta por integración caída |
| Épica | [E-05 · Motor de políticas y configuración](../E-05-motor-de-politicas-y-configuracion/README.md) |

## Rol o actor

Sistema

## Descripción

Cuando una integración pasa a `caido`, el sistema debe alertar a Administradores y Analistas y registrar `integracion.caida`; cuando se recupera, debe registrar `integracion.recuperada`.

## Fuente

08 §6 · 07 §10 · 09 §5.1 · 11 §4.1 · CB-64

## Historias que lo implementan

- [HU-035 · Salud de las integraciones](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) (R3)

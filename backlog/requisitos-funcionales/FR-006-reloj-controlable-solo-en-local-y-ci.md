# FR-006 · Reloj controlable solo en local y CI

| Campo | Valor |
|---|---|
| Identificador | FR-006 |
| Nombre | Reloj controlable solo en local y CI |
| Épica | [E-01 · Cimientos y calidad continua](../E-01-cimientos-y-calidad-continua/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe tomar la hora de toda su lógica de `private.ahora()`, que en local y CI se puede adelantar con el esquema `pruebas` y en la nube equivale a la hora real porque ese esquema no existe.

## Fuente

15 §3

## Historias que lo implementan

- [TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba](../E-01-cimientos-y-calidad-continua/TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) (R1)

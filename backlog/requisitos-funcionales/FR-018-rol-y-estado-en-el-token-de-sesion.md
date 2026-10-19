# FR-018 · Rol y estado en el token de sesión

| Campo | Valor |
|---|---|
| Identificador | FR-018 |
| Nombre | Rol y estado en el token de sesión |
| Épica | [E-02 · Identidad y acceso](../E-02-identidad-y-acceso/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe agregar al token de sesión los claims `app_rol` y `app_estado` leídos de `perfiles`, con una duración del token de 15 minutos.

## Fuente

04 §7 · 04 §8 · 03 §4.1

## Historias que lo implementan

- [HU-001 · Perfiles, rol actual y lecturas por rol](../E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) (R1)

# FR-019 · Autorización por perfil activo

| Campo | Valor |
|---|---|
| Identificador | FR-019 |
| Nombre | Autorización por perfil activo |
| Épica | [E-02 · Identidad y acceso](../E-02-identidad-y-acceso/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe autorizar cada lectura y cada escritura consultando el rol y el estado en `perfiles`, no los claims del token, y debe negar todo acceso a una cuenta que no esté activa.

## Fuente

03 §4.2 · 03 §1 (principios)

## Historias que lo implementan

- [HU-001 · Perfiles, rol actual y lecturas por rol](../E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) (R1)
- [HU-003 · Invitar a una persona y revocar invitaciones](../E-02-identidad-y-acceso/HU-003-invitar-a-una-persona-y-revocar-invitaciones.md) (R1)

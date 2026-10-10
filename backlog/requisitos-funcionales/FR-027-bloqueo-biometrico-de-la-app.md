# FR-027 · Bloqueo biométrico de la app

| Campo | Valor |
|---|---|
| Identificador | FR-027 |
| Nombre | Bloqueo biométrico de la app |
| Épica | [E-02 · Identidad y acceso](../E-02-identidad-y-acceso/README.md) |

## Rol o actor

Usuario, Analista y Administrador

## Descripción

La app móvil debe pedir biometría o el PIN del dispositivo antes de mostrar datos cuando vuelve de segundo plano después de `app.minutos_bloqueo` minutos.

## Fuente

04 §8 · CB-08

## Historias que lo implementan

- [HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) (R2)

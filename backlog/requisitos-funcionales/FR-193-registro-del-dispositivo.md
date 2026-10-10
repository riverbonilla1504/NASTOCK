# FR-193 · Registro del dispositivo

| Campo | Valor |
|---|---|
| Identificador | FR-193 |
| Nombre | Registro del dispositivo |
| Épica | [E-09 · Tiempo real y notificaciones](../E-09-tiempo-real-y-notificaciones/README.md) |

## Rol o actor

Usuario, Analista y Administrador

## Descripción

El sistema debe registrar el token de push del dispositivo al iniciar sesión y cuando FCM lo renueva, y borrarlo al cerrar sesión, al suspender la cuenta, cuando FCM lo declara inválido y tras 60 días sin uso.

## Fuente

PM-03 · 09 §5.5

## Historias que lo implementan

- [HU-087 · Registrar mi dispositivo para push](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md) (R5)

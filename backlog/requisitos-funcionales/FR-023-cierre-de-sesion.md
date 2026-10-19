# FR-023 · Cierre de sesión

| Campo | Valor |
|---|---|
| Identificador | FR-023 |
| Nombre | Cierre de sesión |
| Épica | [E-02 · Identidad y acceso](../E-02-identidad-y-acceso/README.md) |

## Rol o actor

Usuario, Analista y Administrador

## Descripción

Al cerrar sesión, la app debe cancelar sus suscripciones de tiempo real, eliminar el token de push del dispositivo, revocar la sesión en Supabase y cerrar la sesión de Google.

## Fuente

04 §4.5 · 09 §7

## Historias que lo implementan

- [HU-007 · Cerrar sesión](../E-02-identidad-y-acceso/HU-007-cerrar-sesion.md) (R1)
- [HU-087 · Registrar mi dispositivo para push](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md) (R5)

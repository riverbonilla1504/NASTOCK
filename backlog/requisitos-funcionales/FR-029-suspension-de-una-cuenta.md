# FR-029 · Suspensión de una cuenta

| Campo | Valor |
|---|---|
| Identificador | FR-029 |
| Nombre | Suspensión de una cuenta |
| Épica | [E-02 · Identidad y acceso](../E-02-identidad-y-acceso/README.md) |

## Rol o actor

Administrador

## Descripción

El sistema debe permitir al Administrador suspender una cuenta: cambiar su estado a suspendido, invalidar sus sugerencias vivas, borrar sus dispositivos de push, bloquearla en Auth y publicar `sesion_revocada` en su canal.

## Fuente

PM-52 · 04 §10 · RN-57 · CB-07

## Historias que lo implementan

- [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) (R2)
- [HU-067 · Invalidación por precio y por cambio de situación](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md) (R4)
- [HU-087 · Registrar mi dispositivo para push](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md) (R5)

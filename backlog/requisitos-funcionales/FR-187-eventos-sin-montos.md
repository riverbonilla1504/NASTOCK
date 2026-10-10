# FR-187 · Eventos sin montos

| Campo | Valor |
|---|---|
| Identificador | FR-187 |
| Nombre | Eventos sin montos |
| Épica | [E-09 · Tiempo real y notificaciones](../E-09-tiempo-real-y-notificaciones/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe enviar en cada evento de entidad solo la tabla, el id, la versión y el estado, y nunca montos; la única excepción son los precios del canal `mercado`.

## Fuente

09 §4 · D-32

## Historias que lo implementan

- [HU-083 · Canales privados de tiempo real](../E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md) (R1)

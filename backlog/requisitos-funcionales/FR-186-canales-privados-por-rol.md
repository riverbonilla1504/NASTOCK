# FR-186 · Canales privados por rol

| Campo | Valor |
|---|---|
| Identificador | FR-186 |
| Nombre | Canales privados por rol |
| Épica | [E-09 · Tiempo real y notificaciones](../E-09-tiempo-real-y-notificaciones/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe publicar eventos solo desde la base de datos y en canales privados: `mercado` y `fondo` para toda persona activa, `usuario:{id}` solo para su dueño, `supervision` para Analistas y Administradores y `admin` solo para Administradores; ningún cliente puede publicar.

## Fuente

09 §3 · 03 §4.6

## Historias que lo implementan

- [HU-083 · Canales privados de tiempo real](../E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md) (R1)

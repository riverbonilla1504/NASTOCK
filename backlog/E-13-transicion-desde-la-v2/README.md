# E-13 · Transición desde la v2

| Campo | Valor |
|---|---|
| Objetivo | Reutilizar del repositorio v2 lo que ya funciona y está probado: el motor ×2 y el exportador. La interfaz es referencia para la identidad visual, no se copia (D-67). |
| Documentación fuente | docs/05 §11 |
| Módulos (docs/17) | M-05, M-15, M-20 |
| Depende de | — (en paralelo con E-01) |
| Entregas en las que avanza | R1 |
| Etiquetas | `epica` · `E-13` |

> **MVP corto** ([docs/14 §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)): entra 1 de los 3 ítems de esta épica: HU-116, con otro alcance (D-67). Los marcados *fuera del MVP corto* quedan para la fase siguiente; las relaciones de abajo son las del plan completo.

## Capacidades

Tomadas de `docs/14` §2:

- Copiar del repositorio v2 el motor ×2 y el exportador, con sus pruebas; construir la identidad visual y el sistema de diseño tomando la interfaz de la v2 como referencia (D-67)

## Historias de usuario

Cada historia tiene su narrativa, sus criterios de aceptación, sus tareas y sus relaciones en su propio archivo.

| ID | Historia | Rol | Entrega | Prioridad | Depende de |
|---|---|---|---|---|---|
| [HU-115](HU-115-motor-x2-teorico-de-la-v2-con-sus-pruebas.md) | Motor ×2 teórico de la v2 con sus pruebas · *fuera del MVP corto* | Usuario | R1 | Media | [TT-04](../E-01-cimientos-y-calidad-continua/TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) |
| [HU-116](HU-116-tema-estilos-widgets-y-fuentes-de-la-v2.md) | Identidad visual y sistema de diseño | Usuario | R1 | Baja | [TT-04](../E-01-cimientos-y-calidad-continua/TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) |
| [HU-117](HU-117-exportador-de-reportes-de-la-v2-con-sus-pruebas.md) | Exportador de reportes de la v2 con sus pruebas · *fuera del MVP corto* | Administrador | R1 | Baja | [TT-04](../E-01-cimientos-y-calidad-continua/TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) |

## Relaciones

Una flecha `A --> B` significa que B depende de A. Los nodos con borde punteado son ítems de otras épicas.

```mermaid
flowchart LR
  HU115["HU-115<br/>Motor ×2 teórico de la v2 con sus…"]
  HU116["HU-116<br/>Identidad visual y sistema de…"]
  HU117["HU-117<br/>Exportador de reportes de la v2…"]
  TT04(["TT-04"]):::externa
  TT04 --> HU115
  TT04 --> HU116
  TT04 --> HU117
  classDef externa stroke-dasharray: 4 3
```

## Requisitos funcionales de la épica

| ID | Requisito | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-227](../requisitos-funcionales/FR-227-linea-x2-teorico.md) | Línea ×2 teórico | Sistema | [HU-115](HU-115-motor-x2-teorico-de-la-v2-con-sus-pruebas.md) |

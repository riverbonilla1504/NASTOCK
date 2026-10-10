# FR-109 · Ciclo programado del agente

| Campo | Valor |
|---|---|
| Identificador | FR-109 |
| Nombre | Ciclo programado del agente |
| Épica | [E-06 · IA: contexto y decisión](../E-06-ia-contexto-y-decision/README.md) |

## Rol o actor

Sistema (IA principal)

## Descripción

El sistema debe correr un ciclo de decisión cada `ia.minutos_entre_ciclos` minutos dentro de la ventana de compras con `ia_activa` encendido, uno a la vez, y marcar como fallido un ciclo en curso de más de 5 minutos.

## Fuente

07 §2 · 07 §3 · CB-62 · Q-16

## Historias que lo implementan

- [HU-046 · Ciclo del agente: programación, uno a la vez y omisiones](../E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) (R3)

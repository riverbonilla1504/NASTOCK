# FR-110 · Ciclo por evento de mercado

| Campo | Valor |
|---|---|
| Identificador | FR-110 |
| Nombre | Ciclo por evento de mercado |
| Épica | [E-06 · IA: contexto y decisión](../E-06-ia-contexto-y-decision/README.md) |

## Rol o actor

Sistema (IA principal)

## Descripción

El sistema debe correr un ciclo extra cuando QQQ se mueve al menos `ia.umbral_evento_qqq_pct` desde el último ciclo y ese ciclo fue hace más de 3 minutos.

## Fuente

07 §2 · CB-55

## Historias que lo implementan

- [HU-046 · Ciclo del agente: programación, uno a la vez y omisiones](../E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) (R3)

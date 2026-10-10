# FR-114 · Reglas de decisión de compra

| Campo | Valor |
|---|---|
| Identificador | FR-114 |
| Nombre | Reglas de decisión de compra |
| Épica | [E-06 · IA: contexto y decisión](../E-06-ia-contexto-y-decision/README.md) |

## Rol o actor

Sistema (IA principal)

## Descripción

El sistema debe convertir en señal de compra solo la candidata elegible con mayor puntaje de cada bolsillo (desempate por mayor confianza y luego menor volatilidad) que cumpla: calidad de datos, `entry_timing = buy_now`, confianza mayor o igual a `jev.confianza_minima`, contradicción menor que `jev.umbral_contradiccion`, puntaje mayor o igual a `jev.puntaje_minimo` y ninguna señal viva del símbolo; si ninguna cumple, no debe proponer nada.

## Fuente

07 §6.3 · CB-60 · CB-85 · CB-86

## Historias que lo implementan

- [HU-047 · Puntaje compuesto y elección de la mejor opción](../E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) (R3)

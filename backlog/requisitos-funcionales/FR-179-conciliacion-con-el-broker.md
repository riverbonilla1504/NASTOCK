# FR-179 · Conciliación con el broker

| Campo | Valor |
|---|---|
| Identificador | FR-179 |
| Nombre | Conciliación con el broker |
| Épica | [E-08 · Ejecución y broker](../E-08-ejecucion-y-broker/README.md) |

## Rol o actor

Sistema y Broker (Alpaca paper)

## Descripción

El sistema debe comparar cada `conciliacion.minutos_entre` minutos en horario de mercado, y una vez tras el cierre, el efectivo, las posiciones por símbolo y las órdenes vivas del broker con el libro, y registrar el resultado: `ok`, `diferencia_menor` o `descuadre_critico`.

## Fuente

10 §8

## Historias que lo implementan

- [HU-080 · Conciliación completa con pausa automática](../E-08-ejecucion-y-broker/HU-080-conciliacion-completa-con-pausa-automatica.md) (R5)

# FR-091 · Reglas que dependen de lo ya operado

| Campo | Valor |
|---|---|
| Identificador | FR-091 |
| Nombre | Reglas que dependen de lo ya operado |
| Épica | [E-05 · Motor de políticas y configuración](../E-05-motor-de-politicas-y-configuracion/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe rechazar una operación que duplique una sugerencia u orden viva de la misma subcuenta, símbolo y lado (RR-10), una venta de más de lo que se tiene (RR-15), una sugerencia que supere el máximo diario por cupo (RR-16), una compra en Arriesgadas tras superar la pérdida diaria máxima (RR-19) y la recompra de un símbolo dentro del enfriamiento posterior a un stop-loss (RR-20).

## Fuente

RR-10 · RR-15 · RR-16 · RR-19 · RR-20

## Historias que lo implementan

- [HU-038 · Motor de políticas completo en los cuatro momentos](../E-05-motor-de-politicas-y-configuracion/HU-038-motor-de-politicas-completo-en-los-cuatro-momentos.md) (R4)

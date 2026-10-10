# FR-139 · Vencimiento y precios de la sugerencia

| Campo | Valor |
|---|---|
| Identificador | FR-139 |
| Nombre | Vencimiento y precios de la sugerencia |
| Épica | [E-07 · Sugerencias y decisiones](../E-07-sugerencias-y-decisiones/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe fijar el vencimiento de cada sugerencia como el menor entre ahora más `sugerencias.minutos_vencimiento` y el cierre menos el margen (compras) o el cierre (ventas), y calcular stop y objetivo en precio sobre el precio de referencia.

## Fuente

07 §7.5 · CB-50 · CB-56

## Historias que lo implementan

- [HU-058 · Sugerencia de compra para Arriesgadas](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md) (R4)
- [HU-059 · Reparto de una señal de Usuarios en sugerencias por cupo](../E-07-sugerencias-y-decisiones/HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) (R4)

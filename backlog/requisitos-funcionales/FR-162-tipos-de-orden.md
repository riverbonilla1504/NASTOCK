# FR-162 · Tipos de orden

| Campo | Valor |
|---|---|
| Identificador | FR-162 |
| Nombre | Tipos de orden |
| Épica | [E-08 · Ejecución y broker](../E-08-ejecucion-y-broker/README.md) |

## Rol o actor

Sistema (ejecutor de órdenes)

## Descripción

El sistema debe enviar: bracket límite `gtc` en compras de acciones enteras; simple límite `day` en compras fraccionales y en ventas sugeridas o manuales; y simple a mercado `day` en ventas por protección virtual y de liquidación; con el precio límite igual al de referencia más la banda en compras y al precio actual menos la banda en ventas.

## Fuente

10 §5 · RN-24

## Historias que lo implementan

- [HU-073 · Enviar al broker las órdenes aprobadas](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) (R4)

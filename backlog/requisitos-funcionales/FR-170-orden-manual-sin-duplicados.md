# FR-170 · Orden manual sin duplicados

| Campo | Valor |
|---|---|
| Identificador | FR-170 |
| Nombre | Orden manual sin duplicados |
| Épica | [E-08 · Ejecución y broker](../E-08-ejecucion-y-broker/README.md) |

## Rol o actor

Usuario

## Descripción

El sistema debe usar el id generado en la app como clave de idempotencia de la orden manual: reintentar con el mismo id devuelve la misma orden.

## Fuente

08 §7.5 · 08 §9.3

## Historias que lo implementan

- [HU-075 · Crear una orden manual en mi cupo](../E-08-ejecucion-y-broker/HU-075-crear-una-orden-manual-en-mi-cupo.md) (R4)

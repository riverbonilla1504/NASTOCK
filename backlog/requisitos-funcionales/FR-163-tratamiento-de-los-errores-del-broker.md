# FR-163 · Tratamiento de los errores del broker

| Campo | Valor |
|---|---|
| Identificador | FR-163 |
| Nombre | Tratamiento de los errores del broker |
| Épica | [E-08 · Ejecución y broker](../E-08-ejecucion-y-broker/README.md) |

## Rol o actor

Sistema (ejecutor de órdenes)

## Descripción

El sistema debe tratar cada error del broker según su tipo: fondos insuficientes (orden rechazada y alerta al Administrador), parámetros inválidos (error de envío), límite de solicitudes (reintento con espera), error del servidor o sin respuesta (desconocida) y mercado cerrado (fallida con el motivo).

## Fuente

10 §10 · CB-36

## Historias que lo implementan

- [HU-073 · Enviar al broker las órdenes aprobadas](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) (R4)

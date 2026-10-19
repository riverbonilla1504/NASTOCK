# FR-010 · Respaldo diario cifrado

| Campo | Valor |
|---|---|
| Identificador | FR-010 |
| Nombre | Respaldo diario cifrado |
| Épica | [E-01 · Cimientos y calidad continua](../E-01-cimientos-y-calidad-continua/README.md) |

## Rol o actor

Flujo de mantenimiento (GitHub Actions)

## Descripción

El sistema debe generar cada día un volcado del esquema y los datos de la base, cifrarlo con GPG (AES-256) y conservarlo 7 días como artefacto.

## Fuente

11 §7 · D-55

## Historias que lo implementan

- [TT-09 · Mantenimiento: ping diario, respaldo cifrado y prueba real semanal](../E-01-cimientos-y-calidad-continua/TT-09-mantenimiento-ping-diario-respaldo-cifrado-y-prueba-real-semanal.md) (R1)
- [HU-113 · Simulacro de restauración de un respaldo](../E-12-seguridad-auditoria-y-cumplimiento/HU-113-simulacro-de-restauracion-de-un-respaldo.md) (R6)

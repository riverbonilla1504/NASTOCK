# FR-008 · Latido del proyecto

| Campo | Valor |
|---|---|
| Identificador | FR-008 |
| Nombre | Latido del proyecto |
| Épica | [E-01 · Cimientos y calidad continua](../E-01-cimientos-y-calidad-continua/README.md) |

## Rol o actor

Flujo de mantenimiento (GitHub Actions)

## Descripción

El sistema debe exponer la función `ping()` sin sesión, que actualiza una fila de latido y devuelve la hora del servidor, y no debe dar ningún otro acceso al rol anónimo.

## Fuente

06 §7 · 05 §3.4 · CB-93

## Historias que lo implementan

- [TT-03 · Base de Supabase: esquema private, extensiones, Vault y ping](../E-01-cimientos-y-calidad-continua/TT-03-base-de-supabase-esquema-private-extensiones-vault-y-ping.md) (R1)
- [TT-09 · Mantenimiento: ping diario, respaldo cifrado y prueba real semanal](../E-01-cimientos-y-calidad-continua/TT-09-mantenimiento-ping-diario-respaldo-cifrado-y-prueba-real-semanal.md) (R1)

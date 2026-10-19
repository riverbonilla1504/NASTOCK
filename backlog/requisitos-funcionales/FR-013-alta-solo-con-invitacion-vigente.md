# FR-013 · Alta solo con invitación vigente

| Campo | Valor |
|---|---|
| Identificador | FR-013 |
| Nombre | Alta solo con invitación vigente |
| Épica | [E-02 · Identidad y acceso](../E-02-identidad-y-acceso/README.md) |

## Rol o actor

Google Workspace y Sistema (hook de alta)

## Descripción

En el primer ingreso, el sistema debe crear la cuenta solo si el proveedor está en `auth.proveedores_permitidos`, el dominio está en `auth.dominios_permitidos` y existe una invitación pendiente y no vencida para ese correo; en otro caso debe rechazar el alta con el mensaje definido y no crear el usuario.

## Fuente

04 §5 · CB-01 · CB-02 · CB-92

## Historias que lo implementan

- [HU-002 · Alta solo con invitación vigente](../E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md) (R1)

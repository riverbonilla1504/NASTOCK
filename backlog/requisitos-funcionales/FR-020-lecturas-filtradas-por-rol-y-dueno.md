# FR-020 · Lecturas filtradas por rol y dueño

| Campo | Valor |
|---|---|
| Identificador | FR-020 |
| Nombre | Lecturas filtradas por rol y dueño |
| Épica | [E-02 · Identidad y acceso](../E-02-identidad-y-acceso/README.md) |

## Rol o actor

Sistema

## Descripción

El sistema debe filtrar cada lectura de las tablas de `public` según la matriz de lectura por rol y dueño, y no debe conceder inserción, actualización ni borrado directo a ningún rol de la API.

## Fuente

03 §4.3 · 03 §4.4 · 06 §7

## Historias que lo implementan

- [HU-001 · Perfiles, rol actual y lecturas por rol](../E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) (R1)
- [HU-109 · Aislamiento verificado por tabla y por función](../E-12-seguridad-auditoria-y-cumplimiento/HU-109-aislamiento-verificado-por-tabla-y-por-funcion.md) (R2)

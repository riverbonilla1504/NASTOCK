# Modelo de datos (Fase 1): HU-107 · Bitácora inmutable con cadena de hash

Fuente: `docs/06` §5.6 (`auditoria`), `docs/11` §4 y `docs/03` §4.3. Los nombres y tipos son los de `docs/`.

## Tabla `public.auditoria`

| Columna | Tipo | Reglas |
|---|---|---|
| `id` | `bigint` | Clave primaria, `generated always as identity`. Crece en el orden de la cadena (research D-4). |
| `momento` | `timestamptz` | No nulo. Lo pone `auditar` con `private.ahora()`; sin valor por defecto. |
| `actor_id` | `uuid` | Nulo = sistema. Sin llave foránea: la bitácora no depende de `perfiles`. |
| `actor_rol` | `rol_app` | Nulo si el actor es el sistema o no tiene perfil. Lo lee `auditar` de `perfiles`. |
| `accion` | `text` | No nulo y no vacío. Una del catálogo de `docs/11` §4.1 (`cuenta.activada`…). |
| `entidad` | `text` | No nulo y no vacío. |
| `entidad_id` | `text` | Nulo si la acción no recae en una fila concreta. |
| `antes` | `jsonb` | Valor anterior. |
| `despues` | `jsonb` | Valor nuevo. |
| `detalle` | `jsonb` | Contexto de la acción. Entra en el hash. |
| `origen` | `text` | No nulo. `check (origen in ('app', 'sistema', 'cron', 'auth'))`. |
| `hash_anterior` | `text` | No nulo, único, 64 caracteres hexadecimales. El primer registro lleva 64 ceros (research D-3). |
| `hash` | `text` | No nulo, 64 caracteres hexadecimales: `sha256` de la fórmula de [contracts/auditoria.md](contracts/auditoria.md). |

Índices: la clave primaria y el índice único de `hash_anterior`. La consulta con filtros de HU-108 pedirá los suyos.

## Relaciones y estados

- Sin llaves foráneas: es un registro histórico que sobrevive a cualquier cambio de las tablas de negocio.
- No tiene `version` ni estados (`docs/06` §1): solo se agrega, nunca cambia, y no emite eventos de tiempo real.
- No se borra nunca (`docs/06` §1 y §10).

## Cadena

```text
fila 1: hash_anterior = 000…0 (64 ceros)   hash = H1
fila 2: hash_anterior = H1                  hash = H2
fila 3: hash_anterior = H2                  hash = H3
```

Cada registro apunta al hash del anterior; alterar uno del pasado obliga a recalcular todos los siguientes y a alterar los reportes diarios que guardan el último hash (`docs/11` §4.3, punto 5).

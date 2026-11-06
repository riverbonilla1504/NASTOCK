# Contrato: funciones `private` de la historia

Se llaman solo por conexión directa desde `_shared/bd.ts` (D-66). `execute` revocado a `public`, `anon` y `authenticated`. Se agregan a `docs/06` §8.2.

| Función | Argumentos | Devuelve | Errores |
|---|---|---|---|
| `private.simbolos_del_universo()` | — | `table(simbolo text)` | — |
| `private.simbolos_sin_historia(p_desde date)` | `p_desde` no nulo | `table(simbolo text)` | `p_desde` nulo: `simbolos_sin_historia: desde es obligatorio` |
| `private.guardar_barras_diarias(p_datos jsonb)` | arreglo de `{simbolo, fecha, apertura, maximo, minimo, cierre, volumen}` | `integer` (filas nuevas) | no es un arreglo: `guardar_barras_diarias: se esperaba un arreglo`; una barra que viola un `check` de la tabla: error `23514` y no se guarda el lote |

`guardar_barras_diarias` es idempotente: repetir el mismo arreglo devuelve `0`. Las barras ya guardadas no se reemplazan.

## Pruebas (pgTAP, `supabase/tests/database/02_universo_y_barras_test.sql`)

Tablas y tipo; RLS; permisos de `anon` y `authenticated`; CA-1 (cuentas por bolsillo, nombre y sector); barras sembradas; las tres funciones (incluido CA-3, QQQ siempre, símbolo inactivo fuera); `execute` cerrado.

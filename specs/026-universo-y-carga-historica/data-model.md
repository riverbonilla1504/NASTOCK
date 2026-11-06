# Modelo de datos (Data Model): HU-026 · Universo del NASDAQ-100 y carga histórica de barras

Fuente: `docs/06` §3 (enumeraciones) y §5.2 (mercado). Los nombres y tipos son los de `docs/`; la migración agrega comentarios, restricciones de integridad y permisos.

## Tipo nuevo

| Tipo | Valores | Nota |
|---|---|---|
| `public.bolsillo` | `reserva`, `arriesgadas`, `usuarios` | `docs/06` §3. Lo crea esta historia porque `lista_blanca` es la primera tabla que lo usa; las historias siguientes no lo vuelven a crear. |

## Tablas

### `public.lista_blanca`

| Columna | Tipo | Reglas |
|---|---|---|
| `bolsillo` | `bolsillo` | No nulo; `check (bolsillo <> 'reserva')`. Parte de la llave primaria. |
| `simbolo` | `text` | No nulo. Parte de la llave primaria. |
| `nombre` | `text` | No nulo. |
| `sector` | `text` | Nulo para los ETF. Sector GICS en inglés para las acciones (research R4). |
| `en_nasdaq100` | `boolean` | No nulo; por defecto `false`. |
| `activo` | `boolean` | No nulo; por defecto `true`. |
| `fraccionable`, `negociable` | `boolean` | Nulos hasta que HU-027 los sincronice. |
| `sincronizado_en` | `timestamptz` | Nulo hasta HU-027. |
| `notas` | `text` | |
| `actualizado_por` | `uuid` | Llave foránea a `perfiles` (`lista_blanca_actualizado_por_fkey`, de `*_lectura_del_mercado.sql`). Nulo en la semilla. |
| `actualizado_en` | `timestamptz` | No nulo; por defecto `now()`. |

Llave primaria `(bolsillo, simbolo)`.

**Semilla (101 acciones + 3 ETF = 104 filas)**

| Bolsillo | Símbolos | `en_nasdaq100` | Sector |
|---|---|---|---|
| `usuarios` | QLD, QQQ | `false` | nulo |
| `arriesgadas` | TQQQ | `false` | nulo |
| `arriesgadas` | las 101 acciones del índice | `true` | GICS (11 sectores) |

La lista completa está en la migración; se contrasta en la prueba pgTAP (cuenta por bolsillo, nombre y sector no vacíos).

### `public.barras_diarias`

| Columna | Tipo | Reglas |
|---|---|---|
| `simbolo` | `text` | No nulo. |
| `fecha` | `date` | No nulo. Día de mercado en Nueva York. |
| `apertura`, `maximo`, `minimo`, `cierre` | `numeric(14,4)` | No nulos; `minimo > 0`; `maximo >= greatest(apertura, cierre, minimo)`; `minimo <= least(apertura, cierre, maximo)`. |
| `volumen` | `bigint` | No nulo; `>= 0`. |

Llave primaria `(simbolo, fecha)`. Se guardan siempre (`docs/06` §10). Sin llave foránea a `lista_blanca`: el mismo símbolo puede estar en dos bolsillos y QQQ se guarda aunque no esté activo.

### `public.barras_minuto`

Mismas columnas que `barras_diarias`, con `momento timestamptz` en lugar de `fecha`. Llave primaria `(simbolo, momento)`. La llena HU-028 y la limpia HU-029 (5 días, solo ETF y símbolos con posiciones). Aquí solo se crea.

## Seguridad (las tres tablas)

| Rol | Permiso |
|---|---|
| `anon` | Ninguno. |
| `authenticated` | Solo `select`, con una política de lectura `using ((select private.rol_actual()) is not null)` (`*_lectura_del_mercado.sql`, posterior a HU-001; ver plan, decisión 1). Una cuenta suspendida, de baja o sin perfil no recibe filas. Sin `insert`, `update` ni `delete`. |
| Edge Functions | Solo a través de funciones `private` (D-66). |

RLS activo en las tres. Sin políticas de escritura.

## Funciones `private` nuevas

Todas `security definer`, `set search_path = ''`, con `revoke all … from public, anon, authenticated`. Se agregan a `docs/06` §8.2.

| Función | Devuelve | Qué hace |
|---|---|---|
| `simbolos_del_universo()` | `table(simbolo text)` | Los símbolos activos de `lista_blanca` de cualquier bolsillo, sin repetir, más `QQQ`. Ordenados. |
| `simbolos_sin_historia(p_desde date)` | `table(simbolo text)` | De los del universo, los que no tienen ninguna barra diaria con `fecha <= p_desde + 7`. |
| `guardar_barras_diarias(p_datos jsonb)` | `integer` | Recibe un arreglo de objetos `{simbolo, fecha, apertura, maximo, minimo, cierre, volumen}`; inserta con `on conflict (simbolo, fecha) do nothing` y devuelve cuántas filas nuevas quedaron. Rechaza un valor que no sea un arreglo. |

## Datos de prueba (`seed.sql`)

Barras diarias de **2025-11-03 a 2026-10-30** (lunes a viernes, 260 días) para los 104 símbolos, con el algoritmo del simulado (`contracts/mercado.md`). Valores conocidos que comprueban pgTAP y `deno test` quedan en `contracts/mercado.md`.

## Transiciones de estado

Ninguna: son tablas de referencia y de historia. Las barras no se modifican una vez guardadas.

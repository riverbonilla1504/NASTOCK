# Investigación (Research): HU-026 · Universo del NASDAQ-100 y carga histórica de barras

Cada punto lleva la decisión, por qué y qué alternativas se descartaron. Lo que sale de `docs/` lo cita; lo que es una elección técnica dentro de lo que `docs/` no fija se marca como **elección técnica** y va al informe de la historia.

## R1 · Cliente de Postgres para `_shared/bd.ts` (D-66)

- **Decisión**: `npm:postgres@3.4.9` (postgres.js), fijado con versión exacta en `supabase/functions/deno.json`. Una conexión por invocación (`max: 1`), `prepare: false`, `connect_timeout` corto, y `end()` al terminar.
- **Por qué**: es gratuito, funciona en el runtime de Supabase y acepta consultas con parámetros enlazados (`$1`, `$2`…) sin armar SQL con texto. `prepare: false` lo hace compatible con el *pooler* en modo transacción. `SUPABASE_DB_URL` lo entrega `supabase functions serve` (se comprobó en local: `postgresql://postgres:…@db:5432/postgres`).
- **Descartado**: la línea 4.x (4.0.0 salió el 2026-10-29: demasiado nueva para un MVP); `deno-postgres` (menos usado con Supabase); supabase-js (no alcanza `private`, ver D-66).

## R2 · Cómo `_shared/bd.ts` garantiza "solo funciones de `private`"

- **Decisión**: una sola operación, `llamar(funcion, argumentos)`. El nombre debe cumplir `^[a-z][a-z0-9_]*$`, se cita como identificador y se antepone `private.`; los argumentos van como parámetros enlazados. Un nombre con punto, comillas, espacios o `;` se rechaza antes de tocar la red. Los objetos y arreglos viajan como texto JSON para las funciones que reciben `jsonb`.
- **Por qué**: D-66 pide nombre validado y parámetros enlazados, nunca SQL armado con texto. Con una lista de funciones permitidas habría que tocar `bd.ts` en cada historia; las funciones `private` ya validan por su cuenta (`docs/06` §7, regla 3).
- **Descartado**: una lista cerrada de nombres (acopla `bd.ts` a todas las historias); exponer `sql` crudo (rompe D-66).

## R3 · Dónde se siembra la lista blanca

- **Decisión**: en una **migración** (así llega a la nube, donde `seed.sql` no corre).
- **Por qué**: CA-1 pide la lista "en la base recién creada" y `docs/10` §12 dice que la lista se siembra al iniciar el proyecto y después la mantiene el administrador. La tarea de la historia dice "Migración … y la semilla del universo con su sector".
- **Pendiente de confirmar**: `docs/05` §12 y `docs/15` §3 nombran la lista blanca bajo `seed.sql`. Ver "Decisiones por confirmar" en `plan.md`.

## R4 · Qué símbolos componen el universo

- **Decisión**: Usuarios: QLD y QQQ. Arriesgadas: TQQQ y las 101 acciones del NASDAQ-100 (Q-13 y Q-20, valores provisionales). La lista sale de la composición publicada por stockanalysis.com el 2026-11-05, contrastada con las posiciones de QQQ del mismo sitio (actualizadas el 2026-11-04). Alpaca no informa qué acciones forman el índice (`docs/10` §12).
- **Sector** (**elección técnica**): los once sectores GICS en inglés, como el ejemplo de `docs/07` §4.2. Los ETF quedan sin sector. Los sectores los asigné yo; los de las acciones más nuevas (SPCX, SNDK, MRNA, HONA, LITE, TER, ALAB, NBIS, RKLB, CRWV) están por confirmar.
- **Por qué**: `docs/` no fija la taxonomía. Los once sectores son estándar y los puede corregir el administrador (HU-036).
- **Descartado**: sectores en español (la IA recibe el sector en inglés); industrias más finas (más datos que mantener sin que `docs/` lo pida).

## R5 · Qué entra en el universo que se carga

- **Decisión**: los símbolos **activos** de cualquier bolsillo, más QQQ aunque no esté activo en ninguno (nota de `docs/06` §5.2 y de la historia). Función `private.simbolos_del_universo()`.
- **Por qué**: un símbolo desactivado ya no se ve ni se opera. QQQ es la referencia del índice y se ingiere siempre.

## R6 · Qué cuenta como "carga inicial" y cómo se evita duplicar (CA-2 y CA-3)

- **Decisión**: la carga pide, para cada símbolo del universo **sin historia suficiente**, las barras entre `hoy − 2 años` y **ayer** (hora de Nueva York). "Sin historia suficiente" = ninguna barra dentro de los primeros 7 días de la ventana (cubre fines de semana y feriados al inicio). Las barras se guardan con `on conflict (simbolo, fecha) do nothing`.
- **Por qué**: la fecha sale de `private.ahora()` (`docs/15` §3). Pedir hasta ayer evita guardar la barra parcial del día en curso, que corresponde a `cierre-diario` (HU-029). Repetir la carga, o correr el trabajo diario de HU-027, no duplica y no vuelve a descargar lo que ya está completo. La barra ya guardada no se reemplaza.
- **Descartado**: guardar siempre con `do update` (reescribiría historia y cambiaría el resultado de los indicadores sin avisar); contar con una marca de "carga hecha" por símbolo (otra tabla que `docs/06` no tiene).
- **Límite conocido**: un símbolo con menos de dos años de vida (una salida a bolsa reciente) nunca cumple la regla de los 7 días y se vuelve a pedir en cada ejecución. Es barato e inofensivo (no duplica).

## R7 · Cuándo corre `calendario-mercado`

- **Decisión**: HU-026 entrega la función y su carga inicial. Quien la dispara es el trabajo diario `calendario` de `docs/05` §7, que crea HU-027; mientras tanto se llama a mano con el secreto interno. No se crea ningún trabajo de `pg_cron` aquí.
- **Por qué**: la tarea de la historia es "Función `calendario-mercado`: carga inicial". El trabajo programado, el calendario y el reloj son de HU-027.

## R8 · Alpaca: qué se pide y cómo se lee

- **Decisión** (**elección técnica** en `adjustment` y `feed`): `GET {ALPACA_DATA_URL}/v2/stocks/bars?symbols=…&timeframe=1Day&start=…&end=…&limit=10000&adjustment=split&feed=iex&sort=asc`, con paginación por `next_page_token`; lotes de 20 símbolos. `feed=iex` porque `docs/10` §1 dice que el plan gratuito da IEX. `adjustment=split` para que un *split* no parezca una caída del 50 % en la media de 200 días. La fecha de la barra es el día en Nueva York de su `t`. Las llaves van en las cabeceras `APCA-API-KEY-ID` y `APCA-API-SECRET-KEY`, nunca en la URL.
- **Por qué**: `docs/10` §1 y §12 piden barras diarias de dos años del universo y no fijan estos parámetros.
- **Respuestas grabadas**: no hay llaves de Alpaca en esta sesión (ni deben usarse), así que las pruebas usan respuestas escritas a mano con la forma documentada de la API de Alpaca, no capturadas en vivo. La prueba real semanal (`docs/15` §6) las contrastará con la API de verdad.

## R9 · El proveedor simulado de mercado

- **Decisión**: caminata determinista, función pura de `(símbolo, fecha)`. Cada símbolo tiene una semilla que sale de sus letras; el retorno de cada día hábil sale de un generador congruencial entero (Park–Miller) sin estado, y el precio es el acumulado desde un ancla fija (2020-01-01). Los días hábiles son de lunes a viernes. QLD y TQQQ siguen a QQQ ×2 y ×3 cada día. Pedir un rango corto o uno largo da la misma barra para la misma fecha.
- **Por qué**: `docs/10` §9 pide una caminata aleatoria **determinista** (semilla fija). Ser función pura de la fecha hace que dos pedidos distintos coincidan y que el resultado se pueda comprobar con valores conocidos. QLD = 2 × QQQ permite probar la línea ×2 teórico (HU-031).
- **Sin feriados**: el simulado trata cada día de lunes a viernes como sesión. Los feriados los resuelve el calendario (HU-027).
- **`snapshots`**: precio intradía determinista a partir del cierre del día hábil anterior y de la hora (`ahora`, de `private.ahora()`).

## R10 · Un año de barras de prueba en `seed.sql`

- **Decisión**: `seed.sql` genera las barras con el **mismo algoritmo** del simulado, escrito en SQL, para la ventana fija 2025-11-03 a 2026-10-30. Dos pruebas con los mismos valores conocidos (una en pgTAP y otra en `deno test`) obligan a que las dos versiones coincidan.
- **Por qué**: `docs/15` §3 pide "un año de barras diarias de prueba". Con la misma fórmula no hay un salto entre las barras sembradas y las que carga el simulado. La ventana fija hace la semilla reproducible.
- **Descartado**: `random()` con `setseed` (las dos versiones no coincidirían); un archivo SQL de ~2 MB con las barras escritas.

## R11 · Seguridad de lectura y escritura

- **Decisión**: RLS activo; política de `select` para `authenticated`; sin políticas de escritura; además `revoke all … from anon, authenticated` y `grant select … to authenticated`, para que una escritura directa falle con "permiso denegado" y no se ignore en silencio.
- **Por qué**: CA-4 pide que la base "lo rechace". Con solo RLS, un `UPDATE` o un `DELETE` termina sin error y sin tocar filas.
- **Pendiente de confirmar**: la condición de "persona activa" (ver `plan.md`).

## R12 · Estado del servidor de funciones

- `supabase functions serve` entrega `SUPABASE_DB_URL`, `SUPABASE_URL` y las llaves de la plataforma (comprobado en local el 2026-11-05).
- Una función que solo acepta el secreto interno necesita `verify_jwt = false` en `config.toml` (`_shared/auth.ts`). El secreto llega a la función por la variable `SECRETO_INTERNO`. `supabase/functions/.env.e2e` todavía no la define (TT-06 arma el arnés que sirve las funciones y la agrega); la prueba servida de esta historia usa un archivo de entorno temporal fuera del repositorio con el valor de prueba de Vault en `seed.sql`.

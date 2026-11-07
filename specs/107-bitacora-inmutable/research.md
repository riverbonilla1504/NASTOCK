# Investigación (Fase 0): HU-107 · Bitácora inmutable con cadena de hash

No quedó ninguna duda que obligue a cambiar `docs/`. Estas son las decisiones de diseño que `docs/` no escribe literalmente y cómo se resolvieron sin cambiar ninguna regla. Las dos últimas (D-10 y D-11) eran observaciones que Javier resolvió después; cada una dice cómo.

## D-1 · `auditar` recibe más datos que los cinco de `docs/06` §8.2

- **Decisión**: `private.auditar(p_actor uuid, p_accion text, p_entidad text, p_entidad_id text, p_detalle jsonb default null, p_antes jsonb default null, p_despues jsonb default null, p_origen text default null) returns bigint`. Los cinco primeros son los de `docs/06` §8.2 y `docs/04` §6; los otros tres son opcionales.
- **Razón**: CA-1 y FR-218 piden registrar "valores anterior y nuevo y origen" y rol, y la tabla (`docs/06` §5.6) tiene esas columnas. Con parámetros opcionales al final, la llamada de cinco argumentos de `docs/04` §6 sigue siendo válida.
- **El rol del actor** (`actor_rol`) no se recibe: `auditar` lo lee de `perfiles` (el rol que la persona tiene al actuar). Así nadie puede declarar un rol que no tiene. Si el actor es nulo (sistema) o no tiene perfil, queda nulo.
- **El origen** (`app`, `sistema`, `cron`, `auth`) lo valida el `check` de la tabla. Si no se pasa: `sistema` cuando no hay actor y `app` cuando lo hay. Quien llama desde un trigger de Auth o desde `pg_cron` lo pasa explícito.
- **Alternativas**: exigir los ocho argumentos (descartada: rompe la llamada de `docs/04` §6); pasar `antes` y `despues` dentro de `detalle` (descartada: la tabla tiene columnas propias).

## D-2 · Formato exacto de la fórmula del hash

- **Decisión**: `hash = encode(sha256(convert_to(contenido, 'UTF8')), 'hex')`, donde el contenido es la unión, con el carácter de control `U+001F` (separador de unidad) entre campos, de: `hash_anterior`, `momento` en UTC con formato `YYYY-MM-DD"T"HH24:MI:SS.US"Z"`, `actor` (el `uuid` en texto), `actor_rol`, `accion`, `entidad`, `entidad_id`, `antes`, `despues` (los dos con `jsonb::text`), `detalle` (`jsonb::text`) y `origen`; un campo nulo entra vacío. El orden y la escritura de cada campo están en `docs/11` §4.3. El cálculo vive en `private.hash_auditoria(...)`.
- **Razón**: `docs/11` §4.3 y CA-2 dan los campos y el orden, no cómo se escriben. `momento::text` depende de la zona horaria de la sesión y concatenar sin separador permite mover un carácter entre dos campos sin cambiar el hash. El formato UTC fijo, el separador y el texto canónico de `jsonb` (ordena las claves) hacen el hash reproducible desde cualquier sesión. Una sola función para el cálculo evita que `auditar` y la verificación de HU-108 se desvíen.
- **Alternativas**: `‖` como `||` sin separador (descartada: ambigua); `pgcrypto.digest` (descartada: `sha256()` ya viene en Postgres y no hace falta la extensión).

## D-3 · Hash anterior del primer registro

- **Decisión**: 64 ceros (`repeat('0', 64)`).
- **Razón**: `hash_anterior` es `text not null` y el primer registro no tiene anterior. Con 64 ceros ambas columnas tienen el mismo formato (hex de 64 caracteres) y un `check` de formato sirve para las dos.
- **Alternativas**: cadena vacía (descartada: formato distinto).

## D-4 · Bloqueo y garantía de que dos inserciones no comparten `hash_anterior`

- **Decisión**: `auditar` ejecuta `lock table public.auditoria in share row exclusive mode` antes de leer el último hash; ese modo choca consigo mismo, así que las escrituras se serializan, y no bloquea las lecturas. Además, `hash_anterior` tiene un índice único: si un hueco del bloqueo (por ejemplo, una transacción `REPEATABLE READ` que no ve la fila recién confirmada) intentara bifurcar la cadena, la inserción fallaría en lugar de crear dos hijos del mismo registro.
- **Razón**: `docs/11` §4.3 pide "un bloqueo para que dos inserciones simultáneas no usen el mismo `hash_anterior`". El bloqueo de tabla no depende de una clave arbitraria de bloqueo asesor que otro código podría reutilizar. El índice único convierte la garantía en una restricción de la base de datos.
- **Alternativas**: `pg_advisory_xact_lock` con una clave fija (descartada: la clave podría chocar con otra); fila "cabeza" aparte (descartada: una tabla más sin pedirlo `docs/`).
- **Orden de la cadena**: `id` (`bigserial`) crece en el orden del bloqueo, así que el orden por `id` es el orden de la cadena. Una transacción revertida deja huecos en `id`, no en la cadena.

## D-5 · Privilegios: también se revoca a `service_role`

- **Decisión**: `revoke all` sobre la tabla y sobre su secuencia a `public`, `anon`, `authenticated` y `service_role`; luego `grant select` solo a `authenticated`. Sin políticas de escritura.
- **Razón**: Supabase concede por defecto todos los privilegios sobre las tablas nuevas de `public` a `service_role`, que además salta RLS. CA-3 exige rechazar la escritura "incluida la llave secreta". Sin el privilegio, el rechazo es `42501` y la prueba lo puede afirmar (con solo RLS sería silencioso).
- **Alternativas**: dejar `service_role` con sus privilegios y confiar en el trigger (descartada: el trigger no cubre `INSERT`).

## D-6 · Lectura solo del Administrador

- **Decisión**: política `auditoria_lectura` (select, `authenticated`) con `using ((select private.rol_actual()) = 'administrador')`. `authenticated` tiene `select` sobre la tabla; la política es la que deja sin filas al Usuario, al Analista y a toda cuenta no activa.
- **Razón**: matriz de `docs/03` §4.3 (`auditoria`: —, —, ✅) y PM-60. CA-5 pide "no recibe filas", no un error.
- **Alternativas**: sin `select` para `authenticated` y una función de lectura (descartada: HU-108 decide cómo consulta; la política de la matriz es lo que pide `docs/03`).

## D-7 · El trigger también rechaza `TRUNCATE`

- **Decisión**: un solo trigger `auditoria_inmutable`, `before update or delete or truncate`, **por sentencia**, que lanza `auditoria: la bitácora es inmutable (<operación> no permitido)`.
- **Razón**: `docs/11` §4.3 pide rechazar "cualquier `UPDATE` o `DELETE`", "incluso de la llave secreta". Un trigger por sentencia rechaza también un `UPDATE` o `DELETE` que no alcanzaría ninguna fila (uno por fila lo dejaría pasar en silencio), y cubre `TRUNCATE`, que no dispara triggers por fila y vaciaría de golpe una bitácora "inmutable". Cierra ese hueco con la misma función, sin ninguna regla nueva.
- **Alternativas**: trigger por fila para `UPDATE` y `DELETE` (descartada: deja pasar las sentencias de cero filas y no cubre `TRUNCATE`); solo `UPDATE` y `DELETE` (descartada: deja el borrado total).
- **Error**: texto libre `auditoria: …`, como el resto de las funciones de `private` ya existentes; no es un código de `docs/06` §9 porque ningún rol de la API llega al trigger (antes falla por privilegios).

## D-8 · Cómo se prueba cada criterio

| Criterio | Cómo |
|---|---|
| CA-1 | pgTAP `06_`: `auditar` guarda momento, actor, rol (leído de `perfiles`), acción, entidad, id, antes, después y origen, con un actor Administrador, con el sistema y con el origen explícito. El momento es el de `private.ahora()` con el reloj fijado. |
| CA-2 | pgTAP `06_`: el primer registro tiene 64 ceros; cada `hash_anterior` es el `hash` del registro previo; el `hash` coincide con `sha256` de la fórmula de los once campos escrita a mano en la prueba; cambiar cualquiera de los once campos cambia el hash; el hash no cambia con la zona horaria de la sesión. Concurrencia: con `dblink`, una segunda conexión que llama a `auditar` queda bloqueada por la primera (`pg_blocking_pids`) y se cancela antes de confirmar nada; el índice único rechaza un segundo hijo del mismo hash. |
| CA-3 | pgTAP `05_` y `07_`: `INSERT`, `UPDATE`, `DELETE` y `TRUNCATE` directos fallan con `42501` para `anon`, `authenticated` (cada rol) y `service_role`; el trigger rechaza `UPDATE`, `DELETE` y `TRUNCATE` incluso con el rol dueño; la función `auditar` no la ejecutan los roles de la API. |
| CA-4 | pgTAP `06_`: con un token y un cuerpo de respuesta de Google en la sesión, `auditar` solo guarda lo que recibe; un barrido de todas las filas de la prueba no encuentra formas de llave, token ni claves `access_token`, `refresh_token`, `id_token`, `provider_token`. |
| CA-5 | pgTAP `05_`: un Usuario, un Analista, una cuenta suspendida y una sesión sin perfil cuentan 0 filas; el Administrador las ve todas; `anon` recibe `42501`. |

## D-9 · Diferencias menores con el pseudo-DDL de `docs/06` §5.6

`docs/06` abre diciendo que sus definiciones son pseudo-DDL y que "las migraciones reales agregan índices, comentarios y políticas". Se mantienen todos los nombres y tipos; cambian estos detalles:

- `id` es `bigint generated always as identity` en lugar de `bigserial`: mismo tipo y mismo orden, pero nadie puede fijar un `id` a mano.
- `momento` no tiene `default now()`: lo pone siempre `auditar` con `private.ahora()` (así el reloj controlable de CI sirve también aquí).
- Se agregan `check` de acción y entidad no vacías, `check` de formato hexadecimal de 64 caracteres para los dos hashes y el índice único de `hash_anterior` (D-4).

## D-10 · Resuelta: el hash cubre todos los campos del registro

- **Qué pasaba**: la fórmula de `docs/11` §4.3 y de CA-2 solo incluía `hash_anterior`, `momento`, `actor`, `accion`, `entidad`, `id` y `detalle`. Cambiar `antes`, `despues`, `actor_rol` u `origen` de un registro no habría roto la cadena.
- **Decisión (Javier, 2026-11-06)**: la fórmula incluye todos los campos que guarda el registro, en este orden fijo: `hash_anterior`, `momento`, `actor`, `actor_rol`, `accion`, `entidad`, `id`, `antes`, `despues`, `detalle` y `origen`. Se cambió `docs/11` §4.3 y CA-2 (historia, spec), con la fila 3.13 en el historial de `docs/13` §4. `private.hash_auditoria` recibe los once campos y `auditar` le pasa el rol y el origen que ya calculó.
- **Razón**: la cadena detecta ahora la alteración de cualquier columna, no solo de las siete de la fórmula original.

## D-11 · Resuelta: la llamada de `docs/04` §6 pasaba un `uuid` como identificador

- **Qué pasaba**: `docs/04` §6 llamaba `private.auditar(new.id, 'cuenta.activada', 'perfiles', new.id, …)` con `uuid` en el cuarto argumento, pero `auditoria.entidad_id` es `text` (cualquier entidad: símbolos, claves de parámetros, números) y Postgres no convierte `uuid` a `text` solo al resolver una función.
- **Decisión (Javier, 2026-11-06)**: `p_entidad_id text` y el ejemplo de `docs/04` §6 pasa `new.id::text`. Además `docs/06` §8.2 muestra la firma completa de `auditar`.

## D-12 · Sin filtro de claves en `detalle`

- **Decisión (Javier, 2026-11-06)**: no se agrega ningún filtro por nombre de clave. CA-4 se cumple porque `auditar` solo guarda lo que recibe (nada de la sesión) y las pruebas lo comprueban; quien llama no pasa llaves, tokens ni respuestas de Google (`docs/11` §4.1).

# Plan de implementación (Implementation Plan): HU-026 · Universo del NASDAQ-100 y carga histórica de barras

**Branch**: `026-universo-y-carga-historica` | **Date**: 2026-11-05 | **Spec**: [spec.md](spec.md)

**Input**: Especificación de [`spec.md`](spec.md), historia [`HU-026`](../../backlog/E-04-datos-de-mercado/HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md), issue #45.

## Resumen (Summary)

La base recién creada trae la lista blanca con el universo (QLD y QQQ en Usuarios; TQQQ y los componentes del NASDAQ-100 en Arriesgadas, con nombre y sector) y las tablas `barras_diarias` y `barras_minuto`. Una Edge Function, `calendario-mercado`, carga dos años de barras diarias de cada símbolo del universo desde el proveedor de mercado (Alpaca, o el simulado en local y CI) y puede correr varias veces sin duplicar.

Se construye por capas, cada una con sus pruebas: **migración** (tablas, RLS, semilla) → **funciones `private`** (leer el universo, guardar barras sin duplicar) → **Edge Function** (adaptador de mercado, `_shared/bd.ts` y `calendario-mercado`). Es la primera historia que usa D-66: la función habla con la base por **conexión directa** (`SUPABASE_DB_URL`) y solo ejecuta funciones de `private`.

## Contexto técnico (Technical Context)

**Language/Version**: SQL (Postgres 17) y TypeScript en Deno (Edge Functions de Supabase, compatibles con Deno 2.1).

**Primary Dependencies**: `zod@3.23.8` (ya fijada) para validar lo que llega del proveedor; **`npm:postgres@3.4.9`** (postgres.js, gratuito) para la conexión directa, fijada con versión exacta en `supabase/functions/deno.json`. La línea 4.x salió hace días (4.0.0 el 2026-10-29) y no se adopta en un MVP.

**Storage**: Postgres de Supabase. Tablas nuevas `lista_blanca`, `barras_diarias`, `barras_minuto` (`docs/06` §5.2) y el tipo `bolsillo` (`docs/06` §3).

**Testing**: pgTAP (`supabase test db`) para tablas, RLS, semilla y funciones `private`; `deno test` para `_shared/bd.ts`, los adaptadores de mercado (respuestas grabadas), el simulado y la lógica de `calendario-mercado` con una base y un proveedor falsos.

**Target Platform**: Supabase local (Docker) y CI; la nube con `db push` y `functions deploy` (TT-08).

**Project Type**: Backend (base de datos + Edge Functions). La app no cambia: HU-030 muestra el mercado.

**Performance Goals**: la carga inicial de ~103 símbolos × ~500 barras entra en los 120 s de `calendario-mercado` (`docs/05` §6) y en 2 s de CPU por invocación (`docs/05` §3.4): se pide a Alpaca en lotes de 20 símbolos y se guarda un lote por llamada a la base. Si el tiempo se acaba, la función devuelve los símbolos pendientes y la siguiente ejecución los retoma.

**Constraints**: solo funciones de `private` desde las Edge Functions (D-66); nada de llaves reales: todo con el proveedor simulado (`ENTORNO=ci`); `lista_blanca` sin escrituras directas (las hará `actualizar_lista_blanca`, HU-036); sin SQL armado con texto en `_shared/bd.ts`.

**Scale/Scope**: 103 símbolos (101 acciones del índice, QQQ, QLD y TQQQ) × 2 años ≈ 52 mil barras diarias (unos 5 MB, `docs/06` §10).

## Revisión de la constitución (Constitution Check)

*Puerta antes de la investigación; se repite tras el diseño.*

| Principio / invariante | ¿Cumple? | Cómo |
|---|---|---|
| I · `docs/` es la fuente de verdad | Sí | Cada tabla y columna sale de `docs/06` §5.2. Las tres funciones `private` nuevas y `_shared/bd.ts` se agregan a `docs/06` §8.2, `docs/05` §6 y `docs/17`. |
| II · Documentación primero | Sí | D-66 ya está en `docs/` (primer commit de la rama). Los dos puntos que faltaban se confirmaron con Javier (ver "Decisiones confirmadas"). |
| III · Sincronía | Sí | No hay historias que citen supabase-js ni la llave secreta para escribir. Las que dicen "incluida la llave secreta" (HU-013, HU-107) hablan de un intento de escritura directa y siguen siendo válidas. |
| IV · Investigación acotada | Sí | Módulos M-05, M-19 y M-20 (`docs/17`). |
| V · Errores conocidos | Sí | Se busca en `docs/errores-conocidos.md` por módulo; se anota lo que cueste más de un intento. |
| VI · Funcionando de punta a punta | Sí | pgTAP + `deno test` + `scripts/verificar.sh` completo. La historia no tiene escenario E2E propio (15 §4) y `supabase/tests/e2e/` aún no existe (TT-06): el recorrido servido contra la base real se documenta en `quickstart.md`. |
| VII · Alcance y costo | Sí | `postgres` es de código abierto y gratuito; Alpaca paper es gratis; nada de dinero real. |
| Inv. 1 · La IA no ejecuta | Sí | `calendario-mercado` no importa `_shared/broker/`. |
| Inv. 4 · Escrituras de la app solo por RPC, RLS en `public` | Sí | RLS activo; `authenticated` solo `select`; ni la app ni la API escriben. |
| Inv. 5 · La autorización lee `perfiles` | Sí, cuando entre HU-001 | Las políticas de lectura usan `(select private.rol_actual()) is not null` y la llave foránea de `actualizado_por` apunta a `perfiles`. Van en una migración posterior a HU-001 (HU-001 pasa a "Depende de" en la historia). Mientras tanto las tablas quedan cerradas: RLS activo y ninguna política. |
| Inv. 6 · Ninguna llave | Sí | La función lee `ALPACA_*` del entorno solo con el proveedor real; los errores nunca copian llaves, URL de conexión ni contraseñas. |
| Inv. 8 · Simulados solo en local y CI | Sí | `elegirProveedor("mercado", …)` de TT-05 se niega a simular con `ENTORNO=mvp`. |
| Inv. 9 · Migraciones solo hacia adelante | Sí | Dos migraciones nuevas con `supabase migration new`. |

### Decisiones confirmadas (Javier, 2026-11-06)

1. **Lectura de "persona activa" (CA-4): opción B, sin relajar.** Las políticas de `lista_blanca`, `barras_diarias` y `barras_minuto` usan `(select private.rol_actual()) is not null` (`docs/03` §4.2 y §4.3) y `lista_blanca.actualizado_por` lleva su llave foránea a `perfiles`. Como `private.rol_actual()` es de HU-001, que aún no está en `main`, HU-001 se agregó a "Depende de" de la historia y esas dos piezas van en una migración posterior (`*_lectura_del_mercado.sql`) que se agrega cuando HU-001 esté en `origin/main`. Hasta entonces las tablas no tienen ninguna política: nadie lee.
2. **La semilla de la lista blanca va en una migración**, para que llegue a la nube. `docs/05` §12 y `docs/15` §3 ya no la ubican en `seed.sql` (13 §4, versión 3.11). Los parámetros por defecto y la configuración de decisión v1 siguen en `seed.sql`: los decide la historia que los crea.

## Estructura del proyecto (Project Structure)

### Documentación de esta historia

```text
specs/026-universo-y-carga-historica/
├── plan.md              # Este archivo
├── research.md          # Decisiones técnicas
├── data-model.md        # Tablas, funciones y datos de la semilla
├── quickstart.md        # Cómo comprobarlo de punta a punta
├── contracts/           # Funciones private, calendario-mercado, interfaz de mercado y _shared/bd.ts
└── tasks.md             # Lo genera /speckit-tasks
```

### Código fuente (raíz del repositorio)

```text
supabase/
├── migrations/
│   ├── <fecha>_lista_blanca_y_barras.sql        # tipo bolsillo, 3 tablas, RLS, semilla del universo
│   └── <fecha>_funciones_de_mercado.sql         # private.simbolos_del_universo, simbolos_sin_historia, guardar_barras_diarias
├── seed.sql                                      # + un año de barras diarias de prueba
├── config.toml                                   # + [functions.calendario-mercado] verify_jwt = false
├── tests/database/
│   └── 02_universo_y_barras_test.sql             # pgTAP: tablas, RLS, semilla, funciones
└── functions/
    ├── deno.json                                 # + "postgres": "npm:postgres@3.4.9"
    ├── _shared/
    │   ├── bd.ts · bd_test.ts                    # única puerta a Postgres (D-66)
    │   └── mercado/
    │       ├── interfaz.ts                       # ProveedorDeMercado: snapshots y barras
    │       ├── alpaca.ts · alpaca_test.ts · fixtures/
    │       ├── simulado.ts · simulado_test.ts
    │       └── mod.ts                            # crearProveedorDeMercado() con elegirProveedor
    └── calendario-mercado/
        ├── index.ts                              # Deno.serve + conexión de las piezas reales
        ├── manejador.ts · manejador_test.ts      # autenticación, respuesta y errores
        └── carga_historica.ts · carga_historica_test.ts   # la carga, con base y proveedor inyectados
scripts/verificar.sh · .github/workflows/ci.yml   # ya tienen la búsqueda de D-66 (primer commit)
docs/05, 06, 15, 17                               # rutas y funciones nuevas
```

**Structure Decision**: se sigue el catálogo de `docs/05` §6 (`_shared/mercado/` con interfaz, `alpaca.ts` y `simulado.ts`; una carpeta por función) y la estructura de `docs/05` §12. La lógica va fuera de `index.ts` para probarla sin levantar `Deno.serve`.

## Seguimiento de complejidad (Complexity Tracking)

Sin violaciones de la constitución que justificar.

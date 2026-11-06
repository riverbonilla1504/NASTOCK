---

description: "Tareas de HU-026 · Universo del NASDAQ-100 y carga histórica de barras"
---

# Tareas (Tasks): HU-026 · Universo del NASDAQ-100 y carga histórica de barras

**Input**: documentos de `specs/026-universo-y-carga-historica/` (`plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`) y la sección "Tareas" de la historia.

**Pruebas**: la historia las pide (pgTAP y `deno test`), así que cada capa lleva las suyas. La historia no tiene escenario E2E propio (15 §4).

**Organización**: hay una sola historia de usuario (US1) y se construye por capas, como pide `CLAUDE.md`: migración → funciones `private` → Edge Functions. Antes de cualquier comando `supabase` o de `scripts/verificar.sh` se toma el candado `C:/Users/Javier/.nastock-supabase-candado` y se suelta al terminar el bloque.

## Formato: `[ID] [P?] [Story] Descripción`

- **[P]**: se puede hacer en paralelo (archivos distintos, sin depender de una tarea pendiente).
- **[US1]**: la única historia de usuario.

## Fase 1: Preparación (Setup)

- [x] T001 Agregar `"postgres": "npm:postgres@3.4.9"` a `imports` en `supabase/functions/deno.json` y regenerar `supabase/functions/deno.lock` (versión exacta, research R1).
- [x] T002 [P] Agregar `[functions.calendario-mercado]` con `verify_jwt = false` en `supabase/config.toml` (la función solo acepta el secreto interno, `_shared/auth.ts`).

## Fase 2: Fundamentos (Foundational, bloquea la fase 3)

**Propósito**: la puerta a la base (D-66), los tipos del proveedor de mercado y el simulado, cuyos valores conocidos fijan la semilla de barras y sus pruebas.

- [x] T003 [P] Crear `supabase/functions/_shared/bd.ts` con `crearBd`, `Bd.llamar`, `Bd.cerrar` y `ErrorDeBd`, según `contracts/bd.md`: nombre `^[a-z][a-z0-9_]*$`, consulta `select * from private."<nombre>"($1…$n)` con argumentos enlazados, `max: 1`, `prepare: false`, errores sin URL ni contraseña. Es el único archivo que importa `postgres`.
- [x] T004 [P] Crear `supabase/functions/_shared/bd_test.ts`: nombres válidos e inválidos (`.`, `"`, `;`, espacios, mayúsculas, vacío) sin llamar al ejecutor, argumentos enlazados en orden, objeto a JSON, sin URL nombra `SUPABASE_DB_URL`, un fallo de conexión no filtra la URL ni la contraseña.
- [x] T005 [P] Crear `supabase/functions/_shared/mercado/interfaz.ts` con `Barra`, `Cotizacion`, `ProveedorDeMercado` (`snapshots` y `barras`) y `ErrorDeProveedor`, según `contracts/mercado.md`.
- [x] T006 Crear `supabase/functions/_shared/mercado/simulado.ts` (`MercadoSimulado`) según `contracts/mercado.md`: función pura de `(símbolo, fecha)`, solo lunes a viernes, QLD y TQQQ como 2× y 3× de QQQ, `snapshots` determinista por hora. Anotar en `contracts/mercado.md` los valores conocidos que compartirán T007, T011 y T015. Depende de T005.
- [x] T007 [P] Crear `supabase/functions/_shared/mercado/simulado_test.ts`: determinismo, mismo resultado para rangos distintos, solo días hábiles, coherencia de cada barra (máximo ≥ apertura y cierre ≥ mínimo, mínimo > 0), QLD = 2 × QQQ y TQQQ = 3 × QQQ en retorno diario, valores conocidos, `snapshots` iguales para la misma hora y distintos para otra.

**Punto de control**: `deno test` de `_shared/bd_test.ts` y `_shared/mercado/simulado_test.ts` en verde.

**Puerta (documentación primero)**: antes de T008 se confirman con la sesión coordinadora las dos decisiones de `plan.md` (condición de lectura de "persona activa" y dónde se siembra la lista blanca). T008 y T009 siguen lo que se confirme.

## Fase 3: Historia de usuario 1 · Universo y carga histórica (Prioridad: P1)

**Meta**: la base recién creada trae el universo y las tablas de barras, y `calendario-mercado` carga dos años de barras diarias sin duplicar.

**Prueba independiente**: pgTAP de la capa de base de datos, `deno test` de las funciones y la prueba servida del `quickstart.md` §3.

### Capa 1 · Migración (tablas, RLS, semilla) — CA-1, CA-4

- [x] T008 [US1] Crear con `supabase migration new lista_blanca_y_barras` la migración: tipo `public.bolsillo` (`reserva`, `arriesgadas`, `usuarios`); tablas `public.lista_blanca` (`check (bolsillo <> 'reserva')`, llave `(bolsillo, simbolo)`, `en_nasdaq100 boolean not null default false`, `activo boolean not null default true`, `actualizado_por uuid` sin llave foránea, `actualizado_en timestamptz not null default now()`), `public.barras_diarias` (llave `(simbolo, fecha)`) y `public.barras_minuto` (llave `(simbolo, momento)`) con precios `numeric(14,4)`, `volumen bigint not null check (volumen >= 0)`, `minimo > 0`, `maximo >= greatest(apertura, cierre, minimo)` y `minimo <= least(apertura, cierre, maximo)`; RLS activo; `revoke all … from public, anon, authenticated` y `grant select … to authenticated` sin ninguna política de lectura (esa y la llave foránea de `actualizado_por` llegan en T029); comentarios en tablas y columnas.
- [x] T009 [US1] En la misma migración (T008), sembrar `lista_blanca` con las 104 filas de `data-model.md`: `usuarios` QLD y QQQ; `arriesgadas` TQQQ y las 101 acciones del NASDAQ-100 con `en_nasdaq100 = true`, `nombre` y `sector` GICS en inglés; ETF con `sector` nulo.
- [x] T010 [US1] Agregar a `supabase/seed.sql` un bloque con las barras diarias de prueba de los 104 símbolos para 2025-11-03 a 2026-10-30 (260 días hábiles), con el algoritmo de `contracts/mercado.md` en SQL (generador entero sin estado, acumulado desde el ancla 2020-01-01, QLD y TQQQ como 2× y 3× de QQQ, redondeo final a 4 decimales). Depende de T006 y T008.
- [x] T011 [US1] Crear `supabase/tests/database/02_universo_y_barras_test.sql` (pgTAP) para esta capa: existencia del tipo y las tablas; RLS activo; `anon` sin permisos; `authenticated` solo `select` (`insert`, `update` y `delete` fallan con `42501`); CA-1 (usuarios = QLD y QQQ; arriesgadas = TQQQ + 101 con nombre y sector no vacíos; `reserva` rechazado por el `check`); CA-4 (lectura como `authenticated`, escritura directa rechazada); barras sembradas (104 símbolos × 260 días, coherentes, valores conocidos de T006).

### Capa 2 · Funciones `private` — CA-2, CA-3

- [x] T012 [US1] Crear con `supabase migration new funciones_de_mercado` la migración con `private.simbolos_del_universo()`, `private.simbolos_sin_historia(p_desde date)` y `private.guardar_barras_diarias(p_datos jsonb)` según `contracts/funciones-private.md`: `security definer`, `set search_path = ''`, `on conflict (simbolo, fecha) do nothing`, `revoke all … from public, anon, authenticated`.
- [x] T013 [US1] Agregar a `02_universo_y_barras_test.sql` las pruebas de las tres funciones: QQQ siempre en el universo (aunque esté inactivo), un símbolo inactivo fuera, `simbolos_sin_historia` lista a los de un solo año y deja de listar al que recibe una barra en la primera semana de la ventana, `guardar_barras_diarias` inserta y devuelve la cantidad (CA-2), repetir devuelve `0` y no duplica (CA-3), un valor que no es arreglo falla, una barra incoherente falla con `23514` y no guarda el lote, `anon` y `authenticated` no pueden ejecutarlas.

**Punto de control**: con el candado, `supabase db reset` y `supabase test db` en verde.

### Capa 3 · Edge Functions — CA-2, CA-3

- [x] T014 [P] [US1] Crear `supabase/functions/_shared/mercado/alpaca.ts` (`MercadoAlpaca`) según `contracts/mercado.md`: lotes, paginación por `next_page_token`, cabeceras de llaves, validación con zod, descarte de barras incoherentes, fecha en Nueva York, tiempo de espera de 15 s y `ErrorDeProveedor` sin llaves en el mensaje.
- [x] T015 [P] [US1] Crear `supabase/functions/_shared/mercado/alpaca_test.ts` y `supabase/functions/_shared/mercado/fixtures/` (respuestas grabadas con la forma documentada de la API, no capturadas en vivo): una página, dos páginas, vacía, con una barra incoherente, `snapshots`, errores 401/403/429/500, llaves solo en cabeceras, símbolos en lotes.
- [x] T016 [US1] Crear `supabase/functions/_shared/mercado/mod.ts` con `crearProveedorDeMercado(leer?)`, que usa `elegirProveedor<ProveedorDeMercado>("mercado", { simulado, alpaca })` de `_shared/proveedores.ts` y lee `ALPACA_KEY_ID`, `ALPACA_SECRET_KEY` y `ALPACA_DATA_URL` solo si el proveedor es `alpaca`; agregar su prueba (se niega con `ENTORNO=mvp` y `PROVEEDOR_MERCADO=simulado`; el simulado se elige por defecto; el real exige llaves).
- [x] T017 [US1] Crear `supabase/functions/calendario-mercado/carga_historica.ts` con la carga: `ahora` de `private.ahora()` (con `bd.llamar("ahora")` llega una fila `{ ahora: Date }`), `desde` y `hasta` en hora de Nueva York, `simbolos_sin_historia`, lotes de 20, `guardar_barras_diarias`, presupuesto de 100 s, `pendientes` y conteos, con `Bd` y `ProveedorDeMercado` inyectados.
- [x] T018 [P] [US1] Crear `supabase/functions/calendario-mercado/carga_historica_test.ts` con base y proveedor falsos: solo los símbolos sin historia, lotes de 20, fechas en Nueva York (incluida una hora de las 02:00 UTC), segunda ejecución sin pedir ni duplicar (CA-3), presupuesto de tiempo agotado, fallo del proveedor con lo ya guardado.
- [x] T019 [US1] Crear `supabase/functions/calendario-mercado/manejador.ts` con `crearManejador({ mercado, abrirBd, secreto })`: solo `POST`; autenticación con `autenticar` de `_shared/auth.ts` (`aceptaInterno: true`, sin roles de persona); respuestas `200`, `401`, `403`, `405` y `502 INTEGRACION_CAIDA` según `contracts/calendario-mercado.md`; cierra la base en `finally`.
- [x] T020 [P] [US1] Crear `supabase/functions/calendario-mercado/manejador_test.ts`: secreto correcto, incorrecto, ausente, con JWT, método distinto de `POST`, error del proveedor, y que la base se cierra siempre.
- [x] T021 [US1] Crear `supabase/functions/calendario-mercado/index.ts`: llama a `crearProveedorDeMercado()` al cargar el módulo (fuera del manejador, para que una configuración inválida impida arrancar) y `Deno.serve(crearManejador({ … abrirBd: () => crearBd() … }))`.
- [x] T022 [US1] Con el candado, servir la función con un archivo de entorno temporal (fuera del repositorio) y ejecutar `quickstart.md` §3: primera llamada carga y devuelve `pendientes: []`; la segunda no duplica; sin cabecera `401`; secreto equivocado `403`. Anotar los resultados para el informe.

**Punto de control**: `deno fmt --check`, `deno lint` y `deno test` de `supabase/functions` en verde.

## Fase 4: Cierre (Polish y transversales)

- [x] T023 Agregar a `docs/06` §8.2 las filas de `simbolos_del_universo()`, `simbolos_sin_historia(desde)` y `guardar_barras_diarias(datos)`.
- [x] T024 Actualizar `docs/17`: M-05 (tablas `lista_blanca`, `barras_diarias`, `barras_minuto`; funciones `private`; `calendario-mercado`; `_shared/mercado/`; pruebas) y M-20 (`_shared/bd.ts`, `deno.json` con `postgres`, `config.toml`, búsqueda de arquitectura de D-66).
- [x] T025 Corregir `docs/05` §12 y `docs/15` §3 (la lista blanca la siembra una migración) y anotarlo en `docs/13` §4 con la versión 3.11 de D-66; agregar HU-001 a "Depende de" de la historia en `backlog/`.
- [x] T026 `git fetch origin && git rebase origin/main`; si `main` trae migraciones más nuevas, renombrar las propias con la fecha y hora actuales; ajustar el número del historial de `docs/13` §4 si cambió.
- [x] T027 Con el candado, correr `scripts/verificar.sh` completo y dejarlo en verde.
- [x] T028 Escribir el cuerpo del PR con `.github/pull_request_template.md` y "Closes #45" en `C:\Users\Javier\Desktop\pr-026-universo-y-carga-historica.md` (fuera del repositorio), indicando que el PR cambia una regla de `docs/` (D-66).

## Fase 5: Cuando HU-001 esté en `origin/main` (Javier, 2026-11-06)

- [ ] T029 `git fetch origin && git rebase origin/main`; crear con `supabase migration new lectura_del_mercado` la migración con la llave foránea `lista_blanca_actualizado_por_fkey` a `public.perfiles (id)` y las tres políticas de `select` para `authenticated` con `using ((select private.rol_actual()) is not null)`; agregar a `02_universo_y_barras_test.sql` las cuentas de prueba (activa en los tres roles, suspendida, de baja y sin perfil) y las comprobaciones de CA-4; volver a correr `scripts/verificar.sh` completo con el candado. La migración y la prueba ya están armadas y comprobadas contra las migraciones de HU-001 en la carpeta de notas compartidas.

## Dependencias y orden

- T001 y T002 primero. T003–T007 bloquean la fase 3; T006 depende de T005.
- Puerta de las dos decisiones de `plan.md` antes de T008.
- Capa 1: T008 → T009 (misma migración) → T010 (también depende de T006) → T011.
- Capa 2: T012 después de T008; T013 después de T011 y T012.
- Capa 3: T014 y T015 se pueden hacer desde la fase 2; T016 después de T006 y T014; T017 después de T003, T005 y T012; T018 después de T017; T019 después de T017; T020 después de T019; T021 después de T016 y T019; T022 después de T021.
- Los valores conocidos de T006 los usan T007, T011 y T015: se calculan una vez y se anotan en `contracts/mercado.md`.

## Oportunidades de paralelismo

- T003, T004 y T005 (archivos distintos).
- T007 con T014 y T015 (simulado y Alpaca, cada uno con su prueba).
- T018 y T020 (pruebas con falsos, después de sus módulos).

## Estrategia de implementación

1. Fase 1 y 2: la puerta a la base, los tipos y el simulado (sus valores conocidos fijan la semilla de barras).
2. Capa 1 y 2 en la base, con el candado: es lo que cierra CA-1, CA-3 (a nivel de función) y CA-4.
3. Capa 3: Alpaca, la carga y la función.
4. Prueba servida (T022), documentación (T023–T025) y verificación completa (T027).

## Notas

- `[P]` = archivos distintos y sin dependencias pendientes.
- No se edita `docs/errores-conocidos.md`: si un error merece entrada, va al informe final.
- Ningún commit lleva `Co-Authored-By` ni firmas de la herramienta; los mensajes van en español, en imperativo, con `(#45)`.

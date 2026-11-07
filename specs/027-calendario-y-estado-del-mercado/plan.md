# Plan de implementación (Implementation Plan): HU-027 · Calendario, reloj y estado del mercado

**Branch**: `027-calendario-y-estado-del-mercado` | **Date**: 2026-11-06 | **Spec**: [spec.md](spec.md)

**Input**: Especificación de [`spec.md`](spec.md), historia [`HU-027`](../../backlog/E-04-datos-de-mercado/HU-027-calendario-reloj-y-estado-del-mercado.md), issue #46.

## Resumen (Summary)

El mercado opera según el calendario del broker, que se sincroniza a diario y nunca se programa a mano (RN-41). La historia entrega: la tabla `calendario_mercado` (apertura y cierre ya en UTC), las funciones de horario sobre `private.ahora()` (`mercado_abierto`, `mercado_en_ventana`, `ventana_compras_abierta`), la RPC `estado_mercado()` y la sincronización diaria: `calendario-mercado` (que ya carga barras desde HU-026) ahora también trae el calendario y el reloj del broker y los atributos `fraccionable` y `negociable` de la lista blanca, y desactiva el símbolo que deja de ser negociable. Un trabajo de `pg_cron` lo despierta cada día a las 10:00 UTC.

Se construye por capas, cada una con sus pruebas: **migración** (tabla y RLS) → **funciones `private`** (horario, guardar calendario, guardar atributos) → **RPC `estado_mercado()`** → **Edge Function** (operaciones `calendario`, `reloj` y `activos` de `_shared/broker/`, y ampliación de `calendario-mercado`) → **trabajo `calendario`**.

## Contexto técnico (Technical Context)

**Language/Version**: SQL (Postgres 17) y TypeScript en Deno (Edge Functions, Deno 2.1).

**Primary Dependencies**: ninguna nueva. `zod@3.23.8` valida las respuestas de Alpaca; `_shared/bd.ts` (D-66) es la única puerta a la base; `_shared/proveedores.ts` elige broker real o simulado.

**Storage**: Postgres de Supabase. Tabla nueva `calendario_mercado` (`docs/06` §5.2); `lista_blanca` ya existe (HU-026) y recibe `fraccionable`, `negociable`, `sincronizado_en` y la baja de `activo`.

**Testing**: pgTAP (`supabase test db`) con el reloj fijado (`pruebas.fijar_reloj`) para feriado, media jornada, cambio de horario y ventana; `deno test` para el adaptador real (respuestas grabadas), el simulado y `calendario-mercado` con base y broker falsos.

**Target Platform**: Supabase local (Docker) y CI; la nube con `db push` y `functions deploy` (TT-08).

**Project Type**: Backend (base de datos + Edge Functions). La app no cambia: HU-030 muestra el mercado.

**Performance Goals**: `calendario-mercado` dura como máximo 120 s (`docs/05` §6). Calendario y reloj son 2 llamadas; los atributos son una llamada por símbolo (~103), en tandas de 10 en paralelo, muy por debajo del límite de 200 por minuto de Alpaca. La carga de barras de HU-026 recibe como presupuesto lo que queda de los 100 s.

**Constraints**: solo funciones de `private` desde las Edge Functions (D-66); nada de llaves reales (todo con el broker simulado, `ENTORNO=ci`); `agente`, `contexto-ia` y `opinion-ia` no importan `_shared/broker/`; toda la lógica toma la hora de `private.ahora()`; `calendario_mercado` y `lista_blanca` sin escrituras directas.

**Scale/Scope**: ~45 días de calendario por sincronización; 103 símbolos.

## Revisión de la constitución (Constitution Check)

| Principio / invariante | ¿Cumple? | Cómo |
|---|---|---|
| I · `docs/` es la fuente de verdad | Sí | Cada tabla, función y estado sale de `docs/06` §5.2, §6 y §8, `docs/08` §6, `docs/02` §12, `docs/10`. Los puntos que `docs/` no fija se listan en "Puntos abiertos". |
| II · Documentación primero | Sí | Los tres puntos que `docs/` no fijaba se aprobaron y se escribieron (13 §4, 3.12): márgenes de compra, operaciones `reloj` y `activos` del broker, y la frescura de los datos. Ver "Puntos abiertos". |
| III · Sincronía | Sí | No hay historias que citen algo que este plan cambie; se actualiza `docs/17`. |
| IV · Investigación acotada | Sí | Módulo M-05 (`docs/17`); toca M-19 solo por `private.ahora()` y `despertar_funcion`. |
| V · Errores conocidos | Sí | Se busca por módulo; se anota lo que cueste más de un intento. |
| VI · Funcionando de punta a punta | Sí | pgTAP + `deno test` + `scripts/verificar.sh` completo. Sin E2E propio (lo ejercita E2E-03, TT-06 aún no existe). |
| VII · Alcance y costo | Sí | Sin servicios nuevos; Alpaca paper es gratis. |
| Inv. 1 · La IA no ejecuta | Sí | Solo `calendario-mercado` importa `_shared/broker/`; `scripts/verificar.sh` vigila a las otras tres. |
| Inv. 4 · RPC y RLS | Sí | RLS activo, `authenticated` solo `select`; `estado_mercado()` es de solo lectura. |
| Inv. 5 · La autorización lee `perfiles` | Sí | La política y la RPC usan `private.rol_actual()`. |
| Inv. 6 · Ninguna llave | Sí | Las llaves de Alpaca viajan solo en cabeceras; los errores no las copian. |
| Inv. 8 · Simulados solo en local y CI | Sí | `elegirProveedor("broker", …)` se niega con `ENTORNO=mvp`. |
| Inv. 9 · Migraciones solo hacia adelante | Sí | Tres migraciones nuevas con `supabase migration new`. |

### Puntos que `docs/` no fijaba (aprobados y escritos en `docs/`)

1. **Márgenes de compra. Aprobado por Javier el 2026-11-06 ("Sí, la propuesta").** `mercado.minutos_tras_apertura` y `minutos_antes_cierre` (5 y 15, `docs/02` §10) viven en `parametros`, que aún no existe (la crea HU-002; HU-033 completa el catálogo). `private.margenes_de_compra()` devuelve 5 y 15; `ventana_compras_abierta()` y `estado_mercado()` los leen de ahí; HU-033 solo cambia el cuerpo de esa función para leer `parametros`. A anotar fuera de esta historia: la línea que falta en la tarea de HU-033 y la dependencia que falta en el issue #46.
2. **Atributos de los activos en el broker. Aprobado por Javier el 2026-11-06 y escrito en `docs/10` §1 (13 §4, versión 3.12).** `docs/10` §1 lista las operaciones del adaptador del broker sin una de activos, pero FR-065 pide sincronizar `fraccionable` y `negociable` de Alpaca (endpoint de activos de la API de trading, la misma de `/v2/calendar` y `/v2/clock`). Se agrega la operación de solo lectura `activos(simbolos)` a la misma interfaz (y `reloj`, que `docs/05` §6 ya nombraba).
3. **Frescura de los datos** en `estado_mercado()`. `docs/06` §6 la nombra sin definirla; el insumo natural es `cotizaciones` (HU-028, aún no existe) y `mercado.max_antiguedad_cotizacion_seg` (RR-11, en `parametros`). **Aprobado por Javier el 2026-11-06:** `datos_actualizados_en` sale nula hasta que HU-028 tenga `cotizaciones`; HU-028 recibió la tarea de llenarla y HU-032 la usa para el aviso.

## Estructura del proyecto (Project Structure)

### Documentación de esta historia

```text
specs/027-calendario-y-estado-del-mercado/
├── plan.md              # Este archivo
├── research.md          # Decisiones técnicas
├── data-model.md        # Tabla, funciones y estados
├── quickstart.md        # Cómo comprobarlo de punta a punta
├── contracts/           # Funciones private, RPC, interfaz del broker y calendario-mercado
└── tasks.md             # Lo genera /speckit-tasks
```

### Código fuente (raíz del repositorio)

```text
supabase/
├── migrations/
│   ├── <fecha>_calendario_mercado.sql        # tabla, RLS, lectura con private.rol_actual()
│   ├── <fecha>_funciones_de_horario.sql      # mercado_abierto, mercado_en_ventana, sincronizar_calendario, sincronizar_activos
│   ├── <fecha>_trabajo_calendario.sql        # pg_cron 'calendario', diario 10:00 UTC
│   └── <fecha>_estado_mercado.sql            # (al final, con la decisión) margenes_de_compra, ventana_compras_abierta, estado_mercado()
├── tests/database/05_calendario_y_horario_test.sql
└── functions/
    ├── _shared/
    │   ├── mercado/tiempo.ts                 # + instanteDeNuevaYork (movido desde simulado.ts)
    │   └── broker/
    │       ├── interfaz.ts                   # Broker: calendario, reloj, activos
    │       ├── alpaca.ts · alpaca_test.ts · fixtures/
    │       ├── simulado.ts · simulado_test.ts   # reloj configurable: calendario, siempre_abierto, cerrado, cierre_en_10_min
    │       └── mod.ts · mod_test.ts          # crearBroker() con elegirProveedor
    └── calendario-mercado/
        ├── index.ts · manejador.ts           # + broker; orquesta calendario, reloj, activos e historia
        ├── sincronizacion.ts · sincronizacion_test.ts   # calendario, reloj y atributos
        └── (carga_historica.ts sin cambios)
docs/17-mapa-de-modulos.md                     # M-05: rutas y funciones nuevas
```

**Structure Decision**: se sigue `docs/05` §6 (`_shared/broker/` con interfaz, `alpaca.ts` y `simulado.ts`; una carpeta por función). La sincronización va en `sincronizacion.ts`, fuera de `manejador.ts`, para probarla con base y broker inyectados, como `carga_historica.ts`.

## Seguimiento de complejidad (Complexity Tracking)

Sin violaciones de la constitución que justificar. Los puntos abiertos no son violaciones: se detienen en lugar de decidirse.

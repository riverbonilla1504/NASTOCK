# Plan de implementación: HU-107 · Bitácora inmutable con cadena de hash

**Rama**: `107-bitacora-inmutable` | **Fecha**: 2026-11-06 | **Especificación**: [spec.md](spec.md)

**Entrada**: especificación de `specs/107-bitacora-inmutable/spec.md`. Historia: [`backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md`](../../backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) (issue #134).

## Resumen

Toda acción sensible del catálogo de `docs/11` §4.1 queda en la tabla `auditoria`, que nadie puede alterar y cuyos registros se encadenan con un hash. El plan construye, por capas y cada una con sus pruebas pgTAP: (1) la tabla `public.auditoria` de `docs/06` §5.6, con RLS de lectura solo para el Administrador y sin privilegios de escritura para ningún rol de la API (incluida `service_role`); (2) `private.auditar(...)`, la única puerta de escritura, que toma un bloqueo y encadena el hash, junto con el cálculo del hash en una función aparte para que la verificación de HU-108 use la misma fórmula; (3) el trigger que rechaza `UPDATE`, `DELETE` y `TRUNCATE`; (4) las pruebas de encadenado, concurrencia, inmutabilidad y lectura por rol. No hay Edge Functions ni app: la pantalla y la verificación llegan con HU-108 y HU-110.

## Contexto técnico

**Lenguaje/Versión**: SQL y PL/pgSQL (Postgres 17 de Supabase local).

**Dependencias principales**: Supabase CLI 2.122 (stack local con Docker), pgTAP. Para la prueba de concurrencia, la extensión `dblink` que se crea y se deshace dentro de la propia prueba (como `pgtap`); no se instala nada en el equipo ni en las migraciones.

**Almacenamiento**: Postgres. Tabla nueva `public.auditoria`; funciones nuevas en `private`: `hash_auditoria`, `auditar` y la del trigger.

**Pruebas**: pgTAP en `supabase/tests/database/` (convención `NN_nombre_test.sql`); una por capa.

**Plataforma de destino**: Supabase (local, CI y proyecto MVP).

**Tipo de proyecto**: base de datos. Sin Edge Functions ni app.

**Metas de rendimiento**: la bitácora recibe pocas filas al día (acciones de decenas de personas). El bloqueo serializa solo las escrituras de la propia bitácora; las lecturas no se bloquean.

**Restricciones**: funciones `security definer` con `set search_path = ''` (`supabase db lint --fail-on warning`); hora de `private.ahora()`; ningún rol de la API escribe en `auditoria`; el esquema `private` sigue sin `usage` para la API; ninguna llave en el repositorio; sin llaves, tokens ni respuestas de Google en los registros.

**Escala/Alcance**: una tabla, tres funciones, un trigger. Se guarda para siempre (`docs/06` §10): crece poco.

## Revisión de la constitución (Constitution Check)

| Principio o invariante | Cumple | Cómo |
|---|---|---|
| I · `docs/` es la fuente de verdad | Sí | Tabla, fórmula del hash, bloqueo, trigger y lectura salen de `docs/06` §5.6, §7 y §8.2, `docs/11` §4 y `docs/03` §4.3. Lo que `docs/` no escribe literalmente (genesis, formato de la fórmula, parámetros opcionales de `auditar`, `TRUNCATE`) va en [research.md](research.md) y no cambia ninguna regla. |
| II · Documentación primero | Sí | Ninguna regla nueva ni cambio de una existente: solo se actualiza `docs/17` (rutas). Dos observaciones para decidir después (el hash no cubre `antes`, `despues`, `actor_rol` ni `origen`; la llamada de `docs/04` §6 pasa un `uuid` como id) van al informe, no a `docs/`. |
| IV · Investigación acotada | Sí | Solo M-17 y, de M-02, la función `private.rol_actual()` por su firma. |
| V · Errores conocidos | Sí | EC-010 (`search_path`); EC-012 (los denegados no se auditan en la misma transacción, `docs/11` §4.2). |
| VI · Verificación de punta a punta | Sí | `scripts/verificar.sh` completo antes de terminar. Sin escenario E2E propio: se prueba con pgTAP (D-58). |
| VII · Alcance y costo | Sí | Nada de pago ni de servicios nuevos. |
| Invariante 4 (RLS y escritura solo por RPC) | Sí | RLS activo; ni siquiera hay políticas de escritura y se revocan los privilegios de escritura a `anon`, `authenticated` y `service_role`. |
| Invariante 5 (autorización lee `perfiles`) | Sí | La política usa `private.rol_actual()`, no los claims. |
| Invariante 6 (sin llaves) | Sí | No se usa ninguna llave; `auditar` solo guarda lo que le pasan. |

Sin violaciones: no hay tabla de complejidad.

## Estructura del proyecto

### Documentación de esta historia

```text
specs/107-bitacora-inmutable/
├── spec.md
├── plan.md              # Este archivo
├── research.md          # Decisiones de diseño (Fase 0)
├── data-model.md        # La tabla auditoria (Fase 1)
├── quickstart.md        # Cómo comprobar la historia (Fase 1)
├── contracts/           # Funciones, trigger y permisos (Fase 1)
├── checklists/
└── tasks.md             # /speckit-tasks
```

### Código fuente

```text
supabase/
├── migrations/
│   ├── <ts>_auditoria_tabla.sql                  # tabla, índices, RLS, permisos, política de lectura
│   ├── <ts>_auditar.sql                          # private.hash_auditoria(), private.auditar()
│   └── <ts>_auditoria_inmutable.sql              # trigger que rechaza UPDATE, DELETE y TRUNCATE
└── tests/database/
    ├── 05_auditoria_tabla_y_lectura_test.sql     # estructura, permisos, lectura por rol (CA-3, CA-5)
    ├── 06_auditoria_auditar_test.sql             # registro, encadenado, concurrencia, sin secretos (CA-1, CA-2, CA-4)
    └── 07_auditoria_inmutable_test.sql           # el trigger (CA-3)
docs/17-mapa-de-modulos.md                        # M-17: rutas reales
```

**Decisión de estructura**: una migración por capa, en el orden de `CLAUDE.md` (tabla y RLS → función → trigger), y una prueba por capa. Las tres migraciones se crean con `supabase migration new` y llevan una marca de tiempo posterior a la última de `main`.

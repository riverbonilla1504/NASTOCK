# Tareas: HU-109 · Aislamiento verificado por tabla y por función

**Entrada**: [spec.md](spec.md) y [plan.md](plan.md) · **Issue**: #136 · **Módulos**: M-02, M-20

Salen de la sección "Tareas" de la historia: pruebas `rls_*` con la matriz de
03 §4.3, la prueba del catálogo, una prueba por RPC, el asesor de seguridad en
CI, E2E-05 y `scripts/verificar.sh` completo.

Formato: `[ID] [P?] [Historia] Descripción`. `[P]` = se puede hacer en
paralelo (otro archivo, sin dependencias pendientes).

## Fase 1: Preparación

- [X] T001 Precisar en `docs/03-roles-y-permisos.md` §4.3 las filas de `fondos` (solo Analista y Administrador) y `posiciones_valoradas` (según RLS de `posiciones`), en `docs/15-calidad-pruebas-y-ci-cd.md` §6 el paso del asesor de seguridad, y registrar el cambio 3.32 en `docs/13-decisiones-pendientes-riesgos.md` §4

## Fase 2: Base (bloquea la historia)

- [X] T002 Migración `supabase/migrations/20261117120000_aislamiento_verificado.sql`: `revoke insert, update, delete, truncate, references, trigger on public.posiciones_valoradas from anon, authenticated`; `drop extension pg_net` y `create extension pg_net with schema extensions`
- [X] T003 `supabase db reset` y `supabase db advisors --local --type security --level warn --fail-on warn` sin advertencias

## Fase 3: Historia 1 · Aislamiento verificado (P1) 🎯

**Objetivo**: cada tabla y cada RPC de `public` tienen su caso (CA-1, CA-2),
una tabla sin RLS hace fallar la suite (CA-3), el asesor no deja advertencias
(CA-4) y un Usuario no ve ni escribe el cupo de otro por la API (CA-5).

**Prueba independiente**: `supabase test db` y
`deno test --allow-all --config supabase/tests/deno.json supabase/tests/e2e/05_aislamiento_de_cupos_test.ts`.

- [X] T004 [P] [US1] `supabase/tests/database/28_aislamiento_catalogo_test.sql`: RLS en todas las tablas y CA-3 con una tabla creada sin RLS; sin políticas de `INSERT`/`UPDATE`/`DELETE`/`ALL` para `anon`, `authenticated` ni `public`; sin privilegios de escritura de `anon` ni `authenticated` en tablas y vistas; `anon` sin `SELECT`; vistas con `security_invoker`; funciones `security definer` de `public` con `search_path = ''`; `anon` solo ejecuta `ping()`; registro de tablas (igual a la matriz) y de funciones (igual a la matriz de RPC)
- [X] T005 [P] [US1] `supabase/tests/database/29_aislamiento_lectura_por_tabla_test.sql`: datos de prueba en cada tabla, matriz de 03 §4.3 por persona (Usuario A, Usuario B, Analista, Administrador, suspendido, sin perfil, `anon`) y escritura directa rechazada en `subcuentas`, `movimientos`, `asientos`, `ordenes` y `posiciones` (CA-5)
- [X] T006 [P] [US1] `supabase/tests/database/30_aislamiento_por_funcion_test.sql`: cada RPC con los roles equivocados, la cuenta suspendida y la sesión sin perfil; `cancelar_orden` con la orden de otro Usuario; `mi_cupo` y `crear_orden_manual` solo tocan el cupo propio; `oportunidades` y `resumen_fondo` sin filas para la cuenta no activa
- [X] T007 [P] [US1] E2E-05 en `supabase/tests/e2e/05_aislamiento_de_cupos_test.ts`: dos Usuarios con cupo; cada uno lee solo el suyo en `subcuentas` y `mi_cupo`; `POST`/`PATCH`/`DELETE` directos a `subcuentas`, `movimientos` y `asientos` se rechazan y no cambian nada
- [X] T008 [US1] Paso `supabase db advisors --local --type security --level warn --fail-on warn` en `scripts/verificar.sh` (después de `db lint`) y en el trabajo `backend` de `.github/workflows/ci.yml`

**Punto de control**: CA-1 a CA-5 demostrados por pruebas.

## Fase 4: Cierre

- [X] T009 [P] Actualizar `docs/17-mapa-de-modulos.md` (M-02 y M-20: migración, pruebas `28`–`30`, E2E-05 y el asesor), `docs/18-estado-y-traspaso.md` y `docs/19-registro-de-pruebas.md`
- [ ] T010 `scripts/verificar.sh` completo en verde (incluye E2E de backend y de la app)
- [ ] T011 PR hacia `main` con la plantilla, `Closes #136` y la carpeta `specs/109-aislamiento-verificado/`

## Dependencias

- T002 → T003 → T004–T008 (la suite exige la vista sin privilegios y el asesor limpio).
- T009 puede ir con T004–T008. T010 depende de todo; T011 de T010.

## Paralelo

T004, T005, T006 y T007 son archivos distintos y se pueden escribir a la vez.

## Estrategia

Una sola historia (P1). Queda como base transversal: cada historia que cree
una tabla o una RPC agrega su fila a las matrices de `28`–`30` (14 §6).

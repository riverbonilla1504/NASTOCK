---

description: "Tareas de HU-029 · Barra diaria tras el cierre y retención de barras de minuto"
---

# Tareas (Tasks): HU-029

**Pruebas**: la historia las pide (`deno test` de `cierre-diario` y pgTAP de la condición del trabajo con el reloj fijado). Antes de cualquier comando de Supabase se toma el candado `C:/Users/Javier/.nastock-supabase.lock` y se suelta al terminar.

## Fase 1: Base de datos

- [x] T001 [US1] Migración `20261107140000_cierre_diario_y_limpieza.sql`: `private.cierre_diario_pendiente()` y `private.limpiar_barras_minuto()` (sin permisos para `public`, `anon` ni `authenticated`).
- [x] T002 [US1] Migración `20261107140002_trabajos_cierre_diario_y_limpieza.sql`: trabajos `cierre_diario` (cada 10 min, condicionado) y `limpieza` (08:00 UTC).
- [x] T003 [US1] pgTAP `supabase/tests/database/08_cierre_diario_y_limpieza_test.sql` (CA-2, CA-3, CA-4).

## Fase 2: Edge Function

- [x] T004 [US1] `supabase/functions/cierre-diario/` (`index.ts`, `manejador.ts`, `barra_diaria.ts`): barra de hoy de cada símbolo del universo, solo con secreto interno.
- [x] T005 [US1] `manejador_test.ts` (CA-1 y errores).

## Fase 3: Cierre

- [x] T006 [US1] `docs/06` §8.2 y `docs/17` (M-05) con las funciones, trabajos y rutas nuevas.
- [x] T007 [US1] `scripts/verificar.sh` completo en verde.

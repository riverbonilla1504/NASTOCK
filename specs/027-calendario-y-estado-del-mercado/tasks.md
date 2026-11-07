---

description: "Tareas de HU-027 · Calendario, reloj y estado del mercado"
---

# Tareas (Tasks): HU-027 · Calendario, reloj y estado del mercado

**Input**: documentos de `specs/027-calendario-y-estado-del-mercado/` (`plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`) y la sección "Tareas" de la historia.

**Pruebas**: la historia las pide (pgTAP de las funciones de horario con el reloj fijado y `deno test` de `calendario-mercado`), así que cada capa lleva las suyas. Sin escenario E2E propio (15 §4); lo ejercita E2E-03.

**Organización**: una sola historia de usuario (US1), por capas: migración → funciones `private` → RPC → Edge Function → trabajo `pg_cron`. Antes de cualquier comando `supabase` o de `scripts/verificar.sh` se toma el candado `C:/Users/Javier/.nastock-supabase-candado` y se suelta al terminar el bloque.

## Formato: `[ID] [P?] [Story] Descripción`

## Fase 1: Base de datos y funciones de horario

- [x] T001 [US1] `supabase migration new calendario_mercado`: tabla `public.calendario_mercado` (`fecha date pk`, `apertura`, `cierre timestamptz`, `sesion in ('regular','media_jornada')`, `cierre > apertura`), RLS activo, `revoke all`, `grant select` a `authenticated` y política `calendario_mercado_lectura` con `(select private.rol_actual()) is not null` (`docs/03` §4.3).
- [x] T002 [US1] `supabase migration new funciones_de_horario`: `private.mercado_abierto()` y `private.mercado_en_ventana(interval)` sobre `private.ahora()`; `private.sincronizar_calendario(date, date, jsonb)`; `private.sincronizar_activos(jsonb)`. Sin permisos para `public`, `anon` ni `authenticated`.
- [x] T003 [US1] `supabase migration new trabajo_calendario`: `cron.schedule('calendario', '0 10 * * *', …despertar_funcion('calendario-mercado'))`, sin duplicar si se repite.
- [x] T004 [US1] `supabase/tests/database/05_calendario_y_horario_test.sql` (pgTAP, reloj fijado con `pruebas.fijar_reloj`): tabla, llave, RLS y política (activa lee; suspendida, de baja, sin perfil y `anon` no) · día regular: cerrado antes de abrir, abierto al abrir, cerrado al cerrar · feriado sin fila: cerrado todo el día (CA-2) · media jornada: cierra 13:00 NY (CA-3) · los dos cambios de horario de 2026, con la apertura de lunes siguiente en UTC distinta (CA-4) · `mercado_en_ventana(10 min)` · `sincronizar_calendario` inserta, actualiza, borra lo que ya no viene y es idempotente (CA-6) · `sincronizar_activos` guarda atributos y `sincronizado_en`, desactiva el no negociable y no reactiva (CA-5, CA-7) · ninguna de las funciones es ejecutable por `anon` ni `authenticated`.

**Punto de control**: `supabase db reset` y `supabase test db` en verde.

## Fase 2: Broker (`_shared/broker/`, solo lectura)

- [x] T005 [P] [US1] Mover `instanteDeNuevaYork` a `_shared/mercado/tiempo.ts` (exportada) y que `simulado.ts` la importe; agregar `aInstanteUtc(fecha, "HH:MM")` y su prueba con los dos cambios de horario de 2026 (CB-51).
- [x] T006 [P] [US1] `_shared/broker/interfaz.ts` según `contracts/horario-y-calendario.md` §1.
- [x] T007 [US1] `_shared/broker/alpaca.ts` y `alpaca_test.ts` con respuestas grabadas en `fixtures/` (calendario con semana de Acción de Gracias y media jornada, y con el cambio de marzo; reloj; activos activo, no negociable y 404): conversión a UTC, `sesion`, llaves solo en cabeceras, errores sin llaves, zod. Depende de T005 y T006.
- [x] T008 [US1] `_shared/broker/simulado.ts` y `simulado_test.ts`: modos `calendario`, `siempre_abierto`, `cerrado` y `cierre_en_10_min`. Depende de T005 y T006.
- [x] T009 [US1] `_shared/broker/mod.ts` y `mod_test.ts`: `crearBroker()` con `elegirProveedor("broker", …)`, `RELOJ_SIMULADO` inválido es `ErrorDeConfiguracion`, se niega con `ENTORNO=mvp`. Depende de T007 y T008.

**Punto de control**: `deno test` de `_shared/` en verde.

## Fase 3: Edge Function `calendario-mercado`

- [x] T010 [US1] `calendario-mercado/sincronizacion.ts` y `sincronizacion_test.ts`: `sincronizarCalendario`, `contrastarReloj`, `sincronizarActivos` con base y broker falsos (rango de 60 días, lotes de 10, símbolos desactivados, error del proveedor). Depende de T009.
- [x] T011 [US1] Ampliar `manejador.ts` e `index.ts` (dependencia `broker`; los cuatro pasos independientes; presupuesto de la historia = lo que queda; `502` si un paso falla por el proveedor) y actualizar `manejador_test.ts` y `.env.e2e` (`RELOJ_SIMULADO`). Depende de T010.

**Punto de control**: `deno test` completo en verde.

## Fase 4: Estado del mercado (**espera la decisión sobre `parametros`**)

- [x] T012 [US1] `supabase migration new estado_mercado`: `private.margenes_de_compra()` (5 y 15), `private.ventana_compras_abierta()` y `public.estado_mercado()`; frescura según el punto abierto 3.
- [x] T013 [US1] Ampliar `05_calendario_y_horario_test.sql` con la ventana de compras (apertura + 5 min, cierre − 15 min; en media jornada con el cierre de 13:00) y los cinco estados de `estado_mercado()` (CA-1), incluida la lectura por rol.

## Fase 5: Cierre

- [x] T014 Actualizar `docs/17-mapa-de-modulos.md` (M-05): tabla, funciones, RPC, `_shared/broker/`, pruebas.
- [x] T015 Con el candado, `scripts/verificar.sh` completo en verde.
- [x] T016 Commits en español con `(#46)`, cuerpo del PR en `C:\Users\Javier\Desktop\pr-027-calendario-y-estado-del-mercado.md` e informe final.

## Dependencias

T001 → T002 → T003, T004 · T005, T006 → T007, T008 → T009 → T010 → T011 · T012 → T013 · T014 y T015 al final.

## Cobertura de criterios

CA-1: T012, T013 · CA-2, CA-3, CA-4: T004, T005, T007 · CA-5, CA-7: T002, T004, T010 · CA-6: T002, T003, T004, T010.

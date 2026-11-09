# Plan de implementación: HU-097 · Sección de Administración y guía de primeros pasos

**Rama**: `097-seccion-de-administracion` · **Spec**: [spec.md](spec.md) · **Módulo**: M-16 (`docs/17`)

## Resumen

Solo app. Se extiende la pantalla de Administración de HU-006/HU-003 con las cuatro entradas del MVP corto (backlog «MVP corto», `docs/14` §4.1) y la guía de primeros pasos (CB-80). La guarda de `/admin/*` ya existe (HU-006) y se conserva su prueba.

## Por capas

1. `lib/app/rutas.dart`: `/admin/capital`, `/admin/cupos`, `/admin/parametros`.
2. `lib/app/destinos.dart`: `seccionDeAdministracionDisponible(ruta)`; una entrada se habilita cuando su historia registra la subruta, sin tocar la pantalla (HU-099, HU-100 y HU-101 solo agregan su `GoRoute`).
3. `lib/features/admin/data/fondo_repositorio.dart`: `tieneCapital()` (un aporte confirmado en `movimientos_capital`, visible al Administrador por RLS) y `fondoConCapitalProvider`.
4. Pantalla y `GuiaDePrimerosPasos` con los cuatro pasos de `docs/08` §7.6; no se muestra mientras carga ni si la lectura falla.

## Decisiones

- CA-1 del backlog lista diez entradas, pero su sección «MVP corto» (D-58) deja cuatro: Usuarios e invitaciones, Capital, Cupos, Parámetros e interruptores. Rebalanceos, Lista blanca, Salud, Bitácora y Prompts no aparecen.
- «Invitaciones» pasa a llamarse «Usuarios e invitaciones» (docs/03 §3).
- Una entrada sin pantalla aparece deshabilitada con «Próximamente».

## Pruebas

`test/features/admin/pagina_administracion_test.dart` (entradas, guía con y sin capital, carga y error, deshabilitadas); la guarda del rol sigue en `test/app/entrada_a_invitaciones_test.dart`. El E2E-01 no se ajustó (decisión de pruebas mínimas).

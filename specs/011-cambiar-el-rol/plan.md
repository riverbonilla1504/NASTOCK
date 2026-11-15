# Plan de implementación: HU-011 · Cambiar el rol de una cuenta

**Branch**: `011-cambiar-el-rol` | **Date**: 2026-11-15 | **Spec**: [spec.md](spec.md)

**Input**: Issue #28, FR-032, FR-033, FR-034 y CA-1 a CA-5 existentes.

## Summary

Implementar la RPC de cambio de rol, la transición contable del cupo y la renovación de sesión por `perfil_actualizado`. La pantalla de usuarios pertenece a HU-098; RN-56 se completa en HU-065.

## Technical Context

- **Language/Version**: SQL de Supabase y Dart de `pubspec.yaml`; Flutter 3.47.9 fijado por el repositorio.
- **Primary Dependencies**: Supabase Auth/Realtime, Riverpod y GoRouter existentes; sin paquetes nuevos.
- **Storage**: perfiles, subcuentas, movimientos, asientos, órdenes, posiciones y bitácora existentes.
- **Testing**: pgTAP, pruebas Flutter de sesión/navegación y E2E mediante `scripts/verificar.sh` completo.
- **Target Platform**: Android y web, con backend local simulado.
- **Project Type**: App Flutter con backend Supabase.
- **Performance Goals**: navegación actualizada al recibir el evento, sin volver a ingresar; no inventar una latencia numérica.
- **Constraints**: autorización por perfiles, RPC transaccional, `security definer` con `search_path = ''`, migraciones hacia adelante y dinero solo por `registrar_movimiento`.
- **Scale/Scope**: decenas de usuarios (S4 de docs/01); una cuenta por invocación.

## Constitution Check

Diseño revisado antes y después de planear contra `CLAUDE.md` y la constitución. Fuentes: docs/03 §4–6 (PM-51, RN-50, RN-51, RN-54, RN-55), docs/04 §8, docs/06 §4 y §8.1, docs/09 §3–4 y §7, docs/11 §4.1 y docs/12 CB-09/CB-10.

Módulos principales: M-02 y M-04. Consumir las interfaces de M-03 (libro), M-10/M-11 (órdenes y posiciones), M-13 (eventos) y M-17 (auditoría). No cambiar sus reglas. Sin servicios ni reglas nuevas. Verificación completa pendiente: estos artefactos no acreditan una implementación terminada.

## Project Structure

### Documentation (this feature)

`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/cambiar-rol.md`, `quickstart.md`, `tasks.md` y `checklists/requirements.md` dentro de `specs/011-cambiar-el-rol/`.

### Source Code (repository root)

- `supabase/migrations/*_cambiar_rol.sql`: migración nueva, sin editar las anteriores.
- `supabase/tests/database/*_cambiar_rol_test.sql`: reglas, aislamiento, atomicidad y concurrencia.
- `lib/features/auth/data/ingreso_repositorio.dart`: reutilizar el adaptador de sesión.
- `lib/core/realtime/`: consumidor del evento y ciclo de vida de suscripciones.
- `test/core/realtime/`, `test/app/`: renovación y navegación.
- `supabase/tests/e2e/`, `integration_test/app_test.dart`: flujo integrado.
- `docs/15-calidad-pruebas-y-ci-cd.md` y `docs/17-mapa-de-modulos.md`: escenario y mapa.

**Structure Decision**: mantener las capas existentes y sus puntos de inyección. No crear la pantalla de HU-098.

## Fases

1. Escribir pruebas de CA-1 a CA-5 y revisar el orden de bloqueos frente a asignación de cupos y creación de órdenes.
2. Implementar la RPC: validar actor/destino, proteger último administrador y acción propia, comprobar posiciones/órdenes, devolver efectivo y cerrar cupo o crear cupo en cero, actualizar perfil, auditar y emitir evento privado sin montos. Todo en una transacción.
3. Renovar sesión por el adaptador al recibir el evento de la cuenta actual; los providers existentes recalculan guardas y canales. Manejar cierre de sesión y errores asíncronos.
4. Completar pruebas E2E, actualizar catálogo/mapa y ejecutar verificación completa antes del PR.

## Complexity Tracking

Sin excepciones a la constitución. UI de HU-098 y RN-56 quedan fuera del alcance.

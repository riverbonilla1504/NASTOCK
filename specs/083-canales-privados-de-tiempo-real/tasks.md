# Tareas: HU-083 · Canales privados de tiempo real

**Entrada**: [spec.md](spec.md), [plan.md](plan.md) · Tareas de la historia en `backlog/E-09-tiempo-real-y-notificaciones/HU-083-*.md`.

## Fase 1: Migraciones

- [x] T001 [US1] Migración `supabase/migrations/20261107130000_canales_privados_de_tiempo_real.sql`: política `canales_permitidos` sobre `realtime.messages`, sin política de INSERT (CA-1, CA-2, CA-3, CA-5)
- [x] T002 [US1] Migración `supabase/migrations/20261107130002_publicar_evento.sql`: `private.publicar_evento` como envoltura de `realtime.send`
- [x] T003 [US1] Misma migración: `private.carga_evento` con la convención `tabla`, `id`, `version`, `estado` (CA-4)

## Fase 2: Pruebas

- [x] T004 [US1] `supabase/tests/database/08_realtime_canales_test.sql`: cada canal por rol, cuenta no activa, publicación de clientes bloqueada, carga sin montos (CA-1 a CA-5)

## Fase 3: Cierre

- [x] T005 Actualizar M-13 en `docs/17-mapa-de-modulos.md`
- [ ] T006 `scripts/verificar.sh` completo en verde

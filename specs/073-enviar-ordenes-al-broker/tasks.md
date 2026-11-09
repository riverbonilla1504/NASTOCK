# Tareas: HU-073 · Enviar al broker las órdenes aprobadas

- [X] T001 Migración: tipos, `ordenes`, `ordenes_eventos`, RLS, evento `orden` y cola (absorbe la de HU-062, D-65)
- [X] T002 Migración: `tomar_orden_para_envio`, `registrar_respuesta_envio`, `registrar_error_envio`
- [X] T003 Función `ejecutor-ordenes` con el broker simulado y registro de salud
- [X] T004 Migración: trabajo `barrer_ejecutor` y reglas de la cola (5 lecturas → `error_envio`)
- [ ] T005 Notificación `orden_fallida`: no aplica en el MVP (D-62)
- [X] T006 Pruebas `deno test` de `ejecutor-ordenes` (sin respuesta, rechazo, 429, reintentos) y pgTAP del envío
- [ ] T007 E2E-08: pendiente, el escenario nace con la orden manual (HU-075)
- [X] T008 `docs/17` actualizado; `supabase/config.toml` con `verify_jwt = false` para la función
- [X] T009 Migraciones y pgTAP probadas en una transacción sobre la base local; `deno test`, lint y fmt en verde. `supabase db lint` y `scripts/verificar.sh` completo no corridos (pruebas mínimas)

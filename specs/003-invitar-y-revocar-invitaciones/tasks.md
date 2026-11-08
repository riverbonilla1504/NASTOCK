# Tareas: HU-003 · Invitar a una persona y revocar invitaciones

**Entrada**: [spec.md](spec.md), [plan.md](plan.md) · Tareas de la historia en `backlog/E-02-identidad-y-acceso/HU-003-*.md`. Una sola historia de usuario (US1), por capas: cada capa lleva sus pruebas.

## Fase 1: Migración y RPC (US1)

- [ ] T001 [US1] Migración `supabase/migrations/20261108120000_evento_de_invitaciones.sql`: trigger `after insert or update of estado` sobre `public.invitaciones` que publica `invitacion` en el canal `admin` con `private.carga_evento('invitaciones', id, null, estado)` (docs/09 §3 y §4)
- [ ] T002 [US1] Migración `supabase/migrations/20261108120002_invitar_y_revocar_invitaciones.sql`: `public.invitar_usuario(p_email, p_rol, p_cupo_inicial)`: `SESION_INVALIDA`, `NO_AUTORIZADO`, datos mal formados, `CORREO_YA_REGISTRADO`, vencimiento de la pendiente pasada de fecha, `INVITACION_DUPLICADA`, escritura con `private.ahora() + 7 días` y `cuenta.invitada` (CA-1, CA-2, CA-3, CA-5, CA-6, CA-7)
- [ ] T003 [US1] Misma migración: `public.revocar_invitacion(p_id)`: `SESION_INVALIDA`, `NO_AUTORIZADO`, `NO_EXISTE`, `ESTADO_INVALIDO`, estado `revocada` y `cuenta.invitacion_revocada`; `grant execute` solo a `authenticated` (CA-4, CA-5, CA-7)
- [ ] T004 [US1] pgTAP `supabase/tests/database/10_invitar_y_revocar_invitaciones_test.sql`: CA-1 a CA-7 (CA-7 con un administrador ya suspendido en la semilla de la prueba, porque suspender llega con HU-010), evento sin correos ni montos, auditoría, permisos de ejecución y revocada o vencida que el hook rechaza

## Fase 2: E2E de backend (US1)

- [ ] T005 [US1] Actualizar `supabase/tests/e2e/02_alta_con_invitacion_test.ts` (E2E-02): el Administrador invita por la RPC, la persona entra con esa invitación y queda con su rol; una invitación revocada, una vencida por el reloj y un Usuario que invita no dejan entrar ni invitar; la repetida responde `INVITACION_DUPLICADA` y, tras revocarla, se invita de nuevo

## Fase 3: App (US1)

- [ ] T006 [US1] `/impeccable shape` de la pantalla a partir de la historia y de `DESIGN.md`
- [ ] T007 [US1] Modelo `Invitacion` (`domain/`) y repositorio `InvitacionesRepositorio` (`data/`: listar, invitar, revocar, solo por la RPC) en `lib/features/admin/usuarios/`, con pruebas en `test/features/admin/usuarios/`
- [ ] T008 [US1] Providers, `FormularioDeInvitacion`, `ListaDeInvitaciones` y `PaginaInvitaciones` (`presentation/`), con solo tokens y componentes del sistema; errores por `traducirError`; pruebas de widget
- [ ] T009 [US1] Ruta mínima `/admin/usuarios` en `lib/app/enrutador.dart` y entrada en `lib/app/pagina_inicio.dart` visible solo si el token trae `app_rol = administrador`, con sus pruebas
- [ ] T010 [US1] `/impeccable audit` y `/impeccable polish`, revisando en Chrome; lo que encuentren se corrige

## Fase 4: Cierre

- [ ] T011 Actualizar `docs/17-mapa-de-modulos.md`: M-01 (archivos de las dos migraciones y la prueba pgTAP), M-02 (`lib/features/admin/usuarios/` y la ruta `/admin/usuarios`) y M-13 (el trigger del evento `invitacion`)
- [ ] T012 Rebase sobre `origin/main` (y HU-004 si ya llegó) y `scripts/verificar.sh` completo en verde
- [ ] T013 Cuerpo del PR y relevo en `C:\Users\Javier\Desktop\Nastock.md\`

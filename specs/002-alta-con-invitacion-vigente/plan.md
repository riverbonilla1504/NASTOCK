# Plan de implementación: HU-002 · Alta solo con invitación vigente

**Rama**: `002-alta-con-invitacion-vigente` | **Fecha**: 2026-11-07 | **Especificación**: [spec.md](spec.md)

## Resumen

Solo se crea una cuenta si el proveedor y el dominio están permitidos y existe una invitación pendiente y vigente. Por capas, cada una con sus pruebas: (1) tipo `estado_invitacion` y tabla `invitaciones` (RLS: solo el Administrador; índice único de una pendiente por correo; llave foránea de `perfiles.invitacion_id`); (2) tabla `parametros` con `auth.dominios_permitidos` (`[]`) y `auth.proveedores_permitidos` (`["google"]`); (3) `private.error_auth` y el hook `private.antes_de_crear_usuario`, registrado en `supabase/config.toml`; (4) triggers `al_crear_usuario` (perfil activo, invitación aceptada, `cuenta.activada`) y `al_cambiar_correo` (`cuenta.correo_cambiado`); (5) `seed.sql` con los usuarios de prueba, el dominio `prueba.local` y el proveedor `email`; (6) E2E-02 de backend. Sin Edge Functions ni app.

## Contexto técnico

SQL/PL/pgSQL en Supabase local; pgTAP en `supabase/tests/database/`; E2E de backend en Deno contra Auth real. Módulos: M-01 y M-02 (`docs/17`). Cambios a `docs/` de esta historia, registrados en `docs/13` §4 (3.19) y pendientes de la confirmación de Javier: acción `cuenta.correo_cambiado` (`docs/11` §4.1) y dominios vacíos en la migración (`docs/02` §13, Q-08).

## Revisión de la constitución

Cumple `CLAUDE.md`: funciones `security definer` con `set search_path = ''`; RLS en las dos tablas; sin escrituras desde la API; la auditoría pasa por `private.auditar`; la migración nunca agrega `email` a los proveedores; el cupo lo agrega HU-017.

## Decisiones de diseño

- El trigger de alta falla si no hay invitación pendiente (protege altas que no pasan por el hook).
- La bitácora arranca vacía tras `db reset`: la semilla inserta perfiles e invitaciones aceptadas sin disparar los triggers (`session_replication_role = replica`).
- La prueba pgTAP no puede asumir `supabase_auth_admin` (solo un superusuario otorga ese rol): comprueba sus permisos y ejecuta el hook como `postgres`; el E2E-02 lo ejercita con Auth real.
- `supabase/config.toml` solo se relee con `supabase stop` + `supabase start`.

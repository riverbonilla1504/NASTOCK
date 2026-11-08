# Plan de implementación: HU-004 · Primer administrador por configuración de despliegue

**Rama**: `004-primer-administrador` | **Fecha**: 2026-11-08 | **Especificación**: [spec.md](spec.md)

## Resumen

El despliegue crea la primera invitación de Administrador a partir de un correo configurado, sin credenciales en el código. Por capas, cada una con sus pruebas: (1) los dos mensajes del hook de alta cambian por la decisión de Gmail, con una migración nueva que redefine `private.antes_de_crear_usuario` (la de HU-002 ya está integrada y las migraciones solo van hacia adelante); (2) migración de arranque con `private.cargar_dominio_inicial()` (deja `auth.dominios_permitidos = ["gmail.com"]` si está vacío) y `private.crear_invitacion_inicial()` (lee `admin_inicial_email` de Vault y crea la invitación), ambas llamadas una vez al aplicarla; (3) `supabase/config.toml` declara `[db.vault]` con `env(ADMIN_INICIAL_EMAIL)` y `despliegue.yml` pasa el secreto de GitHub a `supabase db push` y falla antes si falta; (4) revisión de CA-4 en `scripts/verificar.sh` y `ci.yml`. Sin Edge Functions ni app.

## Contexto técnico

SQL/PL/pgSQL en Supabase local; pgTAP en `supabase/tests/database/`. Módulo: M-01 (`docs/17`). Reglas: `docs/04` §9 y §5, `docs/13` Q-08 y Q-22. Cambios a `docs/` de esta historia, ya aprobados por Javier y registrados en `docs/13` §4: **3.20** (Gmail, Q-08, Q-22, S1, mensajes del hook) y **3.21** (cómo llega `ADMIN_INICIAL_EMAIL`).

Hechos comprobados en el código del CLI de Supabase (etiqueta `v2.122.0`, la que fija el despliegue): `supabase db push` sube a Vault los valores de `[db.vault]` justo antes de aplicar las migraciones pendientes; los valores vacíos se omiten sin error. Una migración no lee variables de entorno; sí lee `vault.decrypted_secrets`.

## Revisión de la constitución

Cumple `CLAUDE.md`: funciones `security definer` con `set search_path = ''`; ejecución solo para el dueño (sin `public`, `anon` ni `authenticated`); ninguna escritura desde la API; la invitación entra por la tabla `invitaciones` de HU-002 y la auditoría por `private.auditar`; ninguna llave, usuario ni correo real en el repositorio (el correo vive en un secreto de GitHub y en Vault); migraciones solo hacia adelante.

## Decisiones de diseño

- **Una sola vez.** La migración corre una vez por proyecto, así que "aplicarla otra vez" (CA-2) se prueba llamando a la función. Para que esa única vez no se pierda, `despliegue.yml` falla antes de `db push` si falta `ADMIN_INICIAL_EMAIL`, y la función falla con un mensaje claro si el correo no tiene forma de correo o no es de un dominio permitido (un correo que luego el hook rechazaría dejaría a todos fuera).
- **Sin secreto, no hace nada** (local y CI): la semilla ya trae al administrador de prueba y el secreto no existe en Vault.
- **"Existe un administrador"** = alguna fila de `perfiles` con `rol = 'administrador'`, sin mirar el estado: RN-50 y RN-51 impiden dejar el sistema sin administrador activo.
- **Invitación pendiente vencida.** Si el correo tiene una pendiente ya vencida, la función la pasa a `vencida` y crea la nueva (como `invitar_usuario`, 3.2). Así una migración posterior puede reemitir la invitación que venció sin usarse.
- **Bitácora.** Registra `cuenta.invitada` con actor nulo (origen `sistema`) y `{"rol": "administrador", "origen": "despliegue"}`, sin el correo. Es una acción del catálogo de `docs/11` §4.1; la spec no la pide, así que queda anotada para revisión.
- **Mensajes del hook** (`docs/04` §5 y §11): "Solo se admiten cuentas de Google invitadas." y "Solo puedes ingresar con tu cuenta de Google." La migración de HU-002 no se edita: una migración nueva redefine la función con `create or replace`. Se actualizan sus pruebas (pgTAP 08 y E2E-02).
- **Dominio.** HU-002 creó `auth.dominios_permitidos = []` y ninguna historia lo cargaba (HU-101 exige tener ya un administrador). `private.cargar_dominio_inicial()` lo deja en `["gmail.com"]` solo si está vacío; `seed.sql` lo pone en `["prueba.local"]` en local y CI, después de las migraciones.
- **Ensayo del camino de la nube.** `db reset` no es lo que corre el despliegue. Para ensayarlo en local: `supabase db reset --no-seed --version <última de HU-002>`, luego `ADMIN_INICIAL_EMAIL=<correo de prueba> supabase db push --db-url <base local>` y comprobar que existe la invitación.
- `supabase/config.toml` solo se relee con `supabase stop` + `supabase start`.

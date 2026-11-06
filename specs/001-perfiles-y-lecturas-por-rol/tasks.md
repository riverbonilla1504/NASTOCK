---

description: "Tareas de HU-001 · Perfiles, rol actual y lecturas por rol"
---

# Tareas: HU-001 · Perfiles, rol actual y lecturas por rol

**Entrada**: documentos de diseño en `specs/001-perfiles-y-lecturas-por-rol/`

**Requisitos previos**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/funciones-y-hook.md](contracts/funciones-y-hook.md)

**Pruebas**: la historia las pide (pgTAP `rls_*` y `roles_*`), así que cada capa lleva las suyas.

**Organización**: la historia tiene una sola historia de usuario (US1, P1) y se construye por capas, en el orden de `CLAUDE.md`: migración (tablas, RLS) → funciones `private` → hook → app. Las tareas salen de la sección "Tareas" de la historia.

## Formato: `[ID] [P?] [Historia] Descripción`

- **[P]**: se puede hacer en paralelo (archivos distintos, sin depender de una tarea incompleta)
- **[US1]**: la única historia de usuario de esta especificación
- Toda tarea que toca el stack local de Supabase toma antes el candado `C:/Users/Javier/.nastock-supabase-candado` (`mkdir`) y lo suelta al terminar (`rmdir`).

## Convenciones de rutas

- Migraciones: `supabase/migrations/<marca de tiempo>_<nombre>.sql`, creadas con `supabase migration new`, en español y sin tildes.
- Pruebas de base de datos: `supabase/tests/database/NN_<nombre>_test.sql`.
- App: `lib/core/` y `test/core/` (solo con TT-04 en `main`).

---

## Fase 1: Preparación

- [X] T001 Confirmar que TT-03 está en `origin/main`, que `jwt_expiry = 900` está en `supabase/config.toml` y que las migraciones nuevas llevarán una marca de tiempo posterior a la última de `supabase/migrations/`

---

## Fase 2: Fundamentos

No hay: la única dependencia (esquema `private` y stack local) es TT-03, que ya está en `main`.

---

## Fase 3: Historia de usuario 1 · Perfiles, rol actual y lecturas por rol (Prioridad: P1)

**Objetivo**: cada cuenta tiene un único rol y un estado en `perfiles`, y cada lectura se filtra por ellos.

**Prueba independiente**: `supabase test db` pasa `02_perfiles_rls_test.sql` y `03_perfiles_roles_y_token_test.sql`, y un inicio de sesión real en el stack local devuelve `app_rol`, `app_estado` y `exp - iat = 900` ([quickstart.md](quickstart.md)).

### Capa 1 · Tipos y tabla (CA-4, FR-020)

- [X] T002 [US1] Crear la migración `supabase/migrations/<ts>_perfiles_tipos_y_tabla.sql` con los tipos `public.rol_app` (`usuario`, `analista`, `administrador`) y `public.estado_cuenta` (`activo`, `suspendido`, `baja`) y la tabla `public.perfiles` de [data-model.md](data-model.md): `id uuid` clave primaria que referencia `auth.users (id)`; `email text not null unique check (email = lower(email))`; `nombre text not null`; `rol rol_app not null`; `estado estado_cuenta not null default 'activo'`; `recibe_sugerencias boolean not null default true`; `preferencias_push jsonb not null default '{}'`; `invitacion_id uuid` sin llave foránea (research D-3, con comentario); `suspendido_en` y `baja_en timestamptz` nulos; `creado_en` y `actualizado_en timestamptz not null default now()`; `version int not null default 1`. Activar RLS, `revoke all` a `anon` y `authenticated`, `grant select` solo a `authenticated`, y comentarios en español.
- [X] T003 [US1] Crear `supabase/tests/database/02_perfiles_rls_test.sql` (parte de estructura): existen los tipos con sus valores, la tabla tiene RLS activo, no tiene políticas de escritura, `anon` y `authenticated` no tienen `insert`, `update` ni `delete`, y `email` rechaza mayúsculas. Las cuentas de prueba se crean sin depender de futuros triggers de `auth.users` (`session_replication_role = replica` solo al insertar en `auth.users`).

### Capa 2 · Funciones de autorización (CA-2, CA-6, FR-019)

- [X] T004 [US1] Crear la migración `supabase/migrations/<ts>_rol_actual_y_es_supervisor.sql` con `private.rol_actual()` y `private.es_supervisor()` tal como en [contracts/funciones-y-hook.md](contracts/funciones-y-hook.md) (`security definer`, `set search_path = ''`, nombres calificados), `revoke all ... from public, anon` y `grant execute ... to authenticated`, sin dar `usage` sobre `private` (research D-5).
- [X] T005 [US1] Crear `supabase/tests/database/03_perfiles_roles_y_token_test.sql` (parte de funciones): `rol_actual()` devuelve el rol de una cuenta activa de cada rol y `NULL` para una cuenta suspendida, una de baja, una sin perfil y sin sesión; `es_supervisor()` es verdadero para analista y administrador y falso para usuario y cuenta no activa; CA-6: se cambia el rol en `perfiles` y, con un claim `app_rol` viejo en `request.jwt.claims`, `rol_actual()` devuelve el rol nuevo; `authenticated` sigue sin `usage` sobre `private` (no se rompe `00_base_test.sql`).

### Capa 3 · Política de lectura (CA-2, CA-3, CA-4)

- [X] T006 [US1] Crear la migración `supabase/migrations/<ts>_perfiles_politica_de_lectura.sql` con la política `perfiles_lectura` (select, `authenticated`) de [contracts/funciones-y-hook.md](contracts/funciones-y-hook.md) y ninguna política de escritura (research D-1).
- [X] T007 [US1] Completar `supabase/tests/database/02_perfiles_rls_test.sql` (parte de lectura y escritura), actuando con `set local role authenticated` y `request.jwt.claims`: un Usuario ve solo su fila; un Analista y un Administrador ven todas; una cuenta suspendida y una de baja con token vigente no reciben ninguna fila (CA-2, con cuentas creadas ya suspendidas); un token de una persona sin perfil no recibe filas; como `anon` no hay lectura; `INSERT`, `UPDATE` y `DELETE` fallan con `42501` para cada rol y para `anon` (CA-4).

### Capa 4 · Hook del token (CA-1, CA-5, FR-018)

- [X] T008 [US1] Crear la migración `supabase/migrations/<ts>_token_personalizado.sql` con `private.token_personalizado(event jsonb)` de `docs/04` §7 (`security definer`, `set search_path = ''`), `grant usage on schema private` y `grant execute` solo a `supabase_auth_admin`, y `revoke execute ... from public, anon, authenticated`.
- [X] T009 [US1] Registrar el hook en `supabase/config.toml`: sección `[auth.hook.custom_access_token]` con `enabled = true` y `uri = "pg-functions://postgres/private/token_personalizado"`, sin tocar `jwt_expiry = 900`.
- [X] T010 [US1] Completar `supabase/tests/database/03_perfiles_roles_y_token_test.sql` (parte del hook), ejecutándolo como `supabase_auth_admin` (EC-009): para un analista activo el token trae `app_rol = analista` y `app_estado = activo` (CA-1); para una cuenta suspendida trae `app_estado = suspendido`; para un `user_id` sin perfil trae ambos claims en `null`; el resto de los claims del evento no cambia; `anon` y `authenticated` no pueden ejecutar el hook.
- [X] T011 [US1] Comprobar con un inicio de sesión real en el stack local (con el candado, reiniciando el stack desde esta rama) que el JWT trae `app_rol` y `app_estado`, también después de renovar la sesión con el refresh token, y que `exp - iat = 900` (CA-1, CA-5), siguiendo [quickstart.md](quickstart.md). pgTAP no puede leer `config.toml`, así que esta comprobación es manual; el script vive fuera del repositorio.

### Capa 5 · App (FR-018, FR-019, parte de interfaz)

- [X] T012 [US1] Antes de empezar, `git fetch` y revisar si TT-04 (esqueleto de la app) ya está en `origin/main`. Si no está, detenerse con la base de datos terminada y commiteada y avisar.
- [X] T013 [US1] Crear `perfilProvider` en `lib/core/perfil/` (`perfil.dart`, `perfil_repositorio.dart`, `perfil_provider.dart`, según el esqueleto de TT-04) que lee los claims `app_rol` y `app_estado` de la sesión y la fila propia de `perfiles`, y expone rol y estado a la interfaz. No decide autorización: la seguridad la hace la base de datos.
- [X] T014 [US1] Escribir las pruebas de `perfilProvider` en `test/core/perfil/` con claims y fila simulados: rol y estado desde los claims, fila propia de `perfiles`, sesión sin claims, y cuenta no activa.

---

## Fase 4: Cierre

- [ ] T015 `git fetch origin && git rebase origin/main`; si `main` trae migraciones más nuevas que las de esta historia, renombrar las nuestras con la fecha y hora actuales.
- [ ] T016 Correr `scripts/verificar.sh` completo con el candado tomado y dejarlo en verde.
- [ ] T017 Actualizar `docs/17-mapa-de-modulos.md` (M-01 y M-02: tabla `perfiles`, funciones, hook, rutas de migraciones, de pruebas y de `lib/core/`).
- [ ] T018 Escribir el cuerpo del PR con `.github/pull_request_template.md` y "Closes #18" en `C:\Users\Javier\Desktop\pr-001-perfiles-y-lecturas-por-rol.md` (fuera del repositorio).

---

## Dependencias y orden de ejecución

- T001 → T002 → T004 → T006 → T008: cada migración usa lo de la anterior, así que sus marcas de tiempo van en ese orden.
- Cada tarea de prueba va después de su migración: T003 tras T002; T005 tras T004; T007 tras T006; T010 tras T008 y T009.
- T009 es independiente de T008 en archivos, pero la comprobación real (T011) necesita ambas.
- T012 a T014 dependen de que TT-04 esté en `main`; si no está, la historia queda con la base de datos terminada.
- T015 a T018 van al final.

## Oportunidades de paralelismo

Casi ninguna: todas las migraciones y las dos pruebas comparten el stack local y el orden de capas es una restricción. T009 y T008 se pueden escribir a la vez porque tocan archivos distintos.

## Estrategia de implementación

1. Capas 1 a 3 (tabla, funciones, política): ya dan CA-2, CA-3, CA-4 y CA-6.
2. Capa 4 (hook): CA-1 y CA-5.
3. Capa 5 (app) solo cuando TT-04 esté en `main`.
4. Cierre: `verificar.sh`, `docs/17` y el cuerpo del PR.

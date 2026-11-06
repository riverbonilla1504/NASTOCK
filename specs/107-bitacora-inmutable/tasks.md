---

description: "Tareas de HU-107 · Bitácora inmutable con cadena de hash"
---

# Tareas: HU-107 · Bitácora inmutable con cadena de hash

**Entrada**: documentos de diseño en `specs/107-bitacora-inmutable/`

**Requisitos previos**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/auditoria.md](contracts/auditoria.md)

**Pruebas**: la historia las pide (pgTAP `auditoria_*`: encadenado, concurrencia, inmutabilidad y lectura por rol), así que cada capa lleva las suyas.

**Organización**: la historia tiene una sola historia de usuario (US1, P1) y se construye por capas, en el orden de `CLAUDE.md`: migración (tabla, RLS) → función `private` → trigger. No hay Edge Functions ni app. Las tareas salen de la sección "Tareas" de la historia.

## Formato: `[ID] [P?] [Historia] Descripción`

- **[P]**: se puede hacer en paralelo (archivos distintos, sin depender de una tarea incompleta)
- **[US1]**: la única historia de usuario de esta especificación
- Toda tarea que toca el stack local de Supabase toma antes el candado `C:/Users/Javier/.nastock-supabase-candado` (`mkdir`) y lo suelta al terminar (`rmdir`).

## Convenciones de rutas

- Migraciones: `supabase/migrations/<marca de tiempo>_<nombre>.sql`, creadas con `supabase migration new`, en español y sin tildes.
- Pruebas de base de datos: `supabase/tests/database/NN_<nombre>_test.sql`.

---

## Fase 1: Preparación

- [X] T001 Confirmar que TT-03 y HU-001 están en `origin/main` (esquema `private`, `private.rol_actual()`, tipo `rol_app`, `private.ahora()`) y que las migraciones nuevas llevarán una marca de tiempo posterior a la última de `supabase/migrations/`

---

## Fase 2: Fundamentos

No hay: las dependencias (TT-03 y HU-001) ya están en `main`.

---

## Fase 3: Historia de usuario 1 · Bitácora inmutable con cadena de hash (Prioridad: P1)

**Objetivo**: toda acción sensible queda en `auditoria`, que solo escribe `private.auditar`, nadie puede alterar y encadena cada registro con el hash del anterior.

**Prueba independiente**: `supabase test db` pasa `05_auditoria_tabla_y_lectura_test.sql`, `06_auditoria_auditar_test.sql` y `07_auditoria_inmutable_test.sql` ([quickstart.md](quickstart.md)).

### Capa 1 · Tabla, RLS y permisos (CA-3, CA-5, FR-219)

- [X] T002 [US1] Crear la migración `supabase/migrations/<ts>_auditoria_tabla.sql` con la tabla `public.auditoria` de [data-model.md](data-model.md): `id bigint generated always as identity` clave primaria; `momento timestamptz not null` (sin valor por defecto); `actor_id uuid` nulo y sin llave foránea; `actor_rol public.rol_app` nulo; `accion text not null` y `entidad text not null`, ambas con `check (btrim(...) <> '')`; `entidad_id text` nulo; `antes`, `despues` y `detalle` `jsonb` nulos; `origen text not null check (origen in ('app', 'sistema', 'cron', 'auth'))`; `hash_anterior text not null` y `hash text not null`, ambos con `check (... ~ '^[0-9a-f]{64}$')`; índice único sobre `hash_anterior`. Activar RLS; `revoke all` sobre la tabla y su secuencia a `public`, `anon`, `authenticated` y `service_role`; `grant select` solo a `authenticated`; política `auditoria_lectura` de [contracts/auditoria.md](contracts/auditoria.md) (`using ((select private.rol_actual()) = 'administrador')`) y ninguna política de escritura; comentarios en español en la tabla y en las columnas.
- [X] T003 [US1] Crear `supabase/tests/database/05_auditoria_tabla_y_lectura_test.sql`: estructura (`columns_are`, tipos, `not null`, `check` de origen y de formato del hash, índice único de `hash_anterior`); RLS activo con una sola política de lectura para `authenticated`; privilegios (`table_privs_are`: `authenticated` solo `SELECT`; `anon` y `service_role` ninguno); `INSERT`, `UPDATE`, `DELETE` y `TRUNCATE` directos fallan con `42501` para `anon`, `authenticated` con cada rol y `service_role` (CA-3); lectura por rol con filas que inserta directamente el dueño de la prueba, con valores literales y `hash_anterior` y `hash` distintos de 64 caracteres hexadecimales (en esta capa `auditar` aún no existe): el Administrador las ve todas, y un Usuario, un Analista, una cuenta suspendida, una de baja, una sesión sin perfil y un token sin identidad reciben 0 filas (CA-5); `anon` recibe `42501` al leer.

### Capa 2 · `private.auditar` con el bloqueo y el encadenado (CA-1, CA-2, CA-4, FR-218, FR-219)

- [X] T004 [US1] Crear la migración `supabase/migrations/<ts>_auditar.sql` con `private.hash_auditoria(p_hash_anterior text, p_momento timestamptz, p_actor uuid, p_actor_rol public.rol_app, p_accion text, p_entidad text, p_entidad_id text, p_antes jsonb, p_despues jsonb, p_detalle jsonb, p_origen text) returns text` (`language sql immutable`, `set search_path = ''`, fórmula de [contracts/auditoria.md](contracts/auditoria.md) y research D-2) y `private.auditar(p_actor uuid, p_accion text, p_entidad text, p_entidad_id text, p_detalle jsonb default null, p_antes jsonb default null, p_despues jsonb default null, p_origen text default null) returns bigint` (`security definer`, `set search_path = ''`): valida acción y entidad no vacías, `lock table public.auditoria in share row exclusive mode`, lee el último `hash` por `id` o usa 64 ceros, toma `momento` de `private.ahora()`, lee `actor_rol` de `perfiles`, decide `origen` (`sistema` sin actor, `app` con actor), calcula el hash e inserta. `revoke all` de ambas funciones a `public`, `anon`, `authenticated` y `service_role`. Comentarios en español.
- [X] T005 [US1] Crear `supabase/tests/database/06_auditoria_auditar_test.sql`: CA-1 (un registro con momento de `private.ahora()` con el reloj fijado, actor, rol leído de `perfiles` aunque el token diga otro, acción, entidad, id, `antes`, `despues`, `detalle` y origen; el sistema sin actor queda con rol nulo y origen `sistema`; origen explícito `auth` y `cron`; origen inválido falla con `23514`; acción o entidad vacías fallan); CA-2 (el primer registro lleva 64 ceros; cada `hash_anterior` es el `hash` del anterior; el `hash` coincide con el `sha256` de la fórmula de los once campos escrita a mano en la prueba, no con `hash_auditoria`; cambiar cualquiera de los once campos cambia el hash; el hash no cambia si la sesión usa otra zona horaria); SC-003 (la cadena se recalcula de punta a punta con la fórmula escrita en la prueba; la función que la verifica es de HU-108 y su trabajo semanal, de HU-110); concurrencia (con `dblink` creado dentro de la prueba y la conexión armada con `inet_server_addr()`, `current_setting('port')` y el usuario y la clave `postgres` del stack local, una segunda conexión que llama a `auditar` queda bloqueada por la primera según `pg_blocking_pids` y se cancela antes de confirmar nada; el índice único rechaza un segundo hijo del mismo `hash_anterior`; `auditar` deja el bloqueo de tabla `ShareRowExclusiveLock` en `pg_locks`); CA-4 (con un token y un cuerpo de respuesta de Google en la sesión, ninguna fila trae esos valores; un barrido de todas las filas de la prueba no encuentra llaves `sb_secret_`/`sb_publishable_`, JWT `eyJ…`, `ya29.` ni las claves `access_token`, `refresh_token`, `id_token`, `provider_token`); permisos: ningún rol de la API ejecuta `auditar` ni `hash_auditoria`; si la transacción que llama se revierte, el registro también.

### Capa 3 · Trigger de inmutabilidad (CA-3, FR-219)

- [X] T006 [US1] Crear la migración `supabase/migrations/<ts>_auditoria_inmutable.sql` con `private.rechazar_cambio_auditoria()` (`set search_path = ''`, lanza `auditoria: la bitácora es inmutable (<operación> no permitido)`) y el trigger por sentencia `auditoria_inmutable` (`before update or delete or truncate`) sobre `public.auditoria`; `revoke all` de la función a `public`, `anon`, `authenticated` y `service_role`.
- [X] T007 [US1] Crear `supabase/tests/database/07_auditoria_inmutable_test.sql`: con el rol dueño, `UPDATE` de cualquier columna, `DELETE` y `TRUNCATE` fallan con el mensaje del trigger y no cambian nada (`UPDATE` y `DELETE` con y sin `WHERE`, también sobre cero filas); "incluso de la llave secreta": dentro de la prueba se restituyen `update`, `delete` y `truncate` a `service_role` y, actuando como `service_role`, el trigger igual los rechaza; el trigger existe, está activo y es por sentencia (`INSERT ... ON CONFLICT DO UPDATE` también se rechaza); un `INSERT` por `auditar` sigue funcionando; la cadena queda intacta tras los intentos (CA-3).

### Cierre de la capa

- [X] T008 [US1] Correr `supabase db reset` y `supabase test db` con el candado tomado y dejar en verde las cinco pruebas de la capa (incluidas las de TT-03, TT-05, HU-001 y HU-026), y `supabase db lint --level warning --fail-on warning`.

---

## Fase 4: Cierre

- [X] T009 `git fetch origin && git rebase origin/main`; si `main` trae migraciones más nuevas que las de esta historia, renombrar las nuestras con la fecha y hora actuales.
- [X] T010 Correr `scripts/verificar.sh` completo con el candado tomado y dejarlo en verde.
- [X] T011 Actualizar `docs/17-mapa-de-modulos.md` (M-17: tabla `auditoria`, `private.hash_auditoria`, `private.auditar`, el trigger, rutas de migraciones y de pruebas, y "Depende de: M-02" por `private.rol_actual()`).
- [X] T012 Escribir el cuerpo del PR con `.github/pull_request_template.md` y "Closes #134" en `C:\Users\Javier\Desktop\pr-107-bitacora-inmutable.md` (fuera del repositorio).

---

## Fase 5: Cambios aprobados por Javier (2026-11-06)

- [X] T013 Hash con todos los campos: `docs/11` §4.3, CA-2 (historia y spec), `docs/06` §8.2 (firma de `auditar`), `private.hash_auditoria` con los once campos, `private.auditar` y las pruebas `06_` y `07_`; fila 3.13 en `docs/13` §4 (research D-10).
- [X] T014 Ejemplo de `docs/04` §6 con `new.id::text` (research D-11).
- [X] T015 `docs/errores-conocidos.md` en un commit aparte: quitar los retornos de carro literales de EC-019 y agregar EC-021 (`dblink` desde pgTAP).
- [ ] T016 `scripts/verificar.sh` completo con el candado y cuerpo del PR actualizado (indica que cambian reglas de `docs/11` §4.3 y `docs/04` §6).

---

## Dependencias y orden de ejecución

- T001 → T002 → T004 → T006: cada migración usa lo de la anterior, así que sus marcas de tiempo van en ese orden.
- Cada prueba va después de su migración: T003 tras T002; T005 tras T004 (y usa la tabla de T002); T007 tras T006.
- T008 va después de T007; T009 a T012 al final.

## Oportunidades de paralelismo

Casi ninguna: las tres migraciones y las tres pruebas comparten el stack local y el orden de capas es una restricción. Solo T011 y T012 se pueden escribir a la vez, pero T011 espera a T010 porque las rutas deben ser las finales.

## Estrategia de implementación

1. Capa 1 (tabla, RLS y permisos): ya da CA-3 (escritura) y CA-5.
2. Capa 2 (`auditar`): CA-1, CA-2 y CA-4.
3. Capa 3 (trigger): completa CA-3 y cierra el borrado total.
4. Cierre: `verificar.sh`, `docs/17` y el cuerpo del PR.

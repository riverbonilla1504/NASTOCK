# Errores conocidos

Memoria compartida de los problemas que ya se resolvieron, para **no volver
a iterar sobre algo que una sesión anterior ya arregló**.

## Cómo se usa

- **Antes de investigar un error**, buscar aquí por el mensaje, el módulo
  (`M-xx`) o la herramienta. Si está, aplicar la solución.
- **Después de resolver** algo que costó más de un intento, que no era obvio
  o que puede repetirse, agregar una entrada. Un error trivial de tipeo no
  va aquí.
- Las entradas no se borran. Si una solución deja de valer, se marca como
  **obsoleta** con la fecha y se agrega la nueva.
- Si el error revela una regla que faltaba en la especificación, además se
  actualiza `docs/` (y se nombra aquí la sección).

## Formato

```
### EC-000 · Título corto con el síntoma
- Fecha: AAAA-MM-DD · Módulos: M-xx · Origen: investigación | HU-nnn | PR #nnn
- Síntoma: qué se ve (mensaje exacto si hay)
- Causa: por qué pasa
- Solución: qué se hizo (archivo, comando o configuración)
- Para no repetirlo: regla, prueba o verificación que lo previene
```

---

## Conocidos desde la investigación (antes de escribir código)

### EC-001 · Alpaca rechaza el stop-loss en compras fraccionales
- Fecha: 2026-09-28 · Módulos: M-10, M-11 · Origen: investigación
- Síntoma: una orden *bracket* con cantidad fraccional es rechazada.
- Causa: Alpaca solo admite órdenes bracket con acciones enteras; las fracciones solo aceptan órdenes market, limit, stop y stop limit con TIF `day`.
- Solución: comprar acciones enteras cuando alcance (protección nativa) y fracciones con protección virtual (10 §6).
- Para no repetirlo: prueba del ejecutor que verifica la clase de orden según la cantidad.

### EC-002 · Alpaca paper no llena órdenes con el mercado cerrado
- Fecha: 2026-09-28 · Módulos: M-10, M-19 · Origen: investigación
- Síntoma: las pruebas contra Alpaca paper se quedan esperando fuera del horario de mercado.
- Causa: el broker encola la orden hasta la apertura.
- Solución: las pruebas automáticas usan el broker simulado; Alpaca paper solo en el proyecto MVP y en la prueba semanal de solo lectura.
- Para no repetirlo: `.env.e2e` con `PROVEEDOR_BROKER=simulado`.

### EC-003 · Las órdenes GTC de Alpaca se cancelan solas a los 90 días
- Fecha: 2026-09-28 · Módulos: M-11 · Origen: investigación
- Síntoma: una protección nativa desaparece sin que nadie la cancele.
- Causa: vencimiento automático de las órdenes `gtc`.
- Solución: `cierre-diario` renueva las patas que cumplen 80 días.
- Para no repetirlo: prueba de la renovación con el reloj adelantado.

### EC-004 · Alpaca News responde 403 en algunas cuentas gratuitas
- Fecha: 2026-09-28 · Módulos: M-06 · Origen: investigación (reportes en el foro de Alpaca)
- Síntoma: `403` al pedir `/v1beta1/news`.
- Causa: restricciones de suscripción reportadas por usuarios del plan gratuito.
- Solución: verificar al conectar la cuenta (16 §3.4); si ocurre, el sistema sigue "sin contexto" y se evalúa la alternativa de Q-19.
- Para no repetirlo: salud `alpaca_noticias` y alerta al admin.

### EC-005 · DeepSeek devuelve contenido vacío en modo JSON
- Fecha: 2026-09-28 · Módulos: M-06 · Origen: investigación (documentación de DeepSeek)
- Síntoma: respuesta con `content` vacío.
- Causa: problema conocido del modo JSON; también si el prompt no menciona "json" o `max_tokens` es corto.
- Solución: incluir la palabra "json" y un ejemplo en el prompt, `max_tokens` holgado, un reintento.
- Para no repetirlo: prueba del adaptador con una respuesta vacía grabada.

### EC-006 · Los nombres de modelo de DeepSeek cambian
- Fecha: 2026-09-28 · Módulos: M-06 · Origen: investigación
- Síntoma: error de modelo inexistente o facturación a otra tarifa.
- Causa: DeepSeek retira nombres (p. ej. `deepseek-v4-flash` pasó a ser alias obsoleto de `deepseek-flash`).
- Solución: el modelo es un parámetro (`ia.modelo_contexto`) con lista permitida.
- Para no repetirlo: la prueba semanal real detecta el error.

### EC-007 · JEV no hace cuentas ni compara fechas
- Fecha: 2026-09-28 · Módulos: M-07 · Origen: investigación (limitaciones de Jev 1.13)
- Síntoma: respuestas incoherentes cuando el estado trae cifras o fechas para comparar.
- Causa: JEV lee números y fechas como texto; no es una calculadora.
- Solución: toda cifra se calcula en código y se envía como etiqueta semántica (07 §4.3).
- Para no repetirlo: prueba que falla si el estado enviado a JEV contiene números crudos en los campos de la candidata.

### EC-008 · JEV pierde precisión fuera del inglés y con estado irrelevante
- Fecha: 2026-09-28 · Módulos: M-07 · Origen: investigación
- Síntoma: confianza baja o respuestas erráticas.
- Causa: entrenado principalmente en inglés; la precisión baja cuando el estado tiene información que no hace falta.
- Solución: preguntas, criterios y estado en inglés; una llamada por candidata con solo sus datos.
- Para no repetirlo: la configuración de decisión se valida en modo sombra antes de activarse.

### EC-009 · El login falla con un error genérico después de registrar un hook de Auth
- Fecha: 2026-09-28 · Módulos: M-01 · Origen: investigación
- Síntoma: el ingreso falla sin mensaje útil.
- Causa: la función del hook no tiene `grant execute` para `supabase_auth_admin`, o ese rol no puede leer las tablas que consulta (faltan `grant select` y una política RLS para él).
- Solución: grants y políticas de 04 §5.
- Para no repetirlo: prueba pgTAP que ejecuta el hook como `supabase_auth_admin`.

### EC-010 · El linter de Supabase marca funciones `security definer`
- Fecha: 2026-09-28 · Módulos: M-02 · Origen: investigación
- Síntoma: advertencia de seguridad por `search_path` mutable.
- Causa: la función no fija `search_path`.
- Solución: `set search_path = ''` y nombres calificados con el esquema.
- Para no repetirlo: `supabase db lint` en CI con falla ante advertencias.

### EC-011 · Una vista con `security definer` se salta RLS sin que se note
- Fecha: 2026-09-28 · Módulos: M-02, M-15 · Origen: investigación
- Síntoma: un Usuario ve datos agregados de más.
- Causa: las vistas se ejecutan por defecto con los permisos de su dueño.
- Solución: vistas con `security_invoker = true`, o funciones explícitas para agregados (06 §6).
- Para no repetirlo: prueba RLS de cada vista.

### EC-012 · La auditoría desaparece cuando una RPC falla
- Fecha: 2026-09-28 · Módulos: M-17 · Origen: investigación
- Síntoma: no queda registro de un acceso denegado.
- Causa: `raise exception` revierte toda la transacción, incluida la fila de auditoría.
- Solución: los denegados se leen de los registros de la API de Supabase (11 §4.2).
- Para no repetirlo: no intentar auditar dentro de la misma transacción que falla.

### EC-013 · Un broadcast desde la base de datos no llega a la app
- Fecha: 2026-09-28 · Módulos: M-13 · Origen: investigación
- Síntoma: el canal está suscrito pero no recibe eventos.
- Causa: el mensaje se envió privado y el canal del cliente es público (o al revés), o falta la política sobre `realtime.messages`.
- Solución: canales siempre privados en ambos lados y política de 09 §3.
- Para no repetirlo: prueba E2E-03.

### EC-014 · `pg_cron` corre en UTC
- Fecha: 2026-09-28 · Módulos: M-05 · Origen: investigación
- Síntoma: procesos que corren una hora antes o después al cambiar el horario de verano de EE. UU.
- Causa: programar horas fijas de mercado en cron.
- Solución: trabajos frecuentes que preguntan a `calendario_mercado` si les toca (05 §7).
- Para no repetirlo: ninguna hora de mercado escrita en una expresión cron.

### EC-015 · El proyecto gratuito de Supabase se pausa
- Fecha: 2026-09-28 · Módulos: M-20 · Origen: investigación
- Síntoma: la API no responde tras una semana sin uso.
- Causa: pausa por inactividad del plan gratuito (7 días).
- Solución: `ping()` diario desde `mantenimiento.yml` + trabajos de `pg_cron`.
- Para no repetirlo: el flujo diario falla y avisa si el `ping()` no responde.

### EC-016 · `hashFiles` no funciona en el `if` de un trabajo de GitHub Actions
- Fecha: 2026-09-28 · Módulos: M-20 · Origen: investigación
- Síntoma: error de expresión o trabajo que nunca corre.
- Causa: `hashFiles` solo está disponible en los pasos, no en la condición del trabajo.
- Solución: un trabajo `detectar` que publica salidas y los demás usan `needs.detectar.outputs.*` (ya así en `ci.yml`).
- Para no repetirlo: seguir el patrón existente.

### EC-017 · El flujo de la wiki no puede publicar
- Fecha: 2026-09-28 · Módulos: M-20 · Origen: investigación
- Síntoma: `git push` a `<repo>.wiki.git` falla.
- Causa: la wiki no está inicializada (no tiene ninguna página) o falta `permissions: contents: write`.
- Solución: crear a mano la primera página una vez (16 §3.1); el flujo ya declara el permiso.
- Para no repetirlo: paso en la lista de arranque.

### EC-018 · `google_sign_in` cambió su API en la versión 7
- Fecha: 2026-09-28 · Módulos: M-01 · Origen: investigación
- Síntoma: ejemplos antiguos no compilan.
- Causa: la versión 7 introdujo `GoogleSignIn.instance`, `initialize` y `authenticate`.
- Solución: seguir la guía vigente de Supabase para Flutter (04 §4.4).
- Para no repetirlo: fijar la versión del paquete en `pubspec.yaml`.

---

## Encontrados durante la implementación

### EC-019 · `publicar-backlog.py` actualiza todas las issues aunque `backlog/` no cambió
- Fecha: 2026-10-19 · Módulos: M-20 · Origen: implementación
- Síntoma: al volver a correr el script en Windows, todas las issues salen como "actualizada".
- Causa: el archivo temporal del cuerpo se escribía en modo texto con `\r\n`, GitHub guarda esos saltos tal cual y la comparación con el cuerpo generado (`\n`) nunca coincidía.
- Solución: escribir el archivo con `newline="\n"` y comparar el cuerpo de GitHub sin `\r`.
- Para no repetirlo: al pasar texto a `gh` con `--body-file` desde Python, fijar siempre `newline`.

### EC-020 · `gh` falla a mitad de una publicación larga con `TLS handshake timeout`
- Fecha: 2026-10-19 · Módulos: M-20 · Origen: implementación
- Síntoma: `publicar-backlog.py` se detiene con `TLS handshake timeout`, `stream error … CANCEL` o `GraphQL: Something went wrong`.
- Causa: cortes de red o del servidor de GitHub durante cientos de llamadas seguidas; no es un error de la petición.
- Solución: el script repite hasta 4 veces solo esos errores de transporte y solo en operaciones idempotentes; `issue create` no se repite (podría duplicar) y basta volver a correr el script, que reconoce las issues por el prefijo del título.
- Para no repetirlo: no agregar reintentos a `issue create`; ante un corte, volver a correr el script.

### EC-021 · `dblink` desde una prueba pgTAP falla con "password or GSSAPI delegated credentials required"
- Fecha: 2026-11-06 · Módulos: M-17, M-20 · Origen: HU-107
- Síntoma: `dblink_connect` con `host=127.0.0.1` falla con `password or GSSAPI delegated credentials required`; por un socket Unix falla con `could not translate host name "port=5432" to address`.
- Causa: en Supabase `postgres` no es superusuario y `dblink` exige que el servidor le pida la clave, pero la conexión a `127.0.0.1` es de confianza y no la pide. Con un socket Unix `inet_server_addr()` es nulo y el texto de conexión queda `host= port=…`.
- Solución: crear `dblink` dentro de la prueba (`create extension if not exists dblink with schema extensions`, se deshace con ella) y conectar a `inet_server_addr()` (TCP, como lo hace `supabase test db`) con `user=postgres password=postgres`. La consulta de la segunda conexión va en `begin; …; rollback;` y se cancela antes de terminar, para que no deje nada confirmado.
- Para no repetirlo: `supabase/tests/database/06_auditoria_auditar_test.sql` es el ejemplo. Las pruebas que necesiten dos conexiones se corren con `supabase test db`, no por un socket Unix.

### EC-022 · `deno test` del E2E falla con "Could not find a matching package for 'npm:postgres…' in the node_modules directory"
- Fecha: 2026-11-07 · Módulos: M-20 · Origen: TT-06
- Síntoma: `deno test --allow-all supabase/tests/e2e` termina con `Import "postgres" not a dependency` (sin configuración) o con `Could not find a matching package … in the node_modules directory` (con `npm:` en el import).
- Causa: Deno no descubre el `deno.json` de la carpeta de las pruebas; hay que indicárselo con `--config`. Además, si en una carpeta superior del equipo hay un `package.json` (por ejemplo `C:\Users\<usuario>\package.json`), Deno exige `node_modules` y rechaza los paquetes `npm:`.
- Solución: `supabase/tests/deno.json` (con `"nodeModulesDir": "none"` y las dependencias de las pruebas) y siempre `deno test --allow-all --config supabase/tests/deno.json supabase/tests/e2e` (y `…/humo`), en `scripts/verificar.sh`, `ci.yml` y `despliegue.yml`.
- Para no repetirlo: ejecutar las pruebas de `supabase/tests/` solo con `--config supabase/tests/deno.json`; sin eso fallan en equipos con un `package.json` en una carpeta superior aunque en CI pasen.

### EC-023 · `flutter drive` falla con "session not created: This version of ChromeDriver only supports Chrome version N"
- Fecha: 2026-11-07 · Módulos: M-20 · Origen: TT-06
- Síntoma: el E2E de la app termina con `SessionNotCreatedException (500): … only supports Chrome version 157` y `Current browser version is 156…`.
- Causa: la versión mayor de `chromedriver` y la de Chrome tienen que coincidir. En CI coinciden (`$CHROMEWEBDRIVER` viene con el Chrome del ejecutor); en un equipo local Chrome se actualiza solo y `chromedriver` (instalado con Scoop) no.
- Solución: poner `chromedriver` en la misma versión mayor que Chrome (`chrome://version` y `chromedriver --version`), actualizando uno u otro.
- Para no repetirlo: al actualizar Chrome en el equipo de desarrollo, actualizar también `chromedriver`.

### EC-024 · El despliegue falla en `supabase db push` con "Target: local stack (127.0.0.1:54322)"
- Fecha: 2026-11-08 · Módulos: M-20 · Origen: primer despliegue de TT-08 (#157)
- Síntoma: el trabajo `Supabase` de `despliegue.yml` termina con `Target: local stack (127.0.0.1:54322) · default; pass --remote for <proyecto>` y `failed to connect to postgres … dial error (connect ECONNREFUSED 127.0.0.1:54322)`, aunque `supabase link` funcionó y los secretos están cargados.
- Causa: `supabase/setup-cli` con `version: latest` instaló la versión 3 de la CLI. En la 3, `db push` apunta por defecto al stack local; en la 2 (la que se usa en local, 2.122.0) apunta al proyecto enlazado. En el ejecutor de GitHub no hay stack local.
- Solución: fijar `version: 2.122.0` en `despliegue.yml` y `mantenimiento.yml` (TT-07 hace lo mismo en `ci.yml`).
- Para no repetirlo: los flujos usan la misma versión de la CLI que el equipo local, nunca `latest`. Pasar a la 3 es un cambio aparte: actualizar local y flujos juntos y revisar los comandos que ahora piden `--remote`.

### EC-025 · `supabase db lint` falla con "relation pg_temp.<tabla> does not exist (42P01)" en una función plpgsql
- Fecha: 2026-11-09 · Módulos: M-03 · Origen: HU-013 (#31)
- Síntoma: el paso `supabase db lint --level warning --fail-on warning` de CI termina con `function private.registrar_movimiento · level error · relation "pg_temp.asientos_nuevos" does not exist (42P01)`, aunque la función y sus pruebas funcionan.
- Causa: `plpgsql_check` analiza el cuerpo de forma estática y no ve las tablas temporales que la función crea al ejecutarse.
- Solución: no usar tablas temporales dentro de funciones. Leer la entrada con `jsonb_to_recordset(p_param) as x (...)` en cada consulta (migración `20261109120008_registrar_movimiento_sin_tabla_temporal.sql`).
- Para no repetirlo: antes de subir una función nueva, correr `supabase db lint --level warning --fail-on warning`; las pruebas pgTAP no detectan esto.

### EC-026 · El E2E falla al limpiar con "violates foreign key constraint subcuentas_usuario_id_fkey"
- Fecha: 2026-11-09 · Módulos: M-04, M-20 · Origen: HU-017 (#35)
- Síntoma: `PostgresError: update or delete on table "perfiles" violates foreign key constraint "subcuentas_usuario_id_fkey"` en `eliminar()` del arnés (`supabase/tests/e2e/utilidades/sesion.ts`) y en `limpiar()` de E2E-02.
- Causa: desde HU-017 el alta de un Usuario crea su cupo (una subcuenta). La limpieza de las pruebas borraba el perfil sin contar con ella. No es un error del producto: la app nunca borra perfiles (se da de baja).
- Solución: la limpieza de pruebas borra primero la subcuenta de cupo del usuario de prueba (en 0 y sin asientos). No se agregó `on delete cascade` al modelo; si el cupo tuviera asientos, la llave foránea sigue fallando y avisa.
- Para no repetirlo: toda limpieza de pruebas que borre perfiles debe quitar antes lo que cuelga de ellos (cupos).

### EC-027 · El despliegue de Hosting falla con "Permission denied to get service [firebasehosting.googleapis.com]"
- Fecha: 2026-11-08 · Módulos: M-20 · Origen: primer despliegue de TT-08 (#157)
- Síntoma: el trabajo `Web` de `despliegue.yml` termina con `Request to https://serviceusage.googleapis.com/v1/projects/<proyecto>/services/firebasehosting.googleapis.com had HTTP Error: 403, Permission denied to get service [firebasehosting.googleapis.com]`.
- Causa: la cuenta de servicio `ci-despliegue` tenía *Firebase Hosting Admin* y *Firebase App Distribution Admin*, pero `firebase-tools` consulta Service Usage antes de publicar y eso exige el rol *Service Usage Consumer* (`roles/serviceusage.serviceUsageConsumer`), que las guías no mencionaban.
- Solución: en Google Cloud → IAM, agregar a `ci-despliegue` el rol *Service Usage Consumer* (a mano; no hay cambio de código).
- Para no repetirlo: `docs/16` §3.3 lista los tres roles de la cuenta de servicio de CI.

### EC-028 · La CI falla en `supabase start` con 429 de `public.ecr.aws` y luego "port 54322 address already in use"
- Fecha: 2026-11-08 · Módulos: M-20 · Origen: CI de HU-005 (PR #165, ejecución 42453681503, intento 1; el intento 2 pasó)
- Síntoma: el trabajo `Base de datos y funciones` imprime `unexpected status from HEAD request to https://public.ecr.aws/v2/supabase/storage-api/manifests/…: 429 Too Many Requests` y `error from registry: Rate exceeded`, y al final `failed to start docker container "supabase_db_NASTOCK": … failed to bind host port 0.0.0.0:54322/tcp: address already in use`.
- Causa: son dos cosas distintas. (1) El 429 es la limitación de descargas anónimas de ECR Public (los ejecutores comparten IP); la CLI 2.122.0 lo reintenta sola ("Retrying after 4s") y en este caso todas las imágenes se bajaron bien, así que **no** es lo que falló. (2) La falla real es el puerto 54322, ocupado justo después de bajar ~12 imágenes en paralelo. **Causa probable, no confirmada:** los puertos 54320 a 54329 de Supabase están dentro del rango de puertos efímeros de Linux (32768 a 60999), y una de las muchas conexiones salientes de las descargas pudo tomar ese puerto de origen. Se repitió el 2026-11-09 en el E2E del PR #194 (ejecución 42705695618) con el puerto 54324 de `supabase_inbucket_NASTOCK`.
- Solución: volver a lanzar el trabajo (pasó al segundo intento). No se agregan reintentos al flujo.
- Para no repetirlo: si se repite, probar antes de `supabase start` `sudo sysctl -w net.ipv4.ip_local_reserved_ports=54320-54329` (reserva esos puertos para quien haga `bind`) y, para quitar el 429, `SUPABASE_INTERNAL_IMAGE_REGISTRY=ghcr.io` en el entorno del paso. Ninguno está aplicado: hay que verlos fallar y pasar en una ejecución real antes de dejarlos.

### EC-029 · La app o el despliegue usan una llave publicable de otro proyecto de Supabase
- Fecha: 2026-11-08 · Módulos: M-20 · Origen: primer despliegue de TT-08 (#157)
- Síntoma: la prueba de humo falla con `/auth/v1/settings respondió 401`.
- Causa: la variable `SUPABASE_PUBLISHABLE_KEY` de GitHub era la del proyecto anterior, no la de NasTock.
- Solución: cargar la llave publicable del proyecto MVP (`sb_publishable_…`) en la variable.
- Para no repetirlo: tras cambiar de proyecto, correr "Despliegue" a mano; la prueba de humo lo detecta.

### EC-030 · El APK firmado falla con "keystore password was incorrect"
- Fecha: 2026-11-08 · Módulos: M-20 · Origen: primer despliegue de TT-08 (#157)
- Síntoma: `Failed to read key *** from store ".../android/app/upload-keystore.jks": keystore password was incorrect` en `:app:packageRelease`.
- Causa: `ANDROID_KEYSTORE_PASSWORD` y `ANDROID_KEY_PASSWORD` no eran la contraseña real del `.jks` (se habían cargado otros datos del certificado).
- Solución: cargar las dos con la contraseña del `.jks` (la misma en ambas).
- Para no repetirlo: comprobarla en local con `keytool -list -keystore <archivo>` antes de cargarla.

### EC-031 · `deno test --filter "/regex/"` no filtra en Git Bash y sale en verde sin probar nada
- Fecha: 2026-11-07 · Módulos: M-20 · Origen: TT-08
- Síntoma: `3 filtered out` y todas las pruebas descartadas, con salida 0.
- Causa: MSYS convierte el argumento `/ping|CB-91/` en una ruta de Windows.
- Solución: usar texto simple (`--filter CB-91`) o `MSYS_NO_PATHCONV=1`.
- Para no repetirlo: leer el conteo de pruebas ejecutadas, no solo el código de salida.

### EC-032 · `fork: Resource temporarily unavailable` en Git Bash al correr `verificar.sh`
- Fecha: 2026-11-07 · Módulos: M-20 · Origen: TT-08
- Síntoma: el shell no puede crear procesos y `verificar.sh` ni arranca; Docker Desktop llegó a reiniciarse solo.
- Causa: con unos 49 MB de RAM libres (varias sesiones, Gradle y Docker) Windows no da más procesos.
- Solución: cerrar sesiones o procesos pesados y reintentar.
- Para no repetirlo: máximo 3 agentes a la vez y revisar que haya al menos 2 GB libres antes de `verificar.sh`.

### EC-033 · `taskkill /IM supabase.exe` mata también el stack y las funciones de otras sesiones
- Fecha: 2026-11-07 · Módulos: M-20 · Origen: TT-08
- Síntoma: otra sesión pierde `supabase functions serve` o su `supabase start`.
- Causa: el nombre de imagen es el mismo para todas las sesiones.
- Solución: parar solo el proceso propio, por PID o filtrando la línea de comandos.
- Para no repetirlo: una sola sesión a la vez corre la base local (se coordinó con un candado fuera del repo) y nunca se mata por nombre.

### EC-034 · Cambiar `ADMIN_INICIAL_EMAIL` en GitHub no cambia Vault
- Fecha: 2026-11-08 · Módulos: M-01, M-20 · Origen: HU-004 (#21)
- Síntoma: se cambia el secreto y el valor en Vault sigue igual.
- Causa: `supabase db push` solo sube lo de `[db.vault]` cuando hay migraciones pendientes, y omite los valores vacíos sin avisar.
- Solución: la migración de arranque corre una sola vez; si hay que repetirla, una migración nueva que vuelva a llamar a `private.crear_invitacion_inicial()` (reemite la pendiente vencida).
- Para no repetirlo: para ensayar el despliegue en local, `supabase db reset --no-seed --version <última anterior>` y `ADMIN_INICIAL_EMAIL=<correo de prueba> supabase db push --db-url postgresql://postgres:postgres@127.0.0.1:54322/postgres`; después un `supabase db reset` completo para devolver la semilla.

### EC-035 · El rechazo del hook de Auth no trae un código que la app pueda distinguir
- Fecha: 2026-11-08 · Módulos: M-01 · Origen: HU-005 (#22)
- Síntoma: la app no sabe si el rechazo fue "sin invitación", "dominio no permitido" o "proveedor no permitido".
- Causa: `private.error_auth` devuelve `{"error":{"http_code":403,"message":…}}` y Auth lo entrega como `AuthApiException` con estado 403 y el mensaje, sin `code` propio.
- Solución: la app reconoce el rechazo por el prefijo del mensaje y muestra el texto del servidor (`clasificador_de_fallos.dart`).
- Para no repetirlo: si cambia la redacción del hook, conservar el prefijo o actualizar el clasificador; su prueba lee la migración más reciente del hook.

### EC-036 · Riverpod 3: `invalid_use_of_internal_member` al usar `copyWithPrevious`
- Fecha: 2026-11-08 · Módulos: M-16 · Origen: HU-003 (#20)
- Síntoma: el análisis marca `invalid_use_of_internal_member` al conservar la lista anterior en un `AsyncNotifier`.
- Causa: en Riverpod 3 `AsyncValue.copyWithPrevious` es `@internal`.
- Solución: asignar `state = const AsyncLoading()` o `state = AsyncError(...)`; el valor ya conserva los datos anteriores.
- Para no repetirlo: no llamar `copyWithPrevious` desde la app.

### EC-037 · El respaldo diario falla con "Your network does not support IPv6, which is required for direct connections to the database"
- Fecha: 2026-11-13 · Módulos: M-20 · Origen: `mantenimiento.yml`, trabajo "Respaldo cifrado" (ejecuciones del 2026-11-10 al 2026-11-13)
- Síntoma: `supabase db dump` termina con `Your network does not support IPv6, which is required for direct connections to the database. Retry with your project's IPv4 transaction pooler connection string via --db-url.` y el flujo "Mantenimiento" queda en rojo todos los días.
- Causa: el secreto `SUPABASE_DB_URL` de GitHub tiene la conexión directa (`db.<ref>.supabase.co:5432`), que en Supabase es solo IPv6; los ejecutores de GitHub solo tienen IPv4.
- Solución: cargar en el secreto la cadena del **Session pooler** (panel de Supabase → Connect → Session pooler, puerto 5432, usuario `postgres.<ref>`, con la contraseña de la base). Es IPv4 y sirve para `pg_dump`. No hay cambio de código.
- Segundo intento: con el pooler ya conecta, pero puede fallar con `FATAL: password authentication failed for user "postgres"`. Pasa si quedan los corchetes de `[YOUR-PASSWORD]`, si la clave tiene símbolos sin codificar (`@`, `#`, `/`, `?`, `%`, `:`) o si no es la clave vigente. Se resolvió con **Reset database password** usando una clave larga solo de letras y números, y actualizando **los dos** secretos: `SUPABASE_DB_URL` y `SUPABASE_DB_PASSWORD` (el despliegue usa el segundo). Cambiar la clave no afecta a la app ni a las Edge Functions.
- Para no repetirlo: `docs/16` §4.1 dice de dónde sale `SUPABASE_DB_URL`; tras cambiarlo, correr "Mantenimiento" a mano y ver el artefacto `respaldo-*` (quedó en verde el 2026-11-13, ejecución 43504106440).

### EC-038 · `flutter analyze` falla en la CI con "'package:flutter/material.dart' is deprecated … Use package:material_ui/material_ui.dart instead"
- Fecha: 2026-11-13 · Módulos: M-20, M-16 · Origen: CI del PR #195
- Síntoma: el trabajo "App Flutter" termina con exit 1 y un aviso `deprecated_member_use` en cada archivo que importa `package:flutter/material.dart` (`lib/`, `test/` e `integration_test/`). En local, con Flutter 3.47.9, `flutter analyze` sale limpio.
- Causa: los flujos instalaban `channel: stable` sin versión, así que tomaron la versión estable nueva, que declara obsoleto `material.dart` a favor del paquete `material_ui`. El análisis falla con los avisos de tipo info.
- Solución: fijar `flutter-version: 3.47.9` en `subosito/flutter-action` de `ci.yml` y `despliegue.yml`, la misma versión de los equipos de desarrollo (`docs/16` §3.7). No se cambió ninguna regla del análisis.
- Para no repetirlo: subir Flutter es un cambio aparte, en su propia rama: actualizar la versión fijada y la de los equipos, y migrar los imports a `material_ui` en el mismo PR.

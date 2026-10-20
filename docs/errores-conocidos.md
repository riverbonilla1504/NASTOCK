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
- Causa: el archivo temporal del cuerpo se escribía en modo texto con `
`, GitHub guarda esos saltos tal cual y la comparación con el cuerpo generado (`
`) nunca coincidía.
- Solución: escribir el archivo con `newline="
"` y comparar el cuerpo de GitHub sin ``.
- Para no repetirlo: al pasar texto a `gh` con `--body-file` desde Python, fijar siempre `newline`.

### EC-020 · `gh` falla a mitad de una publicación larga con `TLS handshake timeout`
- Fecha: 2026-10-19 · Módulos: M-20 · Origen: implementación
- Síntoma: `publicar-backlog.py` se detiene con `TLS handshake timeout`, `stream error … CANCEL` o `GraphQL: Something went wrong`.
- Causa: cortes de red o del servidor de GitHub durante cientos de llamadas seguidas; no es un error de la petición.
- Solución: el script repite hasta 4 veces solo esos errores de transporte y solo en operaciones idempotentes; `issue create` no se repite (podría duplicar) y basta volver a correr el script, que reconoce las issues por el prefijo del título.
- Para no repetirlo: no agregar reintentos a `issue create`; ante un corte, volver a correr el script.

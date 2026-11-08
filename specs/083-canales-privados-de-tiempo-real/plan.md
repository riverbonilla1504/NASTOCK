# Plan de implementación: HU-083 · Canales privados de tiempo real

**Rama**: `083-canales-privados-de-tiempo-real` · **Spec**: [spec.md](spec.md) · **Módulo**: M-13 (`docs/17` §1)

## Resumen

Solo capa de base de datos (sin Edge Functions ni app; el gestor de la app es HU-084). Fuentes: `docs/09` §3 y §4, `docs/03` §4.6, D-14, D-32.

## Contexto técnico

- PostgreSQL / Supabase Realtime (Broadcast desde la base de datos con `realtime.send`).
- Pruebas: pgTAP en `supabase/tests/database/`.
- Depende de HU-001: `private.rol_actual()` y `private.es_supervisor()` (NULL / falso si la cuenta no está activa).

## Verificación contra las reglas (CLAUDE.md)

- Autorización desde `perfiles`, no desde el JWT: se cumple (las políticas usan las funciones de HU-001).
- Los eventos nunca llevan montos: `private.carga_evento` solo arma `tabla`, `id`, `version`, `estado`.
- Sin política de INSERT: ningún cliente publica. `publicar_evento` es `security definer`, `set search_path = ''`, sin `execute` para la API.
- No hay tablas nuevas, así que no aplican RLS de `public` ni migración de datos.

## Diseño por capas

1. **Migración `20261107130000_canales_privados_de_tiempo_real.sql`**: política `canales_permitidos` (SELECT, `authenticated`) sobre `realtime.messages`, tal como `docs/09` §3.
2. **Migración `20261107130002_publicar_evento.sql`**:
   - `private.publicar_evento(topico, evento, carga)`: valida que el canal sea uno de los cinco de `docs/09` §3 y envuelve `realtime.send(..., private := true)`.
   - `private.carga_evento(tabla, id, version, estado)`: convención de la carga de los eventos de entidad para los triggers de las demás historias.
3. **Pruebas** `supabase/tests/database/08_realtime_canales_test.sql`: cada canal por rol, cuenta suspendida, de baja o sin perfil, publicación de clientes bloqueada, carga sin montos.
4. **docs/17**: M-13 apunta a la prueba y a las funciones reales.

## Notas

- La política solo evalúa `realtime.topic()` (el canal al que se suscribe el cliente); Realtime filtra los mensajes por canal.
- Sin escenario E2E propio (lo ejercitan E2E-03 y E2E-08).

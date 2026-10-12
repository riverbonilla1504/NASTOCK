# CLAUDE.md — Reglas para agentes

Léelo completo antes de hacer cualquier cosa en este repositorio.

## Qué es este proyecto

Plataforma de inversión asistida por IA para RiTech SAS: un fondo en **paper
trading** dividido 50/25/25 (Reserva, Arriesgadas, Usuarios), donde una IA
(IA principal + DeepSeek + JEV) sugiere y **una persona siempre aprueba**.
Flutter (Android + web) + Supabase + Alpaca paper. Es un **MVP** para probar
si el enfoque funciona.

## Reglas de oro

1. **`docs/` es la fuente de verdad de toda la aplicación.** Lo que no está
   en `docs/` no está decidido. Nunca implementes una regla de negocio "de
   memoria" o "porque parece razonable": búscala en `docs/`.

2. **Documentación primero.** Si lo que te piden no está contemplado en
   `docs/` o lo contradice:
   1. Detente antes de escribir código.
   2. Muestra al usuario qué dice `docs/` (archivo y sección) y en qué choca.
   3. Propón el cambio concreto a `docs/`.
   4. Con su confirmación, actualiza `docs/` y anota el cambio en
      `docs/13-decisiones-pendientes-riesgos.md` §4 (historial).
   5. Recién entonces implementa.

3. **Sincronía en ambos sentidos.**
   - Si cambia una historia de usuario (issue), actualiza `docs/` en el mismo PR.
   - Si cambias `docs/`, busca las historias que citan lo cambiado
     (`gh issue list --search "RN-26"`, etc.) y actualízalas o coméntalas.
   - La wiki se genera sola desde `docs/`. Nunca la edites a mano.

4. **Investigación acotada.** No analices el proyecto entero: es lento y caro.
   Sigue el protocolo de `docs/17-mapa-de-modulos.md` §1: módulos afectados
   → solo sus secciones de `docs/`, sus entradas de errores conocidos y sus
   rutas de código → traza el flujo de punta a punta dentro de esos módulos.
   Si al terminar cambiaron rutas, tablas o funciones, actualiza el mapa.

5. **Errores conocidos.** Ante cualquier error, **primero** busca en
   `docs/errores-conocidos.md` (por mensaje, módulo o herramienta). Si
   resolviste algo que costó más de un intento o no era obvio, agrégalo con
   el formato del archivo antes de terminar.

6. **El sistema siempre queda funcionando de punta a punta.**
   - Nada está terminado sin `scripts/verificar.sh` **completo** en verde
     (incluye E2E de backend y de la app). `--rapido` es solo para iterar.
   - Si tu cambio toca un flujo, agrega o actualiza su escenario E2E
     (`docs/15-calidad-pruebas-y-ci-cd.md` §4).
   - **Nunca** desactives, saltes o relajes una prueba para que pase. Si la
     prueba está mal, corrígela y explica por qué en el PR.
   - Nada se integra a `main` con CI en rojo.

7. **Alcance y costo.** Solo MVP en paper trading: nada de dinero real.
   Solo herramientas gratuitas, salvo DeepSeek y JEV. No agregues servicios,
   paquetes de pago ni planes pagos sin aprobación explícita.

## Invariantes que nunca se rompen

- La IA **no ejecuta**: `agente`, `contexto-ia` y `opinion-ia` no importan
  `_shared/broker/`. Toda compra o venta discrecional la aprueba una persona.
- Toda operación pasa por `private.validar_operacion` (motor de políticas).
- El dinero solo se mueve con `private.registrar_movimiento` (doble partida,
  suma cero). Nunca `UPDATE` directo de saldos.
- Escrituras de la app **solo por RPC**; RLS activo en todas las tablas de
  `public`; funciones `security definer` con `set search_path = ''`.
- La autorización lee `perfiles` (`private.rol_actual()`), no los claims del JWT.
- Ninguna llave en la app, en el repositorio, en issues ni en registros.
- A DeepSeek y a JEV no se les envían datos personales. A JEV, etiquetas en
  inglés, nunca cifras ni fechas para comparar.
- Proveedores simulados y correo + contraseña **solo** en local y CI.
- Migraciones solo hacia adelante. Nunca editar la base de datos de la nube a mano.
- Los eventos de Realtime llevan identificadores y versión, nunca montos.

## Flujo para implementar una historia

```
0. gh issue view <n> y su archivo en backlog/ (HU-xxx)
     → criterios, reglas (RN/RR/PM), casos borde (CB), módulos (M), E2E
1. docs/17 → secciones de docs/ y rutas de esos módulos; errores conocidos de esos módulos
2. ¿Contradice o falta en docs/?  → regla de oro 2 (antes de especificar)
3. Rama: <historia en 3 dígitos>-<descripcion-corta>, igual a su carpeta en specs/
     (HU-005 → 005-ingresar-con-google)
4. Especificar con spec-kit, a partir de la historia:
     /speckit-specify → specs/<rama>/spec.md   qué y por qué
     /speckit-plan    → plan.md                cómo: módulos de docs/17, por capas
     /speckit-tasks   → tasks.md               desde la sección "Tareas" de la historia
     /speckit-analyze → consistencia entre los tres
5. Implementar por capas (/speckit-implement), cada una con sus pruebas:
     migración (tablas, RLS) → RPC / funciones private → Edge Functions → app
6. Escenario E2E nuevo o actualizado
7. scripts/verificar.sh  (completo, en verde)
8. Actualizar: docs/ (si cambió una regla) · docs/17 (si cambiaron rutas)
              · errores-conocidos.md (si aplica) · historial 13 §4 (si cambió una regla)
9. PR con la plantilla, "Closes #<n>", con la carpeta de la historia en specs/;
   actualizar el ítem en GitHub Projects
```

### Reglas de spec-kit (D-56)

- `specs/` es un derivado de `docs/` y de `backlog/`. Si una spec choca con
  `docs/`, manda `docs/` y se corrige la spec.
- Una spec por historia, generada por entrega cuando se va a construir. Las
  tareas técnicas de E-01 no llevan spec (rama `tt-<nn>-<descripcion-corta>`).
- La spec conserva los criterios de aceptación con su `CA-n`, cita los `FR` del
  catálogo sin renumerarlos y, en "Supuestos", incluye los supuestos de
  `docs/01` §5 y las preguntas `Q-xx` de `docs/13` §2 que apliquen.
- `/speckit-clarify` solo para dudas que no tocan una regla. Si la tocan, va
  primero a `docs/` (regla de oro 2).
- No se usan `/speckit-taskstoissues` ni las extensiones `git`, `github` y
  `agent-context` del kit: los issues salen del backlog, las ramas y los
  commits siguen `docs/15` §7 y este archivo no lo edita el kit.
- La constitución (`.specify/memory/constitution.md`) remite a este archivo y
  a `docs/`; no agrega reglas.

## Cuando algo falla

1. Lee el error completo (no solo la última línea).
2. Busca en `docs/errores-conocidos.md`.
3. Reproduce con la prueba más pequeña posible (pgTAP, `deno test` o `flutter test`).
4. Corrige la causa, no el síntoma. No agregues reintentos o esperas a ciegas.
5. Registra el error si cumple la regla de oro 5.

## Comandos

```bash
scripts/verificar.sh              # todo lo que corre CI (obligatorio antes de terminar)
scripts/verificar.sh --rapido     # sin E2E de la app (solo para iterar)
python scripts/verificar_docs.py docs

supabase start                    # stack local (Docker)
supabase db reset                 # base local desde cero: migraciones + seed.sql
supabase test db                  # pruebas pgTAP
supabase functions serve --env-file supabase/functions/.env.e2e   # funciones con proveedores simulados

flutter test
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d web-server

gh issue view <n> · gh issue list --search "<ID>" · gh issue comment <n> --body "…"

specify version · specify self check   # línea de comandos de spec-kit (versión fijada en docs/16 §3.7)
# En el chat del agente, no en la terminal:
/speckit-specify · /speckit-plan · /speckit-tasks · /speckit-analyze · /speckit-implement
```

## Convenciones

- Español en documentación, interfaz, modelo de datos, commits y PR.
  Identificadores sin tildes. Preguntas a JEV en inglés.
- Commits en imperativo con la historia: `Agrega la aprobación de sugerencias (#42)`.
- Dinero `numeric(14,2)` en USD; horas en UTC (se muestran en hora de Bogotá).
- Identificadores de reglas y casos (`RN`, `RR`, `PM`, `CB`, `D`, `Q`, `RSG`,
  `E`, `E2E`, `M`, `EC`): nunca se reutilizan (ver `docs/README.md`).

## Estado del proyecto

- Especificación v3.3 completa en `docs/`.
- Backlog completo en `backlog/` (227 requisitos, 13 épicas, 117 historias y
  9 tareas técnicas). **Pendiente**: publicarlo como issues en GitHub Projects
  y conectar los servicios (`docs/16-arranque-del-repositorio.md` §3–§7).
- spec-kit adoptado (D-56). Las specs se generan por entrega; la primera es R1.
- Aún no hay código: la primera épica es E-01 (cimientos y calidad continua).

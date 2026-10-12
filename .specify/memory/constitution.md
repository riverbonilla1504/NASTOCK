<!--
Sync Impact Report
- Versión: plantilla → 1.0.0 (primera versión)
- Principios: I a VII, uno por cada regla de oro de CLAUDE.md
- Secciones: Invariantes · Uso de spec-kit · Gobierno
- Plantillas: .specify/templates/overrides/spec-template.md (en español) ✅
- Pendientes: ninguno
-->

# Constitución de la plataforma de inversión de RiTech (Constitution)

Este archivo **no es una fuente de verdad**. Es el índice que spec-kit lee antes de especificar, planear y analizar: una línea por regla y el lugar donde está escrita completa. Si algo de aquí choca con `docs/` o con `CLAUDE.md`, mandan ellos (ver Gobierno).

## Principios (Core Principles)

### I. `docs/` es la fuente de verdad

Lo que no está en `docs/` no está decidido. Ninguna regla de negocio se escribe de memoria ni porque parezca razonable: al especificar no se suponen valores ni comportamientos, y lo que falte se marca en lugar de adivinarlo.
→ `CLAUDE.md`, regla de oro 1 · `docs/13` D-49

### II. Documentación primero

Si lo pedido no está en `docs/` o lo contradice, se detiene el trabajo, se propone el cambio a `docs/`, se aprueba, se anota en el historial y recién entonces se implementa.
→ `CLAUDE.md`, regla de oro 2 · `docs/13` §4

### III. Sincronía en ambos sentidos

Las historias y `docs/` cambian juntas. La wiki se genera sola y nunca se edita a mano.
→ `CLAUDE.md`, regla de oro 3

### IV. Investigación acotada

Se leen solo los módulos afectados: sus secciones de `docs/`, sus errores conocidos y sus rutas.
→ `CLAUDE.md`, regla de oro 4 · `docs/17` §1 · D-52

### V. Errores conocidos

Ante un error, primero se busca en el registro; lo que costó resolver se anota ahí.
→ `CLAUDE.md`, regla de oro 5 · `docs/errores-conocidos.md` · D-50

### VI. El sistema siempre queda funcionando de punta a punta

Nada está terminado sin `scripts/verificar.sh` completo en verde. Un cambio que toca un flujo agrega o actualiza su escenario E2E. Nunca se desactiva ni se relaja una prueba para que pase.
→ `CLAUDE.md`, regla de oro 6 · `docs/15` · D-51

### VII. Alcance y costo

Solo MVP en paper trading: nada de dinero real. Solo herramientas gratuitas, salvo DeepSeek y JEV.
→ `CLAUDE.md`, regla de oro 7 · D-44 · D-45

## Invariantes (Additional Constraints)

Todo plan y toda tarea los respetan. El texto completo está en `CLAUDE.md`, sección "Invariantes que nunca se rompen".

1. La IA no ejecuta: toda compra o venta discrecional la aprueba una persona.
2. Toda operación pasa por el motor de políticas.
3. El dinero solo se mueve con asientos de doble partida que suman cero; nunca con un cambio directo de saldos.
4. La app escribe solo por RPC y hay RLS en todas las tablas de `public`. → `docs/03` §4.3 y §4.4
5. La autorización lee `perfiles`, no los claims del token. → `docs/03` §4.1 y §4.2
6. Ninguna llave en la app, en el repositorio, en issues ni en registros.
7. A DeepSeek y a JEV no se les envían datos personales; a JEV, etiquetas en inglés, nunca cifras ni fechas. → D-40
8. Proveedores simulados y correo + contraseña solo en local y CI. → `docs/15` §3 · D-47 · D-48
9. Migraciones solo hacia adelante; la base de datos de la nube nunca se edita a mano.
10. Los eventos de tiempo real llevan identificadores y versión, nunca montos. → `docs/09` §4 · D-32

## Uso de spec-kit (Development Workflow)

El flujo y las reglas de uso están en `CLAUDE.md`: "Flujo para implementar una historia" y "Reglas de spec-kit (D-56)". Lo que todo comando del kit debe tener presente:

- La entrada de una spec es una historia de `backlog/`. `specs/` es un derivado de `docs/` y de `backlog/`.
- La spec conserva los criterios de aceptación con su `CA-n` y cita los `FR` del catálogo; no crea requisitos ni criterios.
- El plan parte de los módulos de `docs/17` y se implementa por capas, cada una con sus pruebas: migración → RPC y funciones `private` → Edge Functions → app.
- Las tareas salen de la sección "Tareas" de la historia.
- Los issues salen del backlog; el kit no los crea.

## Gobierno (Governance)

- **Precedencia**: `docs/` → `CLAUDE.md` → esta constitución → `spec.md`, `plan.md` y `tasks.md`. En caso de conflicto manda `docs/`.
- **Cambios**: las reglas se cambian en `docs/` y en `CLAUDE.md`, con el procedimiento de la regla de oro 2. Después se ajusta esta constitución para que siga diciendo lo mismo; nunca al revés.
- **Versiones**: mayor si se quita o se redefine un principio, menor si se agrega uno, parche si solo cambia la redacción.
- **Cumplimiento**: `/speckit-plan` y `/speckit-analyze` revisan estos principios; el PR lo confirma con su plantilla y con `scripts/verificar.sh` en verde.

**Version**: 1.0.0 | **Ratified**: 2026-10-12 | **Last Amended**: 2026-10-12

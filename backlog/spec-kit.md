# spec-kit: qué tiene y cómo encaja con este backlog

Documento informativo. Describe la herramienta [github/spec-kit](https://github.com/github/spec-kit) y cómo se usaría con las historias de esta carpeta. **No la instala ni cambia ninguna regla del proyecto.** Lo que haría falta para adoptarla está en la [última sección](#qué-haría-falta-para-adoptarlo).

Fuentes: el repositorio de spec-kit, su [documentación](https://github.github.io/spec-kit/) y su plantilla de especificación, consultados el 9 de octubre de 2026. La herramienta cambia seguido: los nombres de comandos y opciones hay que confirmarlos con la versión que se instale.

## Qué es

spec-kit es un conjunto de herramientas de código abierto de GitHub para el **desarrollo guiado por especificaciones**: primero se escribe qué se quiere y por qué, luego un plan técnico, luego las tareas y al final el código. Le da al agente de IA un proceso con pasos, plantillas y resultados escritos, en lugar de pedirle código directamente.

Tiene tres piezas:

1. Una **línea de comandos**, `specify`, que prepara el repositorio.
2. Unos **comandos para el agente** que `specify` instala en el repositorio. En Claude Code se instalan como skills dentro de `.claude/skills`.
3. Unas **plantillas** en Markdown que definen la forma de cada documento.

## Qué necesita

- Python 3.11 o superior y `uv`.
- Un agente compatible. Su documentación lista 38 integraciones; la de Claude Code tiene la clave `claude`.
- Windows, macOS o Linux. Git es opcional, salvo que se active su extensión de git.

## Cómo se instala

```bash
# Con una versión fija (la documentación usa v0.12.11 como ejemplo)
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@vX.Y.Z

# Comprobar la instalación y si hay una versión más nueva
specify version
specify self check

# Prepararlo en un repositorio que ya existe, para Claude Code
specify init --here --force --non-interactive --integration claude
```

La opción `--script` elige el tipo de scripts auxiliares: `ps` (PowerShell, el valor por defecto en Windows), `sh` (Bash, el valor por defecto en Linux y macOS) o `py`. `--force` acepta el aviso de que la carpeta no está vacía; antes conviene tener los cambios locales guardados en un commit.

## Qué deja en el repositorio

| Ruta | Para qué |
|---|---|
| `.specify/memory/constitution.md` | La "constitución": los principios que todo plan debe respetar |
| `.specify/templates/` | Las plantillas de especificación, plan y tareas |
| `.specify/templates/overrides/` | Plantillas propias del proyecto, que tienen prioridad sobre las demás |
| `.specify/scripts/` | Scripts auxiliares en la variante elegida (`bash/`, `powershell/` o `python/`) |
| `.claude/skills/` | Los comandos que usa el agente |
| `specs/NNN-nombre/` | Una carpeta por funcionalidad, numerada (001, 002 y así) |

Dentro de cada carpeta de `specs/`:

| Archivo | Contenido |
|---|---|
| `spec.md` | Requisitos, historias de usuario y criterios de aceptación |
| `plan.md` | El plan técnico, con sus decisiones y su porqué |
| `research.md` | Comparación de alternativas técnicas |
| `data-model.md` | Entidades y esquemas |
| `contracts/` | Definiciones de APIs y eventos |
| `quickstart.md` | Los escenarios clave para validar |
| `tasks.md` | La lista de tareas ejecutables |

## Los comandos

El proceso central, en orden:

| Comando | Cuándo | Qué produce |
|---|---|---|
| `/speckit-constitution` | Una vez por proyecto | La constitución |
| `/speckit-specify` | Por funcionalidad | `spec.md`, y la carpeta y la rama numeradas |
| `/speckit-plan` | Por funcionalidad | `plan.md` y los documentos de diseño |
| `/speckit-tasks` | Por funcionalidad | `tasks.md`, con las tareas que se pueden hacer en paralelo marcadas `[P]` |
| `/speckit-implement` | Por funcionalidad | El código y las pruebas |
| `/speckit-converge` | Por funcionalidad | La comprobación de que el código cumple; se repite con `implement` hasta que informa "Converged" |

Además tiene puertas de calidad opcionales (aclarar ambigüedades, listas de verificación y análisis de consistencia entre especificación, plan y tareas) y un comando que convierte las tareas en issues de GitHub (`taskstoissues`). En su documentación de metodología los comandos aparecen escritos con punto (`/speckit.specify`, `/speckit.clarify`, `/speckit.analyze`); la forma exacta depende de la versión y de la integración.

También trae dos extensiones que se instalan aparte: una para corregir errores (`specify extension add bug`) y otra para evaluar una idea antes de construirla (`specify extension add assess`).

## La plantilla de especificación

`spec.md` tiene estas secciones:

| Sección | Qué pide |
|---|---|
| User Scenarios & Testing | Historias de usuario con prioridad (P1, P2…), por qué tienen esa prioridad, cómo se prueban de forma independiente y sus escenarios de aceptación en la forma *Given / When / Then* |
| Edge Cases | Los casos límite y de error |
| Functional Requirements | Requisitos numerados `FR-001`, redactados como "System MUST…" |
| Key Entities | Las entidades de datos, sin detalles de implementación |
| Success Criteria | Resultados medibles, numerados `SC-001` |
| Assumptions | Los supuestos que se tomaron |

Cuando falta información, la plantilla obliga al agente a escribir `[NEEDS CLARIFICATION: …]` en lugar de adivinar.

## Cómo se personaliza

Al buscar una plantilla, spec-kit usa la primera que encuentra en este orden: las del proyecto en `.specify/templates/overrides/`, los *presets* instalados, las extensiones y, al final, las plantillas base. Los *presets* (`specify preset search`, `specify preset add`) sirven para cambios reutilizables, como traducir el flujo o exigir trazabilidad.

## Cómo encaja con este backlog

La unidad acordada es **una funcionalidad de spec-kit por historia**, que coincide con el flujo de `CLAUDE.md`: una historia, una rama y un PR. Cada historia de este backlog ya trae lo que la plantilla de spec-kit pide:

| En spec-kit | En este backlog |
|---|---|
| Entrada de `/speckit-specify` | El archivo de la historia |
| User Story (P1) | La sección "Historia": *Como / quiero / para* |
| Acceptance Scenarios (*Given / When / Then*) | Los criterios de aceptación (*Dado / cuando / entonces*) |
| Edge Cases | Los casos borde `CB` citados |
| Functional Requirements (`FR-001`) | Los `FR-xxx` del [catálogo](requisitos-funcionales/README.md). El prefijo es el mismo a propósito |
| Key Entities | Las tablas que nombran las tareas y las notas técnicas (`docs/06`) |
| Success Criteria | El escenario E2E de la historia y los indicadores de `docs/01` §6 |
| `[NEEDS CLARIFICATION]` | La sección "Documentación a actualizar" |
| `plan.md` | Los módulos de `docs/17` y las secciones de `docs/` de esos módulos |
| `tasks.md` | La sección "Tareas", ya en el orden por capas de `CLAUDE.md` |
| Constitución | Las reglas de oro y los invariantes de `CLAUDE.md` |

Ejemplo con [HU-062 · Aprobar una sugerencia de mi cupo](E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md):

```
/speckit-specify Especifica la historia backlog/E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md. Usa su narrativa, sus criterios de aceptación y sus casos borde tal como están, y cita los FR del catálogo en lugar de crear otros.
/speckit-plan Usa los módulos y las secciones de docs/ que indica docs/17 para esta historia. Capas: migración, funciones de base de datos, Edge Functions, app y E2E.
/speckit-tasks
/speckit-implement
```

## Puntos donde spec-kit y el proyecto no coinciden

| Tema | spec-kit | El proyecto hoy |
|---|---|---|
| Fuente de verdad | `spec.md` de cada funcionalidad | `docs/` (regla de oro 1). El `spec.md` de una historia sería un derivado |
| Ambigüedades | Marca `[NEEDS CLARIFICATION]` y las resuelve en la conversación | Se detiene y actualiza `docs/` primero (regla de oro 2) |
| Nombre de la rama | `NNN-nombre`, con numeración propia | `hu-<número>-<descripcion-corta>` (`docs/15` §7) |
| Idioma | Plantillas y comandos en inglés | Documentación en español |
| Issues | Puede crearlos desde `tasks.md` | Salen de este backlog (`docs/16` §6) |
| Principios | Constitución en `.specify/memory/` | `CLAUDE.md`, que el agente ya lee al empezar |
| Carpetas | `.specify/`, `specs/` y `.claude/skills/` | No están en la estructura de `docs/05` §12 |

## Qué haría falta para adoptarlo

Adoptar spec-kit cambia el flujo de trabajo, así que según la regla de oro 2 primero hay que escribirlo en `docs/`. No se hizo en esta etapa. Lo que habría que decidir y documentar:

1. Actualizar `CLAUDE.md` (flujo para implementar una historia), `docs/15` §7 (ramas), `docs/16` §3.7 y §3.8 (herramientas: `uv` y `specify`), `docs/05` §12 (estructura del repositorio) y `docs/17` (rutas), y anotarlo en el historial de `docs/13` §4.
2. Decidir el nombre de las ramas y de las carpetas de `specs/`, y cómo se relacionan con el número del issue.
3. Escribir la constitución de forma que remita a `CLAUDE.md` y a `docs/` en vez de duplicarlos, para no tener dos fuentes de verdad.
4. Poner plantillas en español en `.specify/templates/overrides/` que pidan citar `RN`, `RR`, `PM`, `CB` y `FR`.
5. No usar la conversión de tareas a issues, para no duplicar el backlog.
6. Después de instalarlo, revisar qué archivos tocó y confirmar que no alteró `CLAUDE.md`.
7. Fijar la versión instalada y anotarla, porque la herramienta cambia seguido.

Es gratuita y solo necesita Python y `uv`, así que no choca con la regla de usar herramientas gratuitas (`docs/13`, D-45).

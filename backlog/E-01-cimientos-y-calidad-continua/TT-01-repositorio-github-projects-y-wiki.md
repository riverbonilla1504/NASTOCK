# TT-01 · Repositorio, GitHub Projects y wiki

| Campo | Valor |
|---|---|
| Épica | [E-01 · Cimientos y calidad continua](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Prioridad | Alta |
| Módulos afectados | M-20 |
| Estimación | Por definir al refinar |
| Etiquetas | `tarea-tecnica` · `E-01` · `M-20` · `prioridad-alta` |

## Qué hay que hacer y por qué

Dejar el repositorio listo para trabajar: la especificación, `CLAUDE.md`, los flujos y las plantillas en `main`; la wiki habilitada y publicada desde `docs/`; las etiquetas, los hitos y el proyecto de GitHub creados; y este backlog publicado como issues. Sin esto no hay dónde llevar el control ni un CI que valide la documentación.

## Documentación fuente

16 §1 · 16 §2 · 16 §3.1 · 16 §5 · 16 §6 · 15 §6

## Requisitos funcionales

Ninguno: este ítem no agrega un requisito funcional del producto.

## Criterio de terminado

- [ ] `ci.yml` corre en `main` y su trabajo `documentacion` está en verde.
- [ ] La wiki muestra las páginas generadas desde `docs/` con el aviso de que no se edita a mano.
- [ ] Existen las etiquetas (`historia`, `epica`, `tarea-tecnica`, prioridades, `E-01` a `E-13` y `M-01` a `M-20`), los hitos R1 a R6 y el proyecto "RiTech SAS · MVP" con los campos Épica, Entrega, Prioridad, Módulos y Estimación.
- [ ] Las épicas, historias y tareas técnicas de `backlog/` existen como issues: cada una con su hito y sus etiquetas, y cada historia como sub-issue de su épica.
- [ ] `scripts/verificar.sh` completo en verde y CI en verde.

## Tareas

- [ ] Decidir la visibilidad del repositorio (Q-18) y, si el plan lo permite, proteger `main` exigiendo los trabajos de `ci.yml` y un PR.
- [ ] Habilitar la wiki (`gh repo edit --enable-wiki`) y crear a mano su primera página, requisito de `wiki.yml`.
- [ ] Ejecutar `gh auth refresh -s project` y `scripts/github/preparar-github.sh <dueño>/<repo>`.
- [ ] Pasos manuales del proyecto: opciones de Status (Backlog, Listo, En curso, En revisión, Hecho) y vistas Tablero, Por entrega y Por épica.
- [ ] Publicar el backlog con los comandos de 16 §6.2: crear los issues desde `backlog/`, enlazar las historias como sub-issues, agregarlos al proyecto y fijar sus campos.
- [ ] Confirmar que Dependabot está activo y que `CLAUDE.md` y `docs/errores-conocidos.md` están en la raíz y en `docs/`.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Habilita | [TT-02 · Cuentas, conexiones y secretos de los servicios externos](TT-02-cuentas-conexiones-y-secretos-de-los-servicios-externos.md) | TT-02: los secretos y variables se cargan en el repositorio. |
| Habilita | [TT-03 · Base de Supabase: esquema private, extensiones, Vault y ping](TT-03-base-de-supabase-esquema-private-extensiones-vault-y-ping.md) | TT-03: las migraciones viven en el repositorio y las valida CI. |
| Habilita | [TT-04 · Esqueleto de la app Flutter para Android y web](TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) | TT-04: el código de la app vive en el repositorio y lo valida CI. |

No depende de ningún otro ítem: se puede empezar de inmediato.

## Notas

El repositorio ya existe con la especificación v3.1 (un commit). Lo pendiente es GitHub Projects, la wiki y la publicación del backlog.

---
version: 1
slug: "lib-app-catalogo-pagina-catalogo-dart"
primary_target: "lib/app/catalogo/pagina_catalogo.dart"
related_targets: ["lib/shared/widgets","lib/app/tema.dart"]
---

## Scope

Sistema de diseño de la app (tema, componentes comunes y catálogo de componentes) para HU-116. Modo: Operate. Plataforma: android (Flutter Material 3, misma interfaz en la web).

## Audience and task

Empleados (Usuario y Analista) en el teléfono durante la jornada; administrador en la web de escritorio. Leer precios con su antigüedad, saber si el mercado está abierto, crear órdenes y entender avisos sin depender del color.

## Chosen direction

Almanaque en grises, aprobado por Javier el 2026-11-06 (mock: .impeccable/mocks/especimen-almanaque-gris.html).

## Direction contract

THESIS: El mercado es cuestión de horas: la jornada, el día y el mes son estructura visible y cada cifra dice de cuándo es. Rechaza el tablero de trading en negro con verde neón y el "panel de IA" con degradados.

OWN-WORLD: Papel gris claro, hojas blancas, tinta casi negra y barra superior en grafito. Color solo en datos: morado para la línea de gráfica, la aguja de ahora y hoy; verde y rojo apagados solo en variaciones con flecha y signo. Archivo normal y condensada, cifras tabulares, reglas de 1 px y esquinas de 4 dp.

STORY: La persona abre Mercado, ve en la barra si la jornada está abierta y cuánto falta, lee la lista de precios con su antigüedad y nota de inmediato un precio desactualizado; decide sin que el color sea el único aviso.

FIRST VIEWPORT: Teléfono. Barra grafito con el título condensado, la franja de la jornada 09:30–16:00 con lo transcurrido en trazo grueso y la aguja morada de ahora, y el tiempo al cierre. Debajo, lista en hoja blanca con símbolo, precio en USD, variación y antigüedad; botón flotante Nueva orden en tinta; barra de navegación Material con la pestaña actual en morado tenue.

FORM: Almanaque, candidata 6 de 7 de la lista propia, asignada por el sorteo; seed: d449656214b9c425. Firma: la franja de la jornada. Disciplinas tomadas: estado por forma de línea, color solo en lo vigente, módulo de 4 dp, antes y después a la vista, sin esperas visibles.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Unresolved

Ninguno.

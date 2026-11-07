---

description: "Tareas de HU-116 · Identidad visual y sistema de diseño"
---

# Tareas: HU-116 · Identidad visual y sistema de diseño

**Entrada**: documentos de diseño en `specs/116-tema-y-estilos-de-la-v2/`

**Requisitos previos**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/componentes.md](contracts/componentes.md)

**Pruebas**: la historia las pide (CA-7: cada componente con su prueba de widget; CA-10: la ruta del catálogo; CA-12: `flutter analyze` y `flutter test`).

**Organización**: una sola historia de usuario (US1, P1), construida por capas: fuente → tokens y tema → componentes → catálogo → documentación visual. Las tareas salen de la sección "Tareas" de la historia. Solo capa de app: no toca `supabase/`.

## Formato: `[ID] [P?] [Historia] Descripción`

- **[P]**: se puede hacer en paralelo (archivos distintos, sin depender de una tarea incompleta)
- **[US1]**: la única historia de usuario de esta especificación

---

## Fase 1: Preparación

- [X] T001 Escribir `PRODUCT.md` desde `docs/01` a `docs/04` y la ronda de preguntas de impeccable (CA-4)
- [X] T002 Proponer la dirección visual con mocks en `.impeccable/mocks/` (fuera del repositorio) y conseguir la aprobación de Javier: Almanaque con paleta gris y morado (2026-11-06)
- [X] T003 Escribir el contrato de dirección de impeccable en `.impeccable/surfaces/` con `impeccable surface-brief write`

---

## Fase 2: Fundamentos

- [X] T004 Guardar las 7 instancias de Archivo, `OFL.txt` y `LEEME.md` (origen y cómo se generaron) en `assets/fonts/archivo/` y registrar las familias `Archivo` (400, 500, 600, 700) y `ArchivoCondensado` (600, 700, 800) en `pubspec.yaml` (CA-12, R-1)
- [X] T005 Agregar `formatearPorcentaje` en `lib/core/formato/formato_porcentaje.dart` con su prueba en `test/core/formato/formato_porcentaje_test.dart` (R-9)

---

## Fase 3: Historia de usuario 1 · Identidad visual y sistema de diseño (P1)

**Objetivo**: toda pantalla nueva se arma con los tokens y los componentes del sistema.

**Prueba independiente**: el catálogo muestra todos los componentes en claro y en oscuro, y cada componente tiene su prueba de widget.

### Tokens y tema

- [X] T006 [US1] Crear `ColoresAlmanaque` (los 16 colores de [data-model.md](data-model.md) en claro y oscuro), `ProfundidadAlmanaque`, `Espacio`, `Radios`, `Duracion` y `Familias`, y `crearTema()` y `crearTemaOscuro()` con Material 3 en `lib/app/tema.dart` (CA-6)
- [X] T007 [US1] Aplicar `darkTheme` y `themeMode: ThemeMode.system` en `lib/app/aplicacion.dart`
- [X] T008 [P] [US1] Probar en `test/app/tema_test.dart` que ambos temas traen la extensión, usan Archivo y que cada par de texto cumple 4,5:1

### Componentes

- [X] T009 [P] [US1] Botones primario, secundario y de texto con estado "Procesando…" (08 §9.3) en `lib/shared/widgets/botones.dart` y su prueba en `test/shared/widgets/botones_test.dart`
- [X] T010 [P] [US1] `Tarjeta` en `lib/shared/widgets/tarjeta.dart` y su prueba en `test/shared/widgets/tarjeta_test.dart`
- [X] T011 [P] [US1] `Campo` con estados de foco, error y solo lectura en `lib/shared/widgets/campo.dart` y su prueba en `test/shared/widgets/campo_test.dart`
- [X] T012 [US1] Pintor de bordes por forma de línea (fina, sólida, discontinua, doble, punteada) en `lib/shared/widgets/forma_de_linea.dart` (R-4)
- [X] T013 [US1] `AvisoEnLinea` con sus cinco tipos y `AvisoEnLinea.deError`, y `mostrarAvisoTemporal`, en `lib/shared/widgets/avisos.dart`, con prueba en `test/shared/widgets/avisos_test.dart`: cada tipo se distingue sin color (CA-8) y el error pasa por `traducirError` (CA-9)
- [X] T014 [US1] `MensajeDeError` dibujado con el aviso de error en `lib/shared/widgets/mensaje_de_error.dart`, sin cambiar su constructor ni sus pruebas (R-5)
- [X] T015 [P] [US1] `EstadoVacio`, `EstadoCargando` y `EstadoDeError` en `lib/shared/widgets/estados.dart` y su prueba en `test/shared/widgets/estados_test.dart`
- [X] T016 [P] [US1] `CifraUsd`, `Variacion` y `AntiguedadDelDato` en `lib/shared/widgets/cifras.dart` y su prueba en `test/shared/widgets/cifras_test.dart`
- [X] T017 [P] [US1] `ChipDeEstado` en `lib/shared/widgets/chip_de_estado.dart` y su prueba en `test/shared/widgets/chip_de_estado_test.dart`
- [X] T018 [P] [US1] `GraficaDeLinea` en `lib/shared/widgets/grafica_de_linea.dart` y su prueba en `test/shared/widgets/grafica_de_linea_test.dart` (R-8)
- [X] T019 [US1] `TarjetaDeCotizacion` en `lib/shared/widgets/tarjeta_de_cotizacion.dart` y su prueba en `test/shared/widgets/tarjeta_de_cotizacion_test.dart`
- [X] T020 [US1] `CalendarioDelMercado`, `mostrarSelectorDePeriodo` y `CampoDePeriodo` en `lib/shared/widgets/calendario.dart` y su prueba en `test/shared/widgets/calendario_test.dart` (R-7)
- [X] T021 [P] [US1] `FranjaDeLaJornada` en `lib/shared/widgets/franja_de_la_jornada.dart` y su prueba en `test/shared/widgets/franja_de_la_jornada_test.dart`

### Catálogo

- [X] T022 [US1] Página del catálogo con todos los componentes y un interruptor claro/oscuro en `lib/app/catalogo/pagina_catalogo.dart`
- [X] T023 [US1] Ruta `/catalogo` solo en debug o con `MODO_PRUEBAS` en `lib/app/enrutador.dart`, y enlace en `lib/app/pagina_inicio.dart` solo cuando la ruta existe (CA-10, R-6)
- [X] T024 [US1] Probar en `test/app/catalogo_test.dart` que la ruta existe con el permiso, no existe sin él y que el catálogo abre sin errores

---

## Fase 4: Documentación visual y cierre

- [X] T025 Revisar el catálogo en Chrome y en el emulador Android (claro, oscuro y texto al 130 %) y guardar las capturas en `.impeccable/review/`
- [X] T026 Revisión final con el revisor de impeccable y corrección de lo que encuentre
- [X] T027 `DESIGN.md` y `.impeccable/design.json` con el documentador de impeccable, a partir de lo construido (CA-5)
- [X] T028 `/impeccable audit` y `/impeccable polish` sobre el catálogo y los componentes; corregir lo encontrado (CA-11)
- [X] T029 [P] Actualizar `docs/17-mapa-de-modulos.md` (M-20: `DESIGN.md`, `PRODUCT.md`, `.impeccable/`, `assets/fonts/`, tema, widgets y catálogo) y enlazar `DESIGN.md` desde `docs/05` §9 y §11 y `docs/15` §12
- [X] T030 `flutter analyze` y `flutter test` sin advertencias ni fallos (CA-12)
- [X] T031 `git fetch origin && git rebase origin/main` y `scripts/verificar.sh` completo en verde, con el candado del stack compartido

---

## Dependencias

- T004 y T005 antes de los componentes (fuente y formato).
- T006 antes de T009 a T021: todos leen los tokens.
- T012 antes de T013 y T017 (bordes y líneas por forma).
- T016 y T018 antes de T019 (la tarjeta de cotización usa cifras y gráfica).
- T009 a T021 antes de T022 (el catálogo los muestra).
- T025 a T028 después del catálogo.

## Paralelo

```text
T009 · T010 · T011 · T015 · T016 · T017 · T018 · T021   (archivos distintos, solo dependen de T006)
```

## Estrategia

Una sola historia: se entrega completa. Primero fuente y tema (la app entera cambia de aspecto), después los componentes con sus pruebas, el catálogo para revisarlos juntos y al final la documentación visual de impeccable.

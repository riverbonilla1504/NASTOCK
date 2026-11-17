# Tareas: HU-117 · Exportador de reportes de la v2 con sus pruebas

**Entrada**: [spec.md](spec.md) y [plan.md](plan.md) · **Issue**: #145 · **Módulo**: M-15

Salen de la sección "Tareas" de la historia: copiar el exportador y su prueba
de la v2, adaptarlo al formato de dinero y fechas de `lib/core/`, correr
`flutter test` y `scripts/verificar.sh` completo. Las pruebas son obligatorias
(CA-1 exige que la prueba copiada pase).

Formato: `[ID] [P?] [Historia] Descripción`. `[P]` = se puede hacer en
paralelo (otro archivo, sin dependencias pendientes).

## Fase 1: Preparación

- [ ] T001 Traer `lib/services/report_exporter.dart` y `test/report_exporter_test.dart` del repositorio v2 (`T0m4s1n/ritech-sas-inversiones`) como referencia, fuera del repositorio (no se versionan tal cual: sus modelos no existen en la v3)

## Fase 2: Base compartida (bloquea la historia)

- [ ] T002 Crear `celdaCsv(String? dato)` en `lib/core/exportacion/celda_csv.dart`: celda entre comillas, comillas internas duplicadas y apóstrofo delante si empieza con `=`, `+`, `-`, `@` (tras espacios) o con tabulador o retorno; `null` → `""`
- [ ] T003 [P] Pruebas de `celdaCsv` en `test/core/exportacion/celda_csv_test.dart` (comillas, fórmulas, nulo, texto normal)
- [ ] T004 Usar `celdaCsv` en `lib/features/admin/bitacora/data/csv_de_bitacora.dart` en lugar de su `_celda` privada, sin cambiar el CSV (las pruebas de `test/features/admin/bitacora/` siguen pasando sin cambios)

## Fase 3: Historia 1 · Exportador de la v2 con sus pruebas (P1) 🎯

**Objetivo**: el exportador de la v2 queda en `lib/features/reportes/` con su
prueba en verde (CA-1), genera CSV con encabezados y montos en el formato de
la app (CA-2) y guarda el archivo en web y Android (CA-3).

**Prueba independiente**: `flutter test test/features/reportes` y
`flutter test --platform chrome test/features/reportes/guardar_reporte_web_test.dart`.

### Pruebas (primero, deben fallar)

- [ ] T005 [P] [US1] Adaptar la prueba de la v2 a `test/features/reportes/exportador_de_reportes_test.dart`: CSV con encabezado, filas y totales; periodo y fecha de generación; sin filas no genera archivo y avisa; solo exporta las filas que recibe. Sin el caso del formato texto (01 §4: solo CSV)
- [ ] T006 [P] [US1] Casos nuevos de CA-2 en el mismo archivo: montos `USD 1.234,50`, porcentajes `+1,24 %`, instantes en hora de Bogotá (`DD/MM/AAAA HH:MM`), BOM al inicio, CRLF, celdas con coma entre comillas, fórmulas neutralizadas y nombre `<base>-AAAAMMDD.csv` con la fecha de Bogotá
- [ ] T007 [P] [US1] Prueba de guardado en Android en `test/features/reportes/guardar_reporte_test.dart`: con el canal `inversiones/exportacion` simulado, `guardarReporte` envía `guardarCsv` con nombre y contenido; con un resultado vacío no llama al canal y devuelve `false`
- [ ] T008 [P] [US1] Prueba de guardado web en `test/features/reportes/guardar_reporte_web_test.dart` con `@TestOn('browser')`: `guardarReporte` con el `guardarCsv` real devuelve `true` y no deja enlaces en el documento

### Implementación

- [ ] T009 [US1] Crear `lib/features/reportes/data/exportador_de_reportes.dart` (copia adaptada de `report_exporter.dart`): `FormatoDeCelda` (`texto`, `dinero`, `porcentaje`, `fecha`, `fechaHora`), `ColumnaDeReporte<T>`, `TotalDeReporte`, `ResultadoDeReporte` (`.listo` / `.vacio`), `ExportadorDeReportes.csv<T>` con `formatearUsd`, `formatearPorcentaje`, `formatearFecha` y `formatearFechaHora` de `lib/core/formato/`, y `celdaCsv`
- [ ] T010 [US1] Agregar `guardarReporte(ResultadoDeReporte, {GuardarArchivo guardar = guardarCsv})` en el mismo archivo, que delega en `lib/core/exportacion/guardar_csv.dart`
- [ ] T011 [US1] Correr `flutter test` y `dart format` / `flutter analyze` hasta verde

**Punto de control**: CA-1, CA-2 y CA-3 demostrados por pruebas.

## Fase 4: Cierre

- [ ] T012 Correr las pruebas `@TestOn('browser')` en Chrome: paso nuevo en `scripts/verificar.sh` (bloque App Flutter) y en el trabajo `app` de `.github/workflows/ci.yml`
- [ ] T013 [P] Actualizar `docs/17-mapa-de-modulos.md` (M-15: rutas de `lib/features/reportes/` y `lib/core/exportacion/celda_csv.dart`) y `docs/15-calidad-pruebas-y-ci-cd.md` §2 y §6 (pruebas web en Chrome)
- [ ] T014 `scripts/verificar.sh` completo en verde (incluye E2E de backend y de la app)
- [ ] T015 PR hacia `main` con la plantilla, `Closes #145` y la carpeta `specs/117-exportador-de-reportes/`

## Dependencias

- T002 → T004 y T009. T005–T008 se escriben antes de T009–T010.
- T012 depende de T008. T014 depende de todo lo anterior; T015 de T014.
- Sin escenario E2E propio (15 §4): no se agrega ni cambia ningún E2E.

## Paralelo

T003, T005, T006, T007 y T008 tocan archivos distintos y se pueden escribir a
la vez. T013 puede ir en paralelo con T012.

## Estrategia

Una sola historia (P1): es el MVP. Se entrega completa en un PR; HU-095 y
HU-108 la usan después sin cambiarla.

# Plan: HU-117 · Exportador de reportes de la v2 con sus pruebas

**Rama**: `117-exportador-de-reportes` · **Issue**: #145 · **Módulo**: M-15 · **Spec**: [spec.md](spec.md)

## Resumen

Se copia `lib/services/report_exporter.dart` y su prueba del repositorio v2
(`T0m4s1n/ritech-sas-inversiones`, `docs/05` §11) a `lib/features/reportes/`.
En la v2 el exportador estaba atado a sus modelos (`InvestmentView`,
`Investment`), que no existen en la v3; se adapta a **columnas y filas
genéricas** para que lo usen la bitácora (HU-108) y los reportes CSV (HU-095)
sin tocarlo. Los montos y las fechas salen con el formato de `lib/core/formato/`
y el archivo se guarda con `lib/core/exportacion/guardar_csv.dart`, que ya
descarga en la web y abre el selector de archivos en Android (HU-108).

## Contexto técnico

- **Lenguaje**: Dart con Flutter 3.47.9 (fijado, EC-038). Sin dependencias nuevas.
- **Almacenamiento**: ninguno. No toca base de datos, RPC ni Edge Functions.
- **Pruebas**: `flutter test` (VM) y `flutter test --platform chrome` para la
  parte web del guardado (CA-3).
- **Plataformas**: web y Android (S2, `docs/01` §5).
- **Restricciones**: dinero en USD con dos decimales (`USD 1.234,50`); horas en
  UTC mostradas en hora de Bogotá (RN-42); el CSV no debe poder ejecutar
  fórmulas al abrirse en una hoja de cálculo (mismo criterio que la bitácora).

## Revisión de la constitución

| Principio | Cumple | Cómo |
|---|---|---|
| I · `docs/` manda | Sí | 05 §11 dice qué se copia; 01 §4 fija CSV en el MVP (PDF fuera); FR-203 |
| II · Documentación primero | Sí | La historia estaba fuera del MVP corto (D-58); se adelantó con el cambio 3.31 de 13 §4, aprobado antes de implementar |
| III · Sincronía | Sí | `docs/17` (M-15) y `docs/15` §2 y §6 se actualizan en este PR |
| IV · Investigación acotada | Sí | Solo M-15 y `lib/core/exportacion/` (M-17, interfaz de guardado) |
| V · Errores conocidos | Sí | Sin entradas para M-15 que apliquen; EC-011 es de vistas SQL |
| VI · Siempre funcionando | Sí | Pruebas nuevas y `scripts/verificar.sh` completo |
| VII · Alcance y costo | Sí | Sin paquetes nuevos ni servicios |
| Invariantes | Sí | No escribe datos, no usa llaves, no envía nada a terceros |

## Investigación (decisiones)

1. **Genérico en vez de modelos de la v2.** *Decisión*: el exportador recibe
   `List<ColumnaDeReporte<T>>` y `List<T>`. *Por qué*: los modelos de la v2 no
   existen y cada reporte de la v3 tiene sus columnas. *Alternativa
   descartada*: copiar `InvestmentView`, que arrastraría el modelo en memoria
   de la v2 que 05 §11 dice que no se copia.
2. **Solo CSV.** *Decisión*: se quita el formato texto de la v2. *Por qué*:
   01 §4 fija CSV en el MVP y deja el PDF para una fase posterior; Q-15 sigue abierta con
   "CSV mensual" como valor provisional.
3. **Se conserva el comportamiento probado de la v2**: título, periodo y
   fecha de generación arriba; una fila de encabezados; totales al final; sin
   filas no se genera archivo y se devuelve un mensaje; nombre de archivo con
   la fecha (`<base>-AAAAMMDD.csv`); solo se exportan las filas que recibe
   (los filtros los aplica quien llama).
4. **Formato de la app.** Montos con `formatearUsd`, porcentajes con
   `formatearPorcentaje`, instantes con `formatearFecha`/`formatearFechaHora`
   (Bogotá). El periodo (`desde`, `hasta`) son días calendario y se escriben
   tal cual, sin cambiar de zona. Como `USD 1.234,50` lleva coma, **toda
   celda va entre comillas** (RFC 4180).
5. **Mismo CSV que la bitácora.** BOM UTF-8 (Excel reconoce las tildes), fin
   de línea CRLF y neutralización de fórmulas (`=`, `+`, `-`, `@` al inicio
   o tabulador/retorno). La función de celda se mueve de
   `csv_de_bitacora.dart` a `lib/core/exportacion/celda_csv.dart` y la usan
   los dos. El formato del CSV de la bitácora no cambia.
6. **Guardado en las dos plataformas.** `guardarReporte` delega en
   `guardarCsv` (importación condicional web/móvil ya existente) y recibe la
   función por parámetro para poder probarla. Android se prueba con el canal
   `inversiones/exportacion` simulado; la web, con una prueba
   `@TestOn('browser')` que corre en Chrome en `verificar.sh` y en CI.

## Diseño

Contrato público de `lib/features/reportes/data/exportador_de_reportes.dart`:

| Elemento | Qué es |
|---|---|
| `FormatoDeCelda` | `texto`, `dinero`, `porcentaje`, `fecha`, `fechaHora` |
| `ColumnaDeReporte<T>` | `encabezado`, `valor(T fila)` y `formato` |
| `TotalDeReporte` | `etiqueta` y `monto` (se escribe como dinero) |
| `ResultadoDeReporte` | `.listo(contenido, nombreDeArchivo)` o `.vacio(mensaje)`; `exito` |
| `ExportadorDeReportes.csv<T>(...)` | Arma el CSV: `titulo`, `nombreBase`, `columnas`, `filas`, `generadoEn`, `desde?`, `hasta?`, `totales` |
| `guardarReporte(resultado, {guardar})` | Guarda en web o Android; `false` si el resultado está vacío o la persona cancela |

Forma del archivo (cada celda entre comillas, líneas con CRLF):

```
﻿"Reporte de <título> · RiTech SAS"
"Periodo","01/01/2026 a 30/06/2026"      ← o "Todo el histórico"
"Generado","15/06/2026 10:30"            ← hora de Bogotá

"<encabezado 1>","<encabezado 2>",...
"<celda>","<celda>",...

"Total invertido","USD 2.000,00"         ← un renglón por total
```

## Estructura

```
lib/core/exportacion/celda_csv.dart                       nuevo (sale de la bitácora)
lib/features/admin/bitacora/data/csv_de_bitacora.dart      usa celdaCsv
lib/features/reportes/data/exportador_de_reportes.dart     nuevo (copia adaptada de la v2)
test/core/exportacion/celda_csv_test.dart                  nuevo
test/features/reportes/exportador_de_reportes_test.dart    nuevo (prueba de la v2 adaptada + CA-2)
test/features/reportes/guardar_reporte_test.dart           nuevo (Android, canal simulado)
test/features/reportes/guardar_reporte_web_test.dart       nuevo (@TestOn('browser'), CA-3)
scripts/verificar.sh · .github/workflows/ci.yml             corren las pruebas web en Chrome
docs/17 (M-15) · docs/15 §2 y §6                           rutas y paso nuevo
```

## Validación (quickstart)

```bash
flutter test test/features/reportes test/core/exportacion test/features/admin/bitacora
flutter test --platform chrome test/features/reportes/guardar_reporte_web_test.dart
scripts/verificar.sh
```

Resultado esperado: las pruebas copiadas de la v2 pasan adaptadas (CA-1); el
CSV trae encabezados y montos `USD 1.234,50` (CA-2); `guardarReporte` llama
al selector de Android por el canal y descarga en Chrome (CA-3); el CSV de la
bitácora sigue igual (sus pruebas no cambian).

## Orden

Celda compartida → exportador y sus pruebas → guardado en Android y web →
pasos de CI y `verificar.sh` → `docs/17` y `docs/15` → verificación completa
→ PR.

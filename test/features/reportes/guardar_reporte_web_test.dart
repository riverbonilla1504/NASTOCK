// HU-117 · CA-3 en la web: con el `guardarCsv` real de la web, el reporte se
// descarga desde un enlace temporal. Corre solo en Chrome:
//   flutter test --platform chrome test/features/reportes/guardar_reporte_web_test.dart
@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/features/reportes/data/exportador_de_reportes.dart';
import 'package:web/web.dart' as web;

void main() {
  test('descarga el CSV y no deja el enlace en la página', () async {
    final reporte = ExportadorDeReportes.csv<String>(
      titulo: 'prueba',
      nombreBase: 'reporte-prueba',
      columnas: [ColumnaDeReporte('dato', (d) => d)],
      filas: const ['a'],
      generadoEn: DateTime.utc(2026, 6, 15, 15, 30),
    );

    final guardado = await guardarReporte(reporte);

    expect(guardado, isTrue);
    expect(
      web.document.querySelector('a[download="reporte-prueba-20260615.csv"]'),
      isNull,
    );
  });

  test('un reporte vacío no descarga nada', () async {
    final reporte = ExportadorDeReportes.csv<String>(
      titulo: 'prueba',
      nombreBase: 'reporte-prueba',
      columnas: [ColumnaDeReporte('dato', (d) => d)],
      filas: const [],
      generadoEn: DateTime.utc(2026, 6, 15, 15, 30),
    );

    expect(await guardarReporte(reporte), isFalse);
  });
}

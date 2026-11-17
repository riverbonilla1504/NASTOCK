// Prueba del exportador copiado de la v2 (`test/report_exporter_test.dart` de
// `ritech-sas-inversiones`), adaptada a columnas genéricas y al formato de la
// app (HU-117).
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/features/reportes/data/exportador_de_reportes.dart';

typedef _Inversion = ({
  String id,
  DateTime fecha,
  double monto,
  double rendimiento,
  double valorActual,
});

_Inversion _inversion({
  String id = 'INV-0001',
  double monto = 1000,
  double rendimiento = 20,
}) => (
  id: id,
  fecha: DateTime.utc(2026, 6, 1, 17),
  monto: monto,
  rendimiento: rendimiento,
  valorActual: monto + monto * rendimiento / 100,
);

final _columnas = <ColumnaDeReporte<_Inversion>>[
  ColumnaDeReporte('id', (i) => i.id),
  ColumnaDeReporte('fecha', (i) => i.fecha, formato: FormatoDeCelda.fecha),
  ColumnaDeReporte('monto', (i) => i.monto, formato: FormatoDeCelda.dinero),
  ColumnaDeReporte(
    'rendimiento',
    (i) => i.rendimiento,
    formato: FormatoDeCelda.porcentaje,
  ),
  ColumnaDeReporte(
    'valor_actual',
    (i) => i.valorActual,
    formato: FormatoDeCelda.dinero,
  ),
];

List<TotalDeReporte> _totales(List<_Inversion> filas) {
  final invertido = filas.fold<double>(0, (s, i) => s + i.monto);
  final actual = filas.fold<double>(0, (s, i) => s + i.valorActual);
  return [
    TotalDeReporte('Total invertido', invertido),
    TotalDeReporte('Valor actual', actual),
    TotalDeReporte('Resultado', actual - invertido),
  ];
}

ResultadoDeReporte _exportar(
  List<_Inversion> filas, {
  DateTime? generadoEn,
  DateTime? desde,
  DateTime? hasta,
}) => ExportadorDeReportes.csv<_Inversion>(
  titulo: 'inversiones',
  nombreBase: 'reporte-inversiones',
  columnas: _columnas,
  filas: filas,
  // 10:30 en Bogotá (UTC−5).
  generadoEn: generadoEn ?? DateTime.utc(2026, 6, 15, 15, 30),
  desde: desde,
  hasta: hasta,
  totales: _totales(filas),
);

void main() {
  group('HU-117 · exportador de la v2 (prueba copiada)', () {
    test('el CSV trae encabezado, filas y totales', () {
      final resultado = _exportar([_inversion()]);

      expect(resultado.exito, isTrue);
      expect(resultado.nombreDeArchivo, endsWith('.csv'));
      expect(
        resultado.contenido,
        contains('"id","fecha","monto","rendimiento","valor_actual"'),
      );
      expect(resultado.contenido, contains('"INV-0001"'));
      expect(resultado.contenido, contains('"Total invertido","USD 1.000,00"'));
      expect(resultado.contenido, contains('"Valor actual","USD 1.200,00"'));
      expect(resultado.contenido, contains('"Resultado","USD 200,00"'));
    });

    test('incluye periodo y fecha de generación', () {
      final resultado = _exportar(
        [_inversion()],
        desde: DateTime(2026, 1, 1),
        hasta: DateTime(2026, 6, 30),
      );

      expect(
        resultado.contenido,
        contains('"Periodo","01/01/2026 a 30/06/2026"'),
      );
      expect(resultado.contenido, contains('"Generado","15/06/2026 10:30"'));
    });

    test('sin rango, el periodo es todo el histórico', () {
      final resultado = _exportar([_inversion()]);

      expect(resultado.contenido, contains('"Periodo","Todo el histórico"'));
    });

    test('sin datos avisa y no genera archivo vacío', () {
      final resultado = _exportar(const []);

      expect(resultado.exito, isFalse);
      expect(resultado.contenido, isNull);
      expect(resultado.nombreDeArchivo, isNull);
      expect(resultado.mensaje, contains('No hay datos'));
    });

    test('respeta los filtros: solo exporta lo que recibe', () {
      final resultado = _exportar([
        _inversion(id: 'INV-0001', monto: 500),
        _inversion(id: 'INV-0002', monto: 1500),
      ]);

      expect(resultado.contenido, contains('"Total invertido","USD 2.000,00"'));
      expect(resultado.contenido, contains('"INV-0001"'));
      expect(resultado.contenido, contains('"INV-0002"'));
      expect(resultado.contenido, isNot(contains('INV-0003')));
    });
  });

  group('HU-117 · CA-2 · formato de la app', () {
    test('cada fila sale con montos, porcentajes y fechas de la app', () {
      final resultado = _exportar([_inversion(monto: 1234.5)]);

      // El `+` del porcentaje lleva el apóstrofo de `celdaCsv`: al inicio de
      // una celda, una hoja de cálculo lo tomaría como fórmula.
      expect(
        resultado.contenido,
        contains(
          '"INV-0001","01/06/2026","USD 1.234,50","\'+20,00 %","USD 1.481,40"',
        ),
      );
    });

    test('las fechas y horas salen en hora de Bogotá', () {
      final columnas = [
        ColumnaDeReporte<DateTime>(
          'momento',
          (m) => m,
          formato: FormatoDeCelda.fechaHora,
        ),
        ColumnaDeReporte<DateTime>(
          'dia',
          (m) => m,
          formato: FormatoDeCelda.fecha,
        ),
      ];
      final resultado = ExportadorDeReportes.csv<DateTime>(
        titulo: 'momentos',
        nombreBase: 'momentos',
        columnas: columnas,
        // 01:00 UTC del 2 de junio = 20:00 del 1 de junio en Bogotá.
        filas: [DateTime.utc(2026, 6, 2, 1)],
        generadoEn: DateTime.utc(2026, 6, 2, 1),
      );

      expect(resultado.contenido, contains('"01/06/2026 20:00","01/06/2026"'));
    });

    test('un monto negativo no se toma como fórmula al abrirlo', () {
      final resultado = _exportar([_inversion(rendimiento: -10)]);

      expect(resultado.contenido, contains('"\'-10,00 %"'));
      expect(resultado.contenido, contains('"Resultado","\'-USD 100,00"'));
    });

    test('el texto con comas, comillas o fórmulas queda en su celda', () {
      final resultado = _exportar([_inversion(id: '=HYPERLINK("x"), sí')]);

      expect(resultado.contenido, contains('"\'=HYPERLINK(""x""), sí"'));
    });

    test('una celda nula queda vacía', () {
      final resultado = ExportadorDeReportes.csv<String?>(
        titulo: 'vacíos',
        nombreBase: 'vacios',
        columnas: [
          ColumnaDeReporte('nota', (n) => n),
          ColumnaDeReporte(
            'monto',
            (_) => null,
            formato: FormatoDeCelda.dinero,
          ),
        ],
        filas: const [null],
        generadoEn: DateTime.utc(2026, 6, 15, 15, 30),
      );

      expect(resultado.contenido, contains('\r\n"",""\r\n'));
    });

    test('empieza con BOM y usa CRLF, como la bitácora', () {
      final contenido = _exportar([_inversion()]).contenido!;

      expect(
        contenido,
        startsWith('﻿"Reporte de inversiones · RiTech SAS"\r\n'),
      );
      expect(contenido.replaceAll('\r\n', ''), isNot(contains('\n')));
      expect(contenido, endsWith('\r\n'));
    });

    test('el nombre lleva la fecha de Bogotá', () {
      // 03:00 UTC del 16 de junio = 22:00 del 15 de junio en Bogotá.
      final resultado = _exportar([
        _inversion(),
      ], generadoEn: DateTime.utc(2026, 6, 16, 3));

      expect(resultado.nombreDeArchivo, 'reporte-inversiones-20260615.csv');
    });
  });
}

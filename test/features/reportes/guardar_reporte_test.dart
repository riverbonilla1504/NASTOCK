// HU-117 · CA-3 en Android: `guardarReporte` usa el canal nativo que abre el
// selector de archivos (`MainActivity.kt`, el mismo de la bitácora).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/features/reportes/data/exportador_de_reportes.dart';

ResultadoDeReporte _reporte(List<String> filas) =>
    ExportadorDeReportes.csv<String>(
      titulo: 'prueba',
      nombreBase: 'reporte-prueba',
      columnas: [ColumnaDeReporte('dato', (d) => d)],
      filas: filas,
      generadoEn: DateTime.utc(2026, 6, 15, 15, 30),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('inversiones/exportacion');
  final mensajero =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final llamadas = <MethodCall>[];
  var respuesta = true;

  setUp(() {
    llamadas.clear();
    respuesta = true;
    mensajero.setMockMethodCallHandler(canal, (llamada) async {
      llamadas.add(llamada);
      return respuesta;
    });
  });
  tearDown(() => mensajero.setMockMethodCallHandler(canal, null));

  test('envía el nombre y el contenido del reporte al selector', () async {
    final reporte = _reporte(['a']);

    final guardado = await guardarReporte(reporte);

    expect(guardado, isTrue);
    expect(llamadas, hasLength(1));
    expect(llamadas.single.method, 'guardarCsv');
    // El decodificador UTF-8 de Dart quita el BOM inicial al leer el mensaje
    // del canal simulado; en Android lo recibe Kotlin, que lo conserva.
    expect(llamadas.single.arguments, {
      'nombre': 'reporte-prueba-20260615.csv',
      'contenido': reporte.contenido!.replaceFirst('﻿', ''),
    });
    expect(reporte.contenido, startsWith('﻿'));
  });

  test('si la persona cancela el selector, devuelve false', () async {
    respuesta = false;

    expect(await guardarReporte(_reporte(['a'])), isFalse);
  });

  test('un reporte vacío no abre el selector', () async {
    expect(await guardarReporte(_reporte(const [])), isFalse);
    expect(llamadas, isEmpty);
  });

  test('acepta otra forma de guardar', () async {
    String? nombre;
    final guardado = await guardarReporte(
      _reporte(['a']),
      guardar: (n, _) async {
        nombre = n;
        return true;
      },
    );

    expect(guardado, isTrue);
    expect(nombre, 'reporte-prueba-20260615.csv');
    expect(llamadas, isEmpty);
  });
}

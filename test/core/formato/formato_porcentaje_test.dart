import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/formato/formato_porcentaje.dart';

void main() {
  group('formatearPorcentaje', () {
    test('lleva signo, coma decimal y espacio antes de %', () {
      expect(formatearPorcentaje(1.24), '+1,24 %');
      expect(formatearPorcentaje(-0.82), '-0,82 %');
      expect(formatearPorcentaje(2.475), '+2,48 %');
    });

    test('un valor que redondea a cero no lleva signo', () {
      expect(formatearPorcentaje(0), '0,00 %');
      expect(formatearPorcentaje(-0.001), '0,00 %');
    });

    test('separa los miles con punto', () {
      expect(formatearPorcentaje(1234.5), '+1.234,50 %');
    });

    test('rechaza valores no finitos', () {
      expect(() => formatearPorcentaje(double.nan), throwsArgumentError);
      expect(() => formatearPorcentaje(double.infinity), throwsArgumentError);
    });
  });

  group('formatearAntiguedad', () {
    test('segundos, minutos, horas y días, truncando', () {
      expect(formatearAntiguedad(const Duration(seconds: 8)), '8 s');
      expect(formatearAntiguedad(const Duration(seconds: 119)), '1 min');
      expect(formatearAntiguedad(const Duration(minutes: 75)), '1 h');
      expect(formatearAntiguedad(const Duration(hours: 50)), '2 d');
    });

    test('una duración negativa cuenta como cero', () {
      expect(formatearAntiguedad(const Duration(seconds: -3)), '0 s');
    });
  });
}

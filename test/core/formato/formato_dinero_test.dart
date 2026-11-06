import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/formato/formato_dinero.dart';

void main() {
  group('formatearUsd', () {
    test('siempre lleva USD y dos decimales', () {
      expect(formatearUsd(0), 'USD 0,00');
      expect(formatearUsd(5), 'USD 5,00');
      expect(formatearUsd(400), 'USD 400,00');
      expect(formatearUsd(110.5), 'USD 110,50');
      expect(formatearUsd(1000.03), 'USD 1.000,03');
    });

    test(
      'usa punto para miles y coma para decimales, como la documentación',
      () {
        expect(formatearUsd(999), 'USD 999,00');
        expect(formatearUsd(1000), 'USD 1.000,00');
        expect(formatearUsd(10000), 'USD 10.000,00');
        expect(formatearUsd(100000), 'USD 100.000,00');
        expect(formatearUsd(1234567.89), 'USD 1.234.567,89');
        // Máximo de numeric(14,2): 12 enteros y 2 decimales.
        expect(formatearUsd(999999999999.99), 'USD 999.999.999.999,99');
      },
    );

    test('redondea a dos decimales', () {
      expect(formatearUsd(2.5), 'USD 2,50');
      expect(formatearUsd(0.126), 'USD 0,13');
      expect(formatearUsd(9.999), 'USD 10,00');
    });

    test('el signo de un monto negativo va delante', () {
      expect(formatearUsd(-5), '-USD 5,00');
      expect(formatearUsd(-1234.5), '-USD 1.234,50');
    });

    test('lo que redondea a cero no lleva signo', () {
      expect(formatearUsd(-0.001), 'USD 0,00');
      expect(formatearUsd(-0.0), 'USD 0,00');
    });

    test('un número que no es finito se rechaza', () {
      expect(() => formatearUsd(double.nan), throwsArgumentError);
      expect(() => formatearUsd(double.infinity), throwsArgumentError);
    });
  });
}

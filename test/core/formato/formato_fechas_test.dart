import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/formato/formato_fechas.dart';

void main() {
  group('hora de Bogotá a partir de UTC', () {
    test('Bogotá está 5 horas por detrás de UTC', () {
      final utc = DateTime.utc(2026, 11, 5, 14, 30);
      expect(formatearHora(utc), '09:30');
      expect(formatearFecha(utc), '05/11/2026');
      expect(formatearFechaHora(utc), '05/11/2026 09:30');
    });

    test('sin horario de verano: mismo desfase en julio y en enero', () {
      expect(formatearHora(DateTime.utc(2026, 7, 15, 13, 30)), '08:30');
      expect(formatearHora(DateTime.utc(2026, 1, 15, 13, 30)), '08:30');
    });

    test('apertura y cierre del mercado según RN-42', () {
      // Verano de EE. UU.: 9:30–16:00 en Nueva York = 8:30–15:00 en Bogotá.
      expect(formatearHora(DateTime.utc(2026, 7, 15, 13, 30)), '08:30');
      expect(formatearHora(DateTime.utc(2026, 7, 15, 20, 0)), '15:00');
      // Resto del año: 9:30–16:00 en Bogotá.
      expect(formatearHora(DateTime.utc(2026, 12, 15, 14, 30)), '09:30');
      expect(formatearHora(DateTime.utc(2026, 12, 15, 21, 0)), '16:00');
    });

    test('cruza la medianoche hacia el día anterior', () {
      final utc = DateTime.utc(2026, 1, 1, 3, 15);
      expect(formatearFechaHora(utc), '31/12/2025 22:15');
    });

    test('rellena con ceros', () {
      expect(
        formatearFechaHora(DateTime.utc(2026, 3, 4, 10, 5)),
        '04/03/2026 05:05',
      );
    });

    test(
      'un instante no UTC se convierte antes: da lo mismo en cualquier zona',
      () {
        final utc = DateTime.utc(2026, 11, 5, 14, 30);
        final local = utc.toLocal();
        expect(formatearHora(local), formatearHora(utc));
        expect(formatearFechaHora(local), formatearFechaHora(utc));
      },
    );
  });
}

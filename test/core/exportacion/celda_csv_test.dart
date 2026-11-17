import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/exportacion/celda_csv.dart';

void main() {
  group('celdaCsv', () {
    test('pone el texto entre comillas', () {
      expect(celdaCsv('cupo.asignado'), '"cupo.asignado"');
    });

    test('una celda con coma queda entera', () {
      expect(celdaCsv('USD 1.234,50'), '"USD 1.234,50"');
    });

    test('duplica las comillas internas', () {
      expect(celdaCsv('dijo "hola"'), '"dijo ""hola"""');
    });

    test('un dato nulo es una celda vacía', () {
      expect(celdaCsv(null), '""');
    });

    test('neutraliza lo que parece una fórmula', () {
      expect(celdaCsv('=1+1'), '"\'=1+1"');
      expect(celdaCsv('+57'), '"\'+57"');
      expect(celdaCsv('-USD 5,00'), '"\'-USD 5,00"');
      expect(celdaCsv('@SUMA'), '"\'@SUMA"');
      expect(celdaCsv('  =A1'), '"\'  =A1"');
      expect(celdaCsv('\tA1'), '"\'\tA1"');
    });

    test('no toca un signo que no está al inicio', () {
      expect(celdaCsv('a=b'), '"a=b"');
    });
  });
}

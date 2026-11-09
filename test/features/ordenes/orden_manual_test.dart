import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/features/ordenes/domain/orden_manual.dart';

void main() {
  test('el id de la orden es un uuid v4 y cambia en cada formulario', () {
    final a = nuevoIdDeOrden(Random(1));
    expect(
      a,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(nuevoIdDeOrden(), isNot(nuevoIdDeOrden()));
  });

  test('D-63: la cantidad es un entero de 1 en adelante', () {
    expect(cantidadEntera('4'), 4);
    expect(cantidadEntera(' 12 '), 12);
    expect(cantidadEntera('1.5'), isNull);
    expect(cantidadEntera('0'), isNull);
    expect(cantidadEntera(''), isNull);
    expect(cantidadEntera('-3'), isNull);
  });

  test('los porcentajes aceptan coma o punto', () {
    expect(porcentaje('8,5'), 8.5);
    expect(porcentaje('15'), 15);
    expect(porcentaje('x'), isNull);
  });

  test('el monto estimado es cantidad por precio', () {
    expect(montoEstimado(4, 100.5), 402);
  });
}

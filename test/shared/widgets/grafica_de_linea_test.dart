import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/shared/widgets/grafica_de_linea.dart';

import 'montar.dart';

void main() {
  testWidgets('se lee con su descripción', (tester) async {
    final semantica = tester.ensureSemantics();
    await montar(
      tester,
      const GraficaDeLinea(
        serie: [95.78, 96.4, 97.1, 98.14],
        referencia: [506.1, 507.2, 509.9, 512.36],
        ahora: 0.35,
        descripcion: 'QLD hoy: sube de 95,78 a 98,14',
      ),
    );

    expect(
      find.bySemanticsLabel('QLD hoy: sube de 95,78 a 98,14'),
      findsOneWidget,
    );
    semantica.dispose();
  });

  testWidgets('dibuja sin fallar con series vacías, de un valor o planas', (
    tester,
  ) async {
    await montar(
      tester,
      const Column(
        children: [
          GraficaDeLinea(serie: [], descripcion: 'vacía'),
          GraficaDeLinea(serie: [98.14], descripcion: 'un valor'),
          GraficaDeLinea(serie: [5, 5, 5], ahora: 1, descripcion: 'plana'),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(GraficaDeLinea), findsNWidgets(3));
  });

  testWidgets('ocupa el alto pedido', (tester) async {
    await montar(
      tester,
      const GraficaDeLinea(serie: [1, 2, 3], alto: 140, descripcion: 'g'),
    );

    expect(tester.getSize(find.byType(GraficaDeLinea)).height, 140);
  });
}

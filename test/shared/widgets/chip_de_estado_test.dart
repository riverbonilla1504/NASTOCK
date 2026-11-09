import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/shared/widgets/chip_de_estado.dart';
import 'package:inversiones/shared/widgets/forma_de_linea.dart';

import 'montar.dart';

void main() {
  testWidgets('cada estado tiene su rótulo y su forma de línea', (
    tester,
  ) async {
    await montar(
      tester,
      const Wrap(
        children: [
          ChipDeEstado.enVivo(),
          ChipDeEstado.pendiente(),
          ChipDeEstado.desactualizado(),
          ChipDeEstado.deshabilitado(),
        ],
      ),
    );

    expect(find.text('En vivo'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Desactualizado'), findsOneWidget);
    expect(find.text('Deshabilitado'), findsOneWidget);
    final formas = tester
        .widgetList<TrazoDeLinea>(find.byType(TrazoDeLinea))
        .map((t) => t.forma)
        .toList();
    expect(formas, [
      FormaDeLinea.solida,
      FormaDeLinea.discontinua,
      FormaDeLinea.punteada,
      FormaDeLinea.solida,
    ]);
  });

  testWidgets('deshabilitado se tacha y se lee como no disponible', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montar(tester, const ChipDeEstado.deshabilitado());

    final texto = tester.widget<Text>(find.text('Deshabilitado'));
    expect(texto.style!.decoration, TextDecoration.lineThrough);
    expect(
      find.bySemanticsLabel('Deshabilitado, no disponible'),
      findsOneWidget,
    );
    semantica.dispose();
  });
}

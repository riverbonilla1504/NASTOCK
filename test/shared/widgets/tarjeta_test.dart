import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/shared/widgets/tarjeta.dart';

import 'montar.dart';

BoxDecoration _decoracion(WidgetTester tester) {
  final caja = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(Tarjeta),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return caja.decoration as BoxDecoration;
}

void main() {
  testWidgets('muestra su contenido y responde al toque', (tester) async {
    var toques = 0;
    await montar(
      tester,
      Tarjeta(alTocar: () => toques++, child: const Text('Cupo')),
    );

    await tester.tap(find.text('Cupo'));
    expect(toques, 1);
  });

  testWidgets('lleva la sombra suave del tema', (tester) async {
    await montar(tester, const Tarjeta(child: Text('Cupo')));

    expect(_decoracion(tester).boxShadow, ProfundidadTema.claro.sombraTarjeta);
  });

  testWidgets('sin elevación no lleva sombra', (tester) async {
    await montar(tester, const Tarjeta(elevada: false, child: Text('Cupo')));

    expect(_decoracion(tester).boxShadow, isNull);
  });
}

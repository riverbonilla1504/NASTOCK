import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/shared/widgets/botones.dart';

import 'montar.dart';

void main() {
  testWidgets('el primario muestra su texto y responde al toque', (
    tester,
  ) async {
    var toques = 0;
    await montar(
      tester,
      BotonPrimario(
        texto: 'Nueva orden',
        icono: Icons.add,
        alPresionar: () => toques++,
      ),
    );

    await tester.tap(find.text('Nueva orden'));
    expect(toques, 1);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('enviando dice "Procesando…" y no responde (08 §9.3)', (
    tester,
  ) async {
    var toques = 0;
    await montar(
      tester,
      BotonPrimario(
        texto: 'Comprar',
        enviando: true,
        alPresionar: () => toques++,
      ),
    );

    expect(find.text(textoProcesando), findsOneWidget);
    expect(find.text('Comprar'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(toques, 0);
    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNull);
  });

  testWidgets('sin acción el botón queda deshabilitado', (tester) async {
    await montar(
      tester,
      const Column(
        children: [
          BotonPrimario(texto: 'Comprar', alPresionar: null),
          BotonSecundario(texto: 'Vender', alPresionar: null),
          BotonTexto(texto: 'Ver detalle', alPresionar: null),
        ],
      ),
    );

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
      isFalse,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).enabled,
      isFalse,
    );
    expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isFalse);
  });

  testWidgets('el secundario también muestra el estado de envío', (
    tester,
  ) async {
    await montar(
      tester,
      BotonSecundario(texto: 'Cancelar', enviando: true, alPresionar: () {}),
    );

    expect(find.text(textoProcesando), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).enabled,
      isFalse,
    );
  });

  testWidgets('los botones miden al menos 48 dp de alto', (tester) async {
    await montar(
      tester,
      BotonSecundario(texto: 'Cancelar', alPresionar: () {}),
    );

    expect(
      tester.getSize(find.byType(OutlinedButton)).height,
      greaterThanOrEqualTo(48),
    );
  });
}

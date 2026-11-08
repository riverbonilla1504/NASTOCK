import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/shared/widgets/campo.dart';

import 'montar.dart';

void main() {
  testWidgets('muestra la etiqueta y la ayuda', (tester) async {
    await montar(
      tester,
      const Campo(
        etiqueta: 'Monto (USD)',
        ayuda: 'Disponible en tu cupo: USD 1.240,00',
      ),
    );

    expect(find.text('Monto (USD)'), findsOneWidget);
    expect(find.text('Disponible en tu cupo: USD 1.240,00'), findsOneWidget);
  });

  testWidgets('con error muestra el mensaje con su marca y oculta la ayuda', (
    tester,
  ) async {
    await montar(
      tester,
      const Campo(
        etiqueta: 'Pérdida diaria máxima (%)',
        ayuda: 'Entre 1 y 10',
        error: 'El valor está fuera del rango permitido (mín.–máx.).',
      ),
    );

    expect(
      find.text('El valor está fuera del rango permitido (mín.–máx.).'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Entre 1 y 10'), findsNothing);
  });

  testWidgets('avisa cada cambio del texto', (tester) async {
    String? ultimo;
    await montar(
      tester,
      Campo(etiqueta: 'Monto (USD)', alCambiar: (v) => ultimo = v),
    );

    await tester.enterText(find.byType(TextField), '250');
    expect(ultimo, '250');
  });

  testWidgets('en solo lectura no deja escribir y responde al toque', (
    tester,
  ) async {
    var toques = 0;
    await montar(
      tester,
      Campo(etiqueta: 'Fecha', soloLectura: true, alTocar: () => toques++),
    );

    await tester.tap(find.byType(TextField));
    expect(toques, 1);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
  });

  testWidgets('oculto esconde lo escrito y apaga las sugerencias', (
    tester,
  ) async {
    await montar(tester, const Campo(etiqueta: 'Contraseña', oculto: true));

    final campo = tester.widget<TextField>(find.byType(TextField));
    expect(campo.obscureText, isTrue);
    expect(campo.enableSuggestions, isFalse);
    expect(campo.autocorrect, isFalse);
  });

  testWidgets('por omisión muestra lo escrito', (tester) async {
    await montar(tester, const Campo(etiqueta: 'Correo'));

    final campo = tester.widget<TextField>(find.byType(TextField));
    expect(campo.obscureText, isFalse);
    expect(campo.enableSuggestions, isTrue);
  });
}

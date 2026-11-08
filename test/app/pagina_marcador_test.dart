import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/pagina_marcador.dart';
import 'package:inversiones/app/tema.dart';

Future<void> _abrir(
  WidgetTester tester, {
  bool oscuro = false,
  double textoEscala = 1,
  double ancho = 360,
}) async {
  tester.view.physicalSize = Size(ancho, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: oscuro ? crearTemaOscuro() : crearTema(),
      builder: (context, hijo) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textoEscala)),
        child: hijo!,
      ),
      home: const PaginaMarcador(etiqueta: 'Oportunidades'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el nombre de la sección y que aún no está disponible', (
    tester,
  ) async {
    await _abrir(tester);

    expect(find.text('Oportunidades'), findsOneWidget);
    expect(find.text('Aún no está disponible'), findsOneWidget);
    expect(
      find.text('Esta sección se habilita en una próxima entrega.'),
      findsOneWidget,
    );
  });

  testWidgets('no ofrece ninguna acción: el menú sigue a la vista', (
    tester,
  ) async {
    await _abrir(tester);

    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  for (final oscuro in [false, true]) {
    for (final ancho in [360.0, 1280.0]) {
      testWidgets(
        '${oscuro ? 'oscuro' : 'claro'} a ${ancho.toInt()} dp con el texto al doble, sin desbordar',
        (tester) async {
          await _abrir(tester, oscuro: oscuro, textoEscala: 2, ancho: ancho);

          expect(find.text('Aún no está disponible'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

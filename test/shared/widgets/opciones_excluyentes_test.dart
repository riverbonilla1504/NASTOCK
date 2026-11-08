import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/shared/widgets/opciones_excluyentes.dart';

import 'montar.dart';

const _roles = [
  OpcionExcluyente(valor: 'usuario', etiqueta: 'Usuario'),
  OpcionExcluyente(valor: 'analista', etiqueta: 'Analista'),
  OpcionExcluyente(valor: 'administrador', etiqueta: 'Administrador'),
];

void main() {
  testWidgets('muestra el rótulo, la ayuda y todas las opciones a la vez', (
    tester,
  ) async {
    await montar(
      tester,
      OpcionesExcluyentes<String>(
        etiqueta: 'Rol',
        ayuda: 'Define qué verá la persona.',
        opciones: _roles,
        valor: 'usuario',
        alElegir: (_) {},
      ),
    );

    expect(find.text('Rol'), findsOneWidget);
    expect(find.text('Define qué verá la persona.'), findsOneWidget);
    for (final opcion in _roles) {
      expect(find.text(opcion.etiqueta), findsOneWidget);
    }
  });

  testWidgets('la elegida lleva un visto y las demás no', (tester) async {
    await montar(
      tester,
      OpcionesExcluyentes<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'analista',
        alElegir: (_) {},
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(InkWell).at(1),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sin valor elegido ninguna lleva visto', (tester) async {
    await montar(
      tester,
      OpcionesExcluyentes<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: null,
        alElegir: (_) {},
      ),
    );

    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('avisa el valor de la opción tocada', (tester) async {
    String? elegido;
    await montar(
      tester,
      OpcionesExcluyentes<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'usuario',
        alElegir: (v) => elegido = v,
      ),
    );

    await tester.tap(find.text('Administrador'));
    expect(elegido, 'administrador');
  });

  testWidgets('deshabilitada no responde al toque', (tester) async {
    String? elegido;
    await montar(
      tester,
      OpcionesExcluyentes<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'usuario',
        alElegir: null,
      ),
    );

    await tester.tap(find.text('Analista'), warnIfMissed: false);
    expect(elegido, isNull);
  });

  testWidgets('cada opción mide al menos 48 dp de alto', (tester) async {
    await montar(
      tester,
      OpcionesExcluyentes<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'usuario',
        alElegir: (_) {},
      ),
    );

    for (final opcion in _roles) {
      final caja = tester.getSize(
        find
            .ancestor(
              of: find.text(opcion.etiqueta),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(caja.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('se lee como un grupo de opciones excluyentes', (tester) async {
    final semantica = tester.ensureSemantics();
    await montar(
      tester,
      OpcionesExcluyentes<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'analista',
        alElegir: (_) {},
      ),
    );

    expect(
      tester.getSemantics(find.text('Analista')),
      matchesSemantics(
        label: 'Analista',
        isButton: true,
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
      ),
    );
    semantica.dispose();
  });

  testWidgets('se dibuja igual en oscuro', (tester) async {
    await montar(
      tester,
      OpcionesExcluyentes<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'usuario',
        alElegir: (_) {},
      ),
      oscuro: true,
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con texto grande las opciones pasan a la línea siguiente', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await montar(
      tester,
      OpcionesExcluyentes<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'usuario',
        alElegir: (_) {},
      ),
    );

    expect(tester.takeException(), isNull);
    final alto = tester.getSize(find.byType(Wrap)).height;
    expect(alto, greaterThan(48 * 2));
  });
}

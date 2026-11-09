import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/shared/widgets/lista_desplegable.dart';

import 'montar.dart';

const _roles = [
  OpcionExcluyente(valor: 'usuario', etiqueta: 'Usuario'),
  OpcionExcluyente(valor: 'analista', etiqueta: 'Analista'),
  OpcionExcluyente(valor: 'administrador', etiqueta: 'Administrador'),
];

void main() {
  testWidgets('cerrada muestra el rótulo, la ayuda y solo la opción elegida', (
    tester,
  ) async {
    await montar(
      tester,
      ListaDesplegable<String>(
        etiqueta: 'Rol',
        ayuda: 'Define qué verá la persona.',
        opciones: _roles,
        valor: 'analista',
        alElegir: (_) {},
      ),
    );

    expect(find.text('Rol'), findsOneWidget);
    expect(find.text('Define qué verá la persona.'), findsOneWidget);
    expect(find.text('Analista'), findsOneWidget);
    expect(find.text('Usuario'), findsNothing);
    expect(find.text('Administrador'), findsNothing);
  });

  testWidgets('al tocarla abre todas las opciones y marca la elegida', (
    tester,
  ) async {
    await montar(
      tester,
      ListaDesplegable<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'analista',
        alElegir: (_) {},
      ),
    );

    await tester.tap(find.text('Analista'));
    await tester.pumpAndSettle();

    for (final opcion in _roles) {
      expect(find.text(opcion.etiqueta), findsWidgets);
    }
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('elegir una opción avisa su valor y cierra la lista', (
    tester,
  ) async {
    String? elegida;
    await montar(
      tester,
      ListaDesplegable<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'usuario',
        alElegir: (v) => elegida = v,
      ),
    );

    await tester.tap(find.text('Usuario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Administrador').last);
    await tester.pumpAndSettle();

    expect(elegida, 'administrador');
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('una opción con valor nulo (Todos) se elige y se muestra', (
    tester,
  ) async {
    String? elegida = 'x';
    var avisos = 0;
    await montar(
      tester,
      ListaDesplegable<String?>(
        etiqueta: 'Lista blanca',
        opciones: const [
          OpcionExcluyente(valor: null, etiqueta: 'Todos'),
          OpcionExcluyente(valor: 'usuarios', etiqueta: 'Usuarios'),
        ],
        valor: 'usuarios',
        alElegir: (v) {
          elegida = v;
          avisos++;
        },
      ),
    );

    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos').last);
    await tester.pumpAndSettle();

    expect(avisos, 1);
    expect(elegida, isNull);
  });

  testWidgets('con el valor nulo elegido la lista cerrada dice Todos', (
    tester,
  ) async {
    await montar(
      tester,
      ListaDesplegable<String?>(
        etiqueta: 'Lista blanca',
        opciones: const [
          OpcionExcluyente(valor: null, etiqueta: 'Todos'),
          OpcionExcluyente(valor: 'usuarios', etiqueta: 'Usuarios'),
        ],
        valor: null,
        alElegir: (_) {},
      ),
    );

    expect(find.text('Todos'), findsOneWidget);
  });

  testWidgets('sin alElegir queda deshabilitada y no abre', (tester) async {
    await montar(
      tester,
      const ListaDesplegable<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'usuario',
        alElegir: null,
      ),
    );

    await tester.tap(find.text('Usuario'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Analista'), findsNothing);
  });

  testWidgets('ocupa todo el ancho y mide al menos 48 dp a 360 dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await montar(
      tester,
      ListaDesplegable<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'usuario',
        alElegir: (_) {},
      ),
    );

    final caja = tester.getRect(find.byType(DropdownButton<int>));
    expect(caja.width, 360 - 32);
    expect(caja.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('no desborda con el texto al doble a 360 dp, en oscuro', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await montar(
      tester,
      ListaDesplegable<String>(
        etiqueta: 'Rol',
        opciones: _roles,
        valor: 'administrador',
        alElegir: (_) {},
      ),
      oscuro: true,
    );

    await tester.tap(find.text('Administrador'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';

/// Monta [widget] con el tema del sistema, claro u oscuro.
Future<void> montar(WidgetTester tester, Widget widget, {bool oscuro = false}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: oscuro ? crearTemaOscuro() : crearTema(),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: widget,
        ),
      ),
    ),
  );
}

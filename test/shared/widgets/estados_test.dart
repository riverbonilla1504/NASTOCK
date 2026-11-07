import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/errores/traduccion_de_errores.dart';
import 'package:inversiones/shared/widgets/botones.dart';
import 'package:inversiones/shared/widgets/estados.dart';

import 'montar.dart';

void main() {
  testWidgets('vacío muestra título, mensaje y acción', (tester) async {
    await montar(
      tester,
      EstadoVacio(
        titulo: 'Aún no tienes posiciones',
        mensaje: 'Cuando compres, aparecen aquí.',
        accion: BotonSecundario(texto: 'Nueva orden', alPresionar: () {}),
      ),
    );

    expect(find.text('Aún no tienes posiciones'), findsOneWidget);
    expect(find.text('Cuando compres, aparecen aquí.'), findsOneWidget);
    expect(find.text('Nueva orden'), findsOneWidget);
  });

  testWidgets('cargando son líneas con brillo, sin rueda de carga', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montar(tester, const EstadoCargando(lineas: 4));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
    semantica.dispose();
  });

  testWidgets('con "quitar animaciones" las líneas quedan quietas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: crearTema(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: EstadoCargando()),
        ),
      ),
    );

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('error muestra el texto traducido y permite reintentar', (
    tester,
  ) async {
    var reintentos = 0;
    await montar(
      tester,
      EstadoDeError(
        error: const ErrorDeNegocio('INTEGRACION_CAIDA'),
        alReintentar: () => reintentos++,
      ),
    );

    expect(
      find.text('El broker o los datos de mercado no están disponibles.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Reintentar'));
    expect(reintentos, 1);
  });
}

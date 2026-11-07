import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/shared/widgets/barra_de_pestanas.dart';
import 'package:inversiones/shared/widgets/barra_superior.dart';
import 'package:inversiones/shared/widgets/forma_de_linea.dart';
import 'package:inversiones/shared/widgets/franja_de_la_jornada.dart';

import 'montar.dart';

// Viernes 6 de noviembre de 2026: 09:30 a 16:00 en Bogotá (UTC−5).
final _apertura = DateTime.utc(2026, 11, 6, 14, 30);
final _cierre = DateTime.utc(2026, 11, 6, 21);

void main() {
  group('franja de la jornada', () {
    testWidgets('dice la jornada y la hora de ahora en hora de Bogotá', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        FranjaDeLaJornada(
          apertura: _apertura,
          cierre: _cierre,
          ahora: DateTime.utc(2026, 11, 6, 16, 46),
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Jornada de 09:30 a 16:00, hora de Bogotá. Ahora 11:46',
        ),
        findsOneWidget,
      );
      semantica.dispose();
    });

    testWidgets('fuera de la jornada no muestra la hora de ahora', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        FranjaDeLaJornada(
          apertura: _apertura,
          cierre: _cierre,
          ahora: DateTime.utc(2026, 11, 7, 0, 20),
        ),
      );

      expect(
        find.bySemanticsLabel('Jornada de 09:30 a 16:00, hora de Bogotá'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantica.dispose();
    });
  });

  group('barra superior', () {
    testWidgets('lleva el título, el degradado grafito y su contenido', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: crearTema(),
          home: const Scaffold(
            appBar: BarraSuperior(
              titulo: 'Mercado',
              alturaInferior: 40,
              inferior: Text('Cierra en 4 h 14 min'),
            ),
          ),
        ),
      );

      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Cierra en 4 h 14 min'), findsOneWidget);
      final caja = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(BarraSuperior),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (caja.decoration as BoxDecoration).gradient,
        ProfundidadAlmanaque.claro.degradadoGrafito,
      );
      expect(
        const BarraSuperior(titulo: 'x', alturaInferior: 40).preferredSize,
        const Size.fromHeight(kToolbarHeight + 40),
      );
    });
  });

  group('barra de pestañas', () {
    testWidgets('muestra sus destinos sobre un velo con desenfoque', (
      tester,
    ) async {
      final elegidos = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: crearTema(),
          home: Scaffold(
            bottomNavigationBar: BarraDePestanas(
              actual: 0,
              alElegir: elegidos.add,
              pestanas: const [
                Pestana(etiqueta: 'Mercado', icono: Icons.show_chart),
                Pestana(etiqueta: 'Alertas', icono: Icons.notifications_none),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
      await tester.tap(find.text('Alertas'));
      expect(elegidos, [1]);
    });
  });

  testWidgets('cada forma de borde se dibuja sin fallar', (tester) async {
    await montar(
      tester,
      Column(
        children: [
          for (final forma in FormaDeLinea.values)
            BordeConForma(
              forma: forma,
              color: const Color(0xFF18181B),
              child: const SizedBox(width: 120, height: 40),
            ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byType(BordeConForma),
      findsNWidgets(FormaDeLinea.values.length),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    Widget pantalla({Widget? cuerpo}) => MaterialApp(
      theme: crearTema(),
      home: Scaffold(
        appBar: const BarraSuperior(
          titulo: 'Mercado',
          alturaInferior: 40,
          inferior: Text('Cierra en 4 h 14 min'),
        ),
        body:
            cuerpo ??
            ListView(children: [for (var i = 0; i < 40; i++) Text('Fila $i')]),
      ),
    );

    final tema = crearTema().textTheme;

    double tamanoDelTitulo(WidgetTester tester) =>
        tester.widget<Text>(find.text('Mercado')).style!.fontSize!;

    BoxDecoration decoracion(WidgetTester tester) =>
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(BarraSuperior),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;

    testWidgets(
      'en reposo: título grande sobre papel, sin borde, y su contenido',
      (tester) async {
        await tester.pumpWidget(pantalla());

        expect(find.text('Mercado'), findsOneWidget);
        expect(find.text('Cierra en 4 h 14 min'), findsOneWidget);
        expect(tamanoDelTitulo(tester), tema.headlineLarge!.fontSize);
        expect(decoracion(tester).gradient, isNull);
        expect(decoracion(tester).color, ColoresTema.claro.papel);
        expect(decoracion(tester).border, isNull);
        expect(
          const BarraSuperior(titulo: 'x', alturaInferior: 40).preferredSize,
          const Size.fromHeight(
            kToolbarHeight + altoMaximoDelTituloGrande + 40,
          ),
        );
      },
    );

    testWidgets(
      'al desplazar se recoge en barra compacta sin borde, y vuelve arriba',
      (tester) async {
        await tester.pumpWidget(pantalla());
        final altoEnReposo = tester.getSize(find.byType(BarraSuperior)).height;

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        expect(find.text('Mercado'), findsOneWidget);
        expect(tamanoDelTitulo(tester), tema.headlineSmall!.fontSize);
        // Compacta tampoco lleva línea entre el título y el contenido.
        expect(decoracion(tester).border, isNull);
        expect(decoracion(tester).color, ColoresTema.claro.papel);
        expect(
          tester.getSize(find.byType(BarraSuperior)).height,
          lessThan(altoEnReposo),
        );
        // La franja de abajo sigue a la vista.
        expect(find.text('Cierra en 4 h 14 min'), findsOneWidget);

        await tester.drag(find.byType(ListView), const Offset(0, 2000));
        await tester.pumpAndSettle();

        expect(tamanoDelTitulo(tester), tema.headlineLarge!.fontSize);
        expect(decoracion(tester).border, isNull);
        expect(tester.getSize(find.byType(BarraSuperior)).height, altoEnReposo);
      },
    );

    testWidgets('con el texto al 200 % el título grande cabe sin desbordar', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(pantalla());

      expect(tester.takeException(), isNull);
    });

    testWidgets('una lista horizontal no recoge el título', (tester) async {
      await tester.pumpWidget(
        pantalla(
          cuerpo: SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < 40; i++)
                  SizedBox(width: 80, child: Text('C$i')),
              ],
            ),
          ),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(tamanoDelTitulo(tester), tema.headlineLarge!.fontSize);
    });
  });

  group('isla de navegación', () {
    const destinos = [
      Pestana(etiqueta: 'Mercado', icono: Icons.show_chart),
      Pestana(etiqueta: 'Oportunidades', icono: Icons.query_stats),
      Pestana(
        etiqueta: 'Mi cupo',
        icono: Icons.account_balance_wallet_outlined,
      ),
      Pestana(etiqueta: 'Alertas', icono: Icons.notifications_none),
    ];

    Widget isla({
      int actual = 0,
      ValueChanged<int>? alElegir,
      double textoEscala = 1,
      bool sinAnimaciones = false,
    }) {
      return MaterialApp(
        theme: crearTema(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textoEscala),
              disableAnimations: sinAnimaciones,
            ),
            child: Scaffold(
              extendBody: true,
              bottomNavigationBar: BarraDePestanas(
                actual: actual,
                alElegir: alElegir ?? (_) {},
                pestanas: destinos,
              ),
            ),
          ),
        ),
      );
    }

    // Teléfono de 360 × 640 dp.
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
    });
    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    testWidgets('es una cápsula flotante con velo y desenfoque', (
      tester,
    ) async {
      await tester.pumpWidget(isla());

      expect(find.byType(BackdropFilter), findsOneWidget);
      final caja = tester.getRect(find.byType(BackdropFilter));
      expect(caja.left, greaterThanOrEqualTo(16));
      expect(caja.right, lessThanOrEqualTo(360 - 16));
      expect(caja.bottom, lessThanOrEqualTo(640 - 16));
      expect(caja.center.dx, closeTo(180, 0.5));
    });

    testWidgets('solo la pestaña actual muestra su rótulo', (tester) async {
      await tester.pumpWidget(isla(actual: 1));

      expect(find.text('Oportunidades'), findsOneWidget);
      expect(find.text('Mercado'), findsNothing);
      expect(find.text('Mi cupo'), findsNothing);
      expect(find.text('Alertas'), findsNothing);
    });

    testWidgets('todos los destinos conservan su nombre para el lector', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(isla(actual: 2));

      for (final d in destinos) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(d.etiqueta)),
          matchesSemantics(
            label: d.etiqueta,
            isButton: true,
            hasSelectedState: true,
            isSelected: d.etiqueta == 'Mi cupo',
            hasTapAction: true,
            hasEnabledState: false,
          ),
          reason: d.etiqueta,
        );
      }
      semantica.dispose();
    });

    testWidgets('cada destino mide al menos 48 dp', (tester) async {
      await tester.pumpWidget(isla());

      for (final d in destinos) {
        final tamano = tester.getSize(
          find.ancestor(
            of: find.byIcon(d.icono),
            matching: find.byType(InkWell),
          ),
        );
        expect(tamano.width, greaterThanOrEqualTo(48), reason: d.etiqueta);
        expect(tamano.height, greaterThanOrEqualTo(48), reason: d.etiqueta);
      }
    });

    testWidgets('elegir un destino llama a alElegir con su posición', (
      tester,
    ) async {
      final elegidos = <int>[];
      await tester.pumpWidget(isla(alElegir: elegidos.add));

      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.tap(find.byIcon(Icons.query_stats));
      expect(elegidos, [3, 1]);
    });

    testWidgets('el destino enfocado con el teclado se distingue', (
      tester,
    ) async {
      await tester.pumpWidget(isla());

      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final foco = find.byWidgetPredicate(
        (w) =>
            w is AnimatedContainer &&
            w.decoration is ShapeDecoration &&
            ((w.decoration! as ShapeDecoration).shape as StadiumBorder)
                    .side
                    .width ==
                2,
      );
      expect(foco, findsOneWidget);
    });

    testWidgets('anima el cambio de pestaña y no lo hace sin animaciones', (
      tester,
    ) async {
      final ancho = find.byType(BackdropFilter);

      await tester.pumpWidget(isla());
      final antes = tester.getSize(ancho).width;
      await tester.pumpWidget(isla(actual: 1));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Oportunidades'), findsOneWidget);
      await tester.pumpAndSettle();
      // ignore: avoid_print
      print(
        'DESPUES ${tester.getSize(ancho).width} ${tester.getSize(find.text('Oportunidades'))}',
      );
      expect(tester.getSize(ancho).width, isNot(closeTo(antes, 0.01)));

      await tester.pumpWidget(isla(sinAnimaciones: true));
      await tester.pumpWidget(isla(actual: 3, sinAnimaciones: true));
      // Sin animación, el estado final llega en el primer cuadro.
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Alertas'), findsOneWidget);
    });

    for (final escala in [1.0, 1.4, 2.0, 3.0]) {
      testWidgets('a 360 dp con texto ×$escala no se desborda', (tester) async {
        for (var i = 0; i < destinos.length; i++) {
          await tester.pumpWidget(isla(actual: i, textoEscala: escala));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: destinos[i].etiqueta);
          final caja = tester.getRect(find.byType(BackdropFilter));
          expect(caja.left, greaterThanOrEqualTo(16));
          expect(caja.right, lessThanOrEqualTo(360 - 16));
        }
      });
    }
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/shared/widgets/grafica_de_linea.dart';
import 'package:inversiones/shared/widgets/selector_de_rango.dart';
import 'package:inversiones/shared/widgets/tarjeta_de_grafica.dart';

import 'montar.dart';

Widget _tarjeta({
  RangoDeGrafica rango = RangoDeGrafica.dia,
  ValueChanged<RangoDeGrafica>? alElegir,
  VoidCallback? alRefrescar,
  num? valor = 10000,
}) => TarjetaDeGrafica(
  titulo: 'Valor del portafolio',
  valor: valor,
  cambio: 1.25,
  fecha: '08/11/2026 07:00',
  serie: const [9800, 9900, 9850, 10000],
  etiquetasX: const ['7 AM', '10 AM', '1 PM'],
  descripcion: 'El portafolio sube de 9.800 a 10.000',
  rango: rango,
  alElegirRango: alElegir ?? (_) {},
  alRefrescar: alRefrescar,
);

void main() {
  group('SelectorDeRango', () {
    testWidgets('muestra 1D, 1M, 1Y y All, y avisa el rango tocado', (
      tester,
    ) async {
      final elegidos = <RangoDeGrafica>[];
      await montar(
        tester,
        SelectorDeRango(rango: RangoDeGrafica.dia, alElegir: elegidos.add),
      );

      for (final texto in ['1D', '1M', '1Y', 'All']) {
        expect(find.text(texto), findsOneWidget);
      }
      await tester.tap(find.byKey(claveDeRango(RangoDeGrafica.anio)));
      await tester.tap(find.byKey(claveDeRango(RangoDeGrafica.todo)));
      expect(elegidos, [RangoDeGrafica.anio, RangoDeGrafica.todo]);
    });

    testWidgets('cada opción mide al menos 48 dp', (tester) async {
      await montar(
        tester,
        SelectorDeRango(rango: RangoDeGrafica.mes, alElegir: (_) {}),
      );

      for (final r in RangoDeGrafica.values) {
        final tamano = tester.getSize(find.byKey(claveDeRango(r)));
        expect(tamano.width, greaterThanOrEqualTo(48), reason: r.etiqueta);
        expect(tamano.height, greaterThanOrEqualTo(48), reason: r.etiqueta);
      }
    });

    testWidgets('el elegido se dice a un lector de pantalla', (tester) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        SelectorDeRango(rango: RangoDeGrafica.mes, alElegir: (_) {}),
      );

      expect(
        tester.getSemantics(find.byKey(claveDeRango(RangoDeGrafica.mes))),
        matchesSemantics(
          label: 'Un mes',
          isButton: true,
          isSelected: true,
          isEnabled: true,
          hasEnabledState: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(claveDeRango(RangoDeGrafica.dia))),
        matchesSemantics(
          label: 'Un día',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      semantica.dispose();
    });

    testWidgets('sin alElegir queda deshabilitado', (tester) async {
      await montar(
        tester,
        const SelectorDeRango(rango: RangoDeGrafica.dia, alElegir: null),
      );

      final tinta = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(claveDeRango(RangoDeGrafica.mes)),
          matching: find.byType(InkWell),
        ),
      );
      expect(tinta.onTap, isNull);
    });

    testWidgets('expandido reparte el ancho entre las cuatro opciones', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await montar(
        tester,
        SelectorDeRango(
          rango: RangoDeGrafica.dia,
          alElegir: (_) {},
          expandido: true,
        ),
      );

      final anchos = [
        for (final r in RangoDeGrafica.values)
          tester.getSize(find.byKey(claveDeRango(r))).width,
      ];
      expect(anchos.toSet().length, 1);
      expect(anchos.reduce((a, b) => a + b), closeTo(360 - 32, 0.5));
    });
  });

  group('TarjetaDeGrafica', () {
    testWidgets('muestra título, valor, cambio, fecha y gráfica', (
      tester,
    ) async {
      await montar(tester, _tarjeta());

      expect(find.text('Valor del portafolio'), findsOneWidget);
      expect(find.text('USD 10.000,00'), findsOneWidget);
      expect(find.text('+1,25 %'), findsOneWidget);
      expect(find.text('08/11/2026 07:00'), findsOneWidget);
      expect(find.byType(GraficaDeLinea), findsOneWidget);
    });

    testWidgets(
      'en el celular el selector va bajo la gráfica, a todo el ancho',
      (tester) async {
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await montar(tester, _tarjeta());

        final grafica = tester.getRect(find.byType(GraficaDeLinea));
        final selector = tester.getRect(find.byType(SelectorDeRango));
        expect(selector.top, greaterThanOrEqualTo(grafica.bottom));
        expect(selector.width, closeTo(grafica.width, 0.5));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('en pantalla ancha el selector va junto al título', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await montar(tester, _tarjeta());

      final titulo = tester.getRect(find.text('Valor del portafolio'));
      final selector = tester.getRect(find.byType(SelectorDeRango));
      final grafica = tester.getRect(find.byType(GraficaDeLinea));
      expect(selector.bottom, lessThanOrEqualTo(grafica.top));
      expect(selector.left, greaterThanOrEqualTo(titulo.right));
    });

    testWidgets('elegir un rango avisa y refrescar se puede tocar', (
      tester,
    ) async {
      final elegidos = <RangoDeGrafica>[];
      var refrescos = 0;
      await montar(
        tester,
        _tarjeta(alElegir: elegidos.add, alRefrescar: () => refrescos++),
      );

      await tester.tap(find.byKey(claveDeRango(RangoDeGrafica.mes)));
      await tester.tap(find.byTooltip('Actualizar'));

      expect(elegidos, [RangoDeGrafica.mes]);
      expect(refrescos, 1);
    });

    testWidgets('sin valor ni botón de refrescar no los muestra', (
      tester,
    ) async {
      await montar(tester, _tarjeta(valor: null));

      expect(find.textContaining('USD'), findsNothing);
      expect(find.byTooltip('Actualizar'), findsNothing);
    });

    for (final oscuro in [false, true]) {
      for (final escala in [1.0, 2.0]) {
        testWidgets('a 360 dp no se desborda (${oscuro ? 'oscuro' : 'claro'}, '
            'texto ×${escala.toInt()})', (tester) async {
          tester.view.physicalSize = const Size(360, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              theme: oscuro ? crearTemaOscuro() : crearTema(),
              builder: (context, hijo) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(escala)),
                child: hijo!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _tarjeta(valor: 1234567.89, alRefrescar: () {}),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

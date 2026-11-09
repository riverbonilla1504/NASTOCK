import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/shared/widgets/calendario.dart';

import 'montar.dart';

final _hoy = DateTime(2026, 11, 6);
final _festivo = DateTime(2026, 11, 26);
final _media = DateTime(2026, 11, 27);

Future<void> _montarAlto(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await montar(tester, widget);
}

void main() {
  test('formatea el día y el título del mes', () {
    expect(formatearDiaDeCalendario(DateTime(2026, 11, 9)), '09/11/2026');
    expect(tituloDeMes(DateTime(2026, 11, 20)), 'Noviembre 2026');
  });

  testWidgets('arranca en lunes y marca hoy, festivo y media jornada', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await _montarAlto(
      tester,
      CalendarioDelMercado(
        mes: _hoy,
        hoy: _hoy,
        festivos: {_festivo},
        mediasJornadas: {_media},
      ),
    );

    expect(find.text('Noviembre 2026'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^viernes 6 de noviembre de 2026, hoy')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp('26 de noviembre.*festivo: la bolsa cierra'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('27 de noviembre.*media jornada')),
      findsOneWidget,
    );
    expect(find.text('Festivo: la bolsa cierra'), findsOneWidget);
    expect(find.text('Media jornada: cierre anticipado'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('hoy va en un círculo morado', (tester) async {
    await _montarAlto(tester, CalendarioDelMercado(mes: _hoy, hoy: _hoy));

    final circulo = tester.widget<Container>(
      find.ancestor(of: find.text('6'), matching: find.byType(Container)).first,
    );
    expect(
      (circulo.decoration! as BoxDecoration).color,
      ColoresTema.claro.morado,
    );
  });

  testWidgets('elegir un día avisa y fuera del rango no se puede', (
    tester,
  ) async {
    final elegidos = <DateTime>[];
    await _montarAlto(
      tester,
      CalendarioDelMercado(
        mes: _hoy,
        hoy: _hoy,
        primerDia: DateTime(2026, 11, 5),
        alElegirDia: elegidos.add,
      ),
    );

    await tester.tap(find.text('9'));
    await tester.tap(find.text('3'));
    expect(elegidos, [DateTime(2026, 11, 9)]);
  });

  testWidgets('cambia de mes con las flechas', (tester) async {
    DateTime? mes;
    await _montarAlto(
      tester,
      CalendarioDelMercado(mes: _hoy, hoy: _hoy, alCambiarMes: (m) => mes = m),
    );

    await tester.tap(find.byTooltip('Mes siguiente'));
    expect(mes, DateTime(2026, 12));
    await tester.tap(find.byTooltip('Mes anterior'));
    expect(mes, DateTime(2026, 10));
  });

  testWidgets('el campo abre el selector y devuelve el periodo elegido', (
    tester,
  ) async {
    DateTimeRange? periodo;
    await _montarAlto(
      tester,
      CampoDePeriodo(
        etiqueta: 'Periodo',
        hoy: _hoy,
        festivos: {_festivo},
        alCambiar: (p) => periodo = p,
      ),
    );

    expect(find.text('Elige el periodo'), findsOneWidget);
    await tester.tap(find.text('Elige el periodo'));
    await tester.pumpAndSettle();
    expect(find.text('Elige el primer día'), findsOneWidget);

    final listo = find.widgetWithText(FilledButton, 'Listo');
    expect(tester.widget<FilledButton>(listo).enabled, isFalse);

    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.tap(find.text('20'));
    await tester.pump();
    expect(find.text('Desde 09/11/2026 hasta 20/11/2026'), findsOneWidget);
    expect(tester.widget<FilledButton>(listo).enabled, isTrue);

    await tester.tap(listo);
    await tester.pumpAndSettle();
    expect(
      periodo,
      DateTimeRange(start: DateTime(2026, 11, 9), end: DateTime(2026, 11, 20)),
    );
  });

  testWidgets('cancelar no cambia el periodo', (tester) async {
    var cambios = 0;
    await _montarAlto(
      tester,
      CampoDePeriodo(
        etiqueta: 'Periodo',
        hoy: _hoy,
        alCambiar: (_) => cambios++,
      ),
    );

    await tester.tap(find.text('Elige el periodo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(cambios, 0);
  });
}

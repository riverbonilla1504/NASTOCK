import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/shared/widgets/barra_de_pestanas.dart';

void main() {
  testWidgets('cada destino de la isla se localiza por su clave', (
    tester,
  ) async {
    int? elegida;
    await tester.pumpWidget(
      MaterialApp(
        theme: crearTema(),
        home: Scaffold(
          extendBody: true,
          bottomNavigationBar: BarraDePestanas(
            actual: 0,
            alElegir: (i) => elegida = i,
            pestanas: const [
              Pestana(
                etiqueta: 'Mercado',
                icono: Icons.show_chart,
                clave: Key('destino-mercado'),
              ),
              Pestana(
                etiqueta: 'Alertas',
                icono: Icons.notifications_none,
                clave: Key('destino-alertas'),
              ),
              Pestana(etiqueta: 'Sin clave', icono: Icons.circle_outlined),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('destino-mercado')), findsOneWidget);
    expect(find.byKey(const Key('destino-alertas')), findsOneWidget);

    await tester.tap(find.byKey(const Key('destino-alertas')));
    expect(elegida, 1);
  });
}

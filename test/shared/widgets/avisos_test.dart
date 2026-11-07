import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/errores/codigos_de_error.dart';
import 'package:inversiones/shared/widgets/avisos.dart';
import 'package:inversiones/shared/widgets/forma_de_linea.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'montar.dart';

void main() {
  testWidgets('cada tipo muestra su título y su mensaje', (tester) async {
    await montar(
      tester,
      Column(
        children: [
          for (final tipo in TipoAviso.values)
            AvisoEnLinea(
              tipo: tipo,
              titulo: 'Título ${tipo.name}',
              mensaje: 'Mensaje ${tipo.name}',
            ),
        ],
      ),
    );

    for (final tipo in TipoAviso.values) {
      expect(find.text('Título ${tipo.name}'), findsOneWidget);
      expect(find.text('Mensaje ${tipo.name}'), findsOneWidget);
    }
  });

  test('cada tipo se distingue sin color: borde y lectura propios (CA-8)', () {
    final formas = TipoAviso.values.map(formaDeAviso).toSet();
    final lecturas = TipoAviso.values.map(lecturaDeTipo).toSet();
    expect(formas.length, TipoAviso.values.length);
    expect(lecturas.length, TipoAviso.values.length);
    expect(formaDeAviso(TipoAviso.error), FormaDeLinea.doble);
    expect(formaDeAviso(TipoAviso.desactualizado), FormaDeLinea.punteada);
  });

  testWidgets('el lector de pantalla oye el tipo antes del texto', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montar(
      tester,
      const AvisoEnLinea(
        tipo: TipoAviso.advertencia,
        mensaje: 'No se abren compras tan cerca de la apertura o del cierre.',
      ),
    );

    expect(find.bySemanticsLabel(RegExp('^Advertencia')), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('el error no usa rojo: marca y borde en tinta', (tester) async {
    await montar(
      tester,
      const AvisoEnLinea(tipo: TipoAviso.error, mensaje: 'Algo falló.'),
    );

    final borde = tester.widget<BordeConForma>(find.byType(BordeConForma));
    expect(borde.forma, FormaDeLinea.doble);
    expect(borde.color, ColoresAlmanaque.claro.tinta);
  });

  testWidgets(
    'deError traduce el código y nunca muestra el texto crudo (CA-9)',
    (tester) async {
      await montar(
        tester,
        Column(
          children: [
            AvisoEnLinea.deError(
              const PostgrestException(message: 'FONDOS_INSUFICIENTES'),
            ),
            AvisoEnLinea.deError(
              const PostgrestException(
                message: 'duplicate key value violates unique constraint',
              ),
            ),
          ],
        ),
      );

      expect(find.text('No tienes disponible suficiente.'), findsOneWidget);
      expect(find.text(mensajeGenerico), findsOneWidget);
      expect(find.textContaining('duplicate'), findsNothing);
    },
  );

  testWidgets('la acción del aviso responde al toque', (tester) async {
    var toques = 0;
    await montar(
      tester,
      AvisoEnLinea(
        tipo: TipoAviso.error,
        mensaje: 'No tienes disponible suficiente.',
        accion: 'Revisar',
        alAccionar: () => toques++,
      ),
    );

    await tester.tap(find.text('Revisar'));
    expect(toques, 1);
  });

  testWidgets('el aviso temporal aparece y su acción lo cierra', (
    tester,
  ) async {
    var toques = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: crearTema(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => mostrarAvisoTemporal(
                context,
                'Parámetro guardado',
                accion: 'Ver',
                alAccionar: () => toques++,
              ),
              child: const Text('Guardar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Parámetro guardado'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    expect(toques, 1);
    expect(find.text('Parámetro guardado'), findsNothing);
  });
}

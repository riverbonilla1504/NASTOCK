import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/features/fondo/presentation/pagina_fondo.dart';

void main() {
  testWidgets('muestra el patrimonio y distingue los dos pesos', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resumenFondoProvider.overrideWith(
            (ref) async => <ResumenDeBolsillo>[
              (
                bolsillo: 'reserva',
                efectivo: 5000,
                posiciones: 400,
                patrimonio: 5400,
                pesoActual: 54,
                pesoObjetivo: 50,
              ),
              (
                bolsillo: 'usuarios',
                efectivo: 4600,
                posiciones: 0,
                patrimonio: 4600,
                pesoActual: 46,
                pesoObjetivo: 25,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: PaginaFondo()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Patrimonio del fondo: USD 10.000,00'), findsOneWidget);
    expect(find.text('Reserva'), findsOneWidget);
    expect(find.text('Valor de las posiciones: USD 400,00'), findsOneWidget);
    expect(find.text('Peso actual: 54,00 %'), findsOneWidget);
    expect(find.text('Peso objetivo: 50,00 %'), findsOneWidget);
  });
}

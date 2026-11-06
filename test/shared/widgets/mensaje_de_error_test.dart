import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/errores/codigos_de_error.dart';
import 'package:inversiones/shared/widgets/mensaje_de_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

Future<void> _mostrar(WidgetTester tester, Object? error) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: MensajeDeError(error: error)),
    ),
  );
}

void main() {
  testWidgets('muestra el mensaje en español del código', (tester) async {
    await _mostrar(
      tester,
      const PostgrestException(message: 'FONDOS_INSUFICIENTES'),
    );

    expect(find.text('No tienes disponible suficiente.'), findsOneWidget);
  });

  testWidgets('nunca muestra el texto crudo de la excepción', (tester) async {
    await _mostrar(
      tester,
      const PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      ),
    );

    expect(find.text(mensajeGenerico), findsOneWidget);
    expect(find.textContaining('duplicate'), findsNothing);
  });
}

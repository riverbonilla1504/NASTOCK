/// E2E de la app (docs/15 §2): abre la app real en Chrome contra el backend
/// local, entra con el ingreso con correo del modo pruebas y llega a la
/// pantalla inicial. Cada historia agrega después sus escenarios del catálogo de
/// docs/15 §4 en este mismo directorio.
///
/// El ingreso con Google no se puede automatizar (docs/04 §1): por eso se usa el
/// de correo y contraseña, que solo existe con `MODO_PRUEBAS` (CI y local) y con
/// un usuario de prueba de `supabase/seed.sql` (no es un secreto).
///
/// Se ejecuta con `flutter drive` (ver `scripts/verificar.sh`), que pasa
/// `MODO_PRUEBAS`, `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` con `--dart-define`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:inversiones/app/pagina_inicio.dart';
import 'package:inversiones/features/auth/presentation/pagina_de_ingreso.dart';
import 'package:inversiones/main.dart' as app;

/// Espera, sin dormir a ciegas, a que aparezca algo que depende de la red.
Future<void> _esperarA(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'la app abre en el ingreso, conectada al backend, y entra con el correo del modo pruebas',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Sin sesión, la app abre en la pantalla de ingreso.
      expect(find.byType(PaginaDeIngreso), findsOneWidget);
      expect(find.byType(PaginaInicio), findsNothing);
      // Si faltaran los --dart-define, la pantalla avisaría que no hay conexión.
      expect(
        find.byKey(PaginaDeIngreso.claveDelAvisoDeConfiguracion),
        findsNothing,
      );
      // El ingreso con correo solo está con MODO_PRUEBAS.
      expect(
        find.byKey(PaginaDeIngreso.claveDelFormularioDePruebas),
        findsOneWidget,
      );

      await tester.enterText(
        find.descendant(
          of: find.byKey(PaginaDeIngreso.claveDelCorreo),
          matching: find.byType(TextField),
        ),
        'admin@prueba.local',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(PaginaDeIngreso.claveDeLaContrasena),
          matching: find.byType(TextField),
        ),
        'prueba-local-1234',
      );
      await tester.ensureVisible(
        find.byKey(PaginaDeIngreso.claveDelBotonDeCorreo),
      );
      await tester.tap(find.byKey(PaginaDeIngreso.claveDelBotonDeCorreo));
      await _esperarA(tester, find.byType(PaginaInicio));
      await tester.pumpAndSettle();

      // Con la sesión iniciada, la app pasa sola a la pantalla inicial.
      expect(find.byType(PaginaInicio), findsOneWidget);
      expect(find.byType(PaginaDeIngreso), findsNothing);
      expect(
        find.text('Plataforma de inversión asistida por IA'),
        findsOneWidget,
      );
      expect(
        find.byKey(PaginaInicio.claveDeAvisoSinConfiguracion),
        findsNothing,
      );
    },
  );
}

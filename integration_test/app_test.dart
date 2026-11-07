/// E2E de la app (docs/15 §2): abre la app real en Chrome contra el backend
/// local y comprueba la pantalla inicial. Cada historia agrega después sus
/// escenarios del catálogo de docs/15 §4 en este mismo directorio.
///
/// Se ejecuta con `flutter drive` (ver `scripts/verificar.sh`), que pasa
/// `MODO_PRUEBAS`, `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` con `--dart-define`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:inversiones/app/pagina_inicio.dart';
import 'package:inversiones/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la app abre en la pantalla inicial y conectada al backend', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();

    expect(find.byType(PaginaInicio), findsOneWidget);
    expect(
      find.text('Plataforma de inversión asistida por IA'),
      findsOneWidget,
    );
    // Si faltaran los --dart-define, la pantalla avisaría que no hay conexión.
    expect(find.byKey(PaginaInicio.claveDeAvisoSinConfiguracion), findsNothing);
  });
}

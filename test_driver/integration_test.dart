import 'package:integration_test/integration_test_driver.dart';

/// Lo ejecuta `flutter drive` (scripts/verificar.sh y CI): abre la app en
/// Chrome y corre `integration_test/app_test.dart` (docs/15 §2).
Future<void> main() => integrationDriver();

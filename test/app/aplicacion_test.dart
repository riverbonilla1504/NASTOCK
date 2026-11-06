import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/aplicacion.dart';
import 'package:inversiones/app/enrutador.dart';
import 'package:inversiones/app/pagina_inicio.dart';
import 'package:inversiones/core/configuracion/entorno.dart';

const _entornoConfigurado = Entorno(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseLlavePublicable: 'llave-publicable-de-prueba',
);

const _entornoSinConfigurar = Entorno(
  supabaseUrl: '',
  supabaseLlavePublicable: '',
);

Future<void> _abrirApp(WidgetTester tester, Entorno entorno) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [entornoProvider.overrideWithValue(entorno)],
      child: const Aplicacion(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la app abre en la pantalla inicial', (tester) async {
    await _abrirApp(tester, _entornoConfigurado);

    expect(find.byType(PaginaInicio), findsOneWidget);
    expect(find.text('RiTech Inversiones'), findsOneWidget);
    expect(
      find.text('Plataforma de inversión asistida por IA'),
      findsOneWidget,
    );
    expect(find.byKey(PaginaInicio.claveDeAvisoSinConfiguracion), findsNothing);
  });

  testWidgets('sin configuración la pantalla inicial lo avisa', (tester) async {
    await _abrirApp(tester, _entornoSinConfigurar);

    expect(find.byType(PaginaInicio), findsOneWidget);
    expect(
      find.byKey(PaginaInicio.claveDeAvisoSinConfiguracion),
      findsOneWidget,
    );
  });

  testWidgets('la ruta raíz lleva al inicio', (tester) async {
    await _abrirApp(tester, _entornoConfigurado);

    final contenedor = ProviderScope.containerOf(
      tester.element(find.byType(PaginaInicio)),
    );
    final enrutador = contenedor.read(enrutadorProvider);
    enrutador.go('/');
    await tester.pumpAndSettle();

    expect(find.byType(PaginaInicio), findsOneWidget);
    expect(enrutador.routeInformationProvider.value.uri.path, Rutas.inicio);
  });
}

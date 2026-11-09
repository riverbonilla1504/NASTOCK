import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/aplicacion.dart';
import 'package:inversiones/app/enrutador.dart';
import 'package:inversiones/app/pagina_inicio.dart';
import 'package:inversiones/core/configuracion/entorno.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/auth/presentation/pagina_de_ingreso.dart';
import 'package:inversiones/features/auth/presentation/sesion_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import '../core/realtime/falsos.dart';
import '../features/auth/falsos.dart';

const _entornoConfigurado = Entorno(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseLlavePublicable: 'llave-publicable-de-prueba',
  googleWebClientId: 'cliente-web-de-prueba.apps.googleusercontent.com',
);

const _entornoSinConfigurar = Entorno(
  supabaseUrl: '',
  supabaseLlavePublicable: '',
);

/// Una sesión de un Usuario activo: el token trae `app_rol` y `app_estado`.
Session _sesionActiva() => sesionDePrueba(rol: 'usuario', estado: 'activo');

/// Sesión fija, para llegar a la pantalla inicial sin pasar por Supabase.
class _SesionFija extends SesionNotifier {
  _SesionFija(this._sesion);

  final Session? _sesion;

  @override
  Session? build() => _sesion;
}

Future<void> _abrirApp(
  WidgetTester tester,
  Entorno entorno, {
  required IngresoRepositorioFalso repo,
  Session? sesionFija,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...tiempoRealEnMemoria(),
        entornoProvider.overrideWithValue(entorno),
        ingresoRepositorioProvider.overrideWithValue(repo),
        if (sesionFija != null)
          sesionProvider.overrideWith(() => _SesionFija(sesionFija)),
      ],
      child: const Aplicacion(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin sesión la app abre en la pantalla de ingreso', (
    tester,
  ) async {
    await _abrirApp(
      tester,
      _entornoConfigurado,
      repo: IngresoRepositorioFalso(),
    );

    expect(find.byType(PaginaDeIngreso), findsOneWidget);
    expect(find.byType(PaginaInicio), findsNothing);
    expect(find.text('Entrar con Google'), findsOneWidget);
  });

  testWidgets('con sesión la app abre en la pantalla inicial', (tester) async {
    await _abrirApp(
      tester,
      _entornoConfigurado,
      repo: IngresoRepositorioFalso()..sesionActual = _sesionActiva(),
    );

    expect(find.byType(PaginaInicio), findsOneWidget);
    expect(find.text('RiTech Inversiones'), findsOneWidget);
    expect(
      find.text('Plataforma de inversión asistida por IA'),
      findsOneWidget,
    );
    expect(find.byKey(PaginaInicio.claveDeAvisoSinConfiguracion), findsNothing);
  });

  testWidgets('sin configuración la app abre en el ingreso y lo avisa', (
    tester,
  ) async {
    await _abrirApp(
      tester,
      _entornoSinConfigurar,
      repo: IngresoRepositorioFalso(),
    );

    expect(find.byType(PaginaDeIngreso), findsOneWidget);
    expect(
      find.byKey(PaginaDeIngreso.claveDelAvisoDeConfiguracion),
      findsOneWidget,
    );
  });

  testWidgets('la pantalla inicial también avisa si falta la configuración', (
    tester,
  ) async {
    await _abrirApp(
      tester,
      _entornoSinConfigurar,
      repo: IngresoRepositorioFalso(),
      sesionFija: _sesionActiva(),
    );

    expect(find.byType(PaginaInicio), findsOneWidget);
    expect(
      find.byKey(PaginaInicio.claveDeAvisoSinConfiguracion),
      findsOneWidget,
    );
  });

  testWidgets('con sesión la ruta raíz lleva al inicio', (tester) async {
    await _abrirApp(
      tester,
      _entornoConfigurado,
      repo: IngresoRepositorioFalso()..sesionActual = _sesionActiva(),
    );

    final contenedor = ProviderScope.containerOf(
      tester.element(find.byType(PaginaInicio)),
    );
    final enrutador = contenedor.read(enrutadorProvider);
    enrutador.go('/');
    await tester.pumpAndSettle();

    expect(find.byType(PaginaInicio), findsOneWidget);
    expect(enrutador.routeInformationProvider.value.uri.path, Rutas.inicio);
  });

  testWidgets('sin sesión la ruta raíz lleva al ingreso', (tester) async {
    await _abrirApp(
      tester,
      _entornoConfigurado,
      repo: IngresoRepositorioFalso(),
    );

    final contenedor = ProviderScope.containerOf(
      tester.element(find.byType(PaginaDeIngreso)),
    );
    final enrutador = contenedor.read(enrutadorProvider);
    enrutador.go('/');
    await tester.pumpAndSettle();

    expect(find.byType(PaginaDeIngreso), findsOneWidget);
    expect(enrutador.routeInformationProvider.value.uri.path, Rutas.ingreso);
  });

  testWidgets('al ingresar la app pasa sola a la pantalla inicial (CA-1)', (
    tester,
  ) async {
    final repo = IngresoRepositorioFalso();
    await _abrirApp(tester, _entornoConfigurado, repo: repo);
    expect(find.byType(PaginaDeIngreso), findsOneWidget);

    repo.sesiones.add(_sesionActiva());
    await tester.pumpAndSettle();

    expect(find.byType(PaginaInicio), findsOneWidget);
    expect(find.byType(PaginaDeIngreso), findsNothing);
  });

  testWidgets('al perder la sesión la app vuelve al ingreso', (tester) async {
    final repo = IngresoRepositorioFalso()..sesionActual = _sesionActiva();
    await _abrirApp(tester, _entornoConfigurado, repo: repo);
    expect(find.byType(PaginaInicio), findsOneWidget);

    repo.sesiones.add(null);
    await tester.pumpAndSettle();

    expect(find.byType(PaginaDeIngreso), findsOneWidget);
    expect(find.byType(PaginaInicio), findsNothing);
  });
}

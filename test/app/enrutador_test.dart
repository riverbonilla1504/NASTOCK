import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inversiones/app/aplicacion.dart';
import 'package:inversiones/app/cascaron_de_navegacion.dart';
import 'package:inversiones/app/catalogo/pagina_catalogo.dart';
import 'package:inversiones/app/destinos.dart';
import 'package:inversiones/app/enrutador.dart';
import 'package:inversiones/app/pagina_inicio.dart';
import 'package:inversiones/app/pagina_marcador.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/configuracion/entorno.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/auth/presentation/acceso_de_sesion_provider.dart';
import 'package:inversiones/features/auth/presentation/pagina_cuenta_suspendida.dart';
import 'package:inversiones/features/auth/presentation/pagina_de_ingreso.dart';
import 'package:inversiones/shared/widgets/barra_de_pestanas.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import '../features/auth/falsos.dart';

const _entorno = Entorno(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseLlavePublicable: 'llave-publicable-de-prueba',
  googleWebClientId: 'cliente-web-de-prueba.apps.googleusercontent.com',
);

Session _sesion(String? rol, [String? estado = 'activo']) =>
    sesionDePrueba(rol: rol, estado: estado);

/// Abre la app completa con [repo] y devuelve el enrutador.
Future<GoRouter> _abrir(
  WidgetTester tester,
  IngresoRepositorioFalso repo,
) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        entornoProvider.overrideWithValue(_entorno),
        ingresoRepositorioProvider.overrideWithValue(repo),
      ],
      child: const Aplicacion(),
    ),
  );
  await tester.pumpAndSettle();
  final contenedor = ProviderScope.containerOf(
    tester.element(find.byType(Aplicacion)),
  );
  return contenedor.read(enrutadorProvider);
}

String _ruta(GoRouter enrutador) =>
    enrutador.routeInformationProvider.value.uri.path;

Future<void> _ir(WidgetTester tester, GoRouter enrutador, String ruta) async {
  enrutador.go(ruta);
  await tester.pumpAndSettle();
}

IngresoRepositorioFalso _conSesion(String? rol, [String? estado = 'activo']) =>
    IngresoRepositorioFalso()..sesionActual = _sesion(rol, estado);

void main() {
  group('CA-3: sin sesión', () {
    testWidgets('cualquier ruta lleva al ingreso', (tester) async {
      final enrutador = await _abrir(tester, IngresoRepositorioFalso());
      expect(find.byType(PaginaDeIngreso), findsOneWidget);

      for (final ruta in [
        Rutas.inicio,
        Rutas.cupo,
        '/admin',
        '/riesgo/bandeja',
      ]) {
        await _ir(tester, enrutador, ruta);
        expect(find.byType(PaginaDeIngreso), findsOneWidget, reason: ruta);
        expect(_ruta(enrutador), Rutas.ingreso, reason: ruta);
      }
    });

    testWidgets('no ve el menú', (tester) async {
      await _abrir(tester, IngresoRepositorioFalso());

      expect(find.byType(BarraDePestanas), findsNothing);
      expect(find.byType(CascaronDeNavegacion), findsNothing);
    });
  });

  group('CA-3: cuenta que no está activa', () {
    for (final (rol, estado) in [
      ('usuario', 'suspendido'),
      ('analista', 'baja'),
      (null, null),
    ]) {
      testWidgets(
        'rol $rol con estado $estado va a /cuenta-suspendida y no sale',
        (tester) async {
          final enrutador = await _abrir(tester, _conSesion(rol, estado));

          expect(find.byType(PaginaCuentaSuspendida), findsOneWidget);
          expect(_ruta(enrutador), Rutas.cuentaSuspendida);
          expect(find.byType(BarraDePestanas), findsNothing);

          for (final ruta in [Rutas.inicio, Rutas.ingreso, '/admin', '/cupo']) {
            await _ir(tester, enrutador, ruta);
            expect(
              find.byType(PaginaCuentaSuspendida),
              findsOneWidget,
              reason: ruta,
            );
            expect(_ruta(enrutador), Rutas.cuentaSuspendida, reason: ruta);
          }
        },
      );
    }

    testWidgets('al reactivarse (token activo) sale de /cuenta-suspendida', (
      tester,
    ) async {
      final repo = _conSesion('usuario', 'suspendido');
      final enrutador = await _abrir(tester, repo);
      expect(find.byType(PaginaCuentaSuspendida), findsOneWidget);

      repo.sesiones.add(_sesion('usuario'));
      await tester.pumpAndSettle();

      expect(find.byType(PaginaCuentaSuspendida), findsNothing);
      expect(find.byType(PaginaInicio), findsOneWidget);
      expect(_ruta(enrutador), Rutas.inicio);
    });

    testWidgets(
      'al suspenderse con la app abierta (token renovado) pasa a la pantalla',
      (tester) async {
        final repo = _conSesion('usuario');
        await _abrir(tester, repo);
        expect(find.byType(PaginaInicio), findsOneWidget);

        repo.sesiones.add(_sesion('usuario', 'suspendido'));
        await tester.pumpAndSettle();

        expect(find.byType(PaginaCuentaSuspendida), findsOneWidget);
        expect(find.byType(PaginaInicio), findsNothing);
      },
    );
  });

  group('CA-1: cada rol ve su menú', () {
    for (final rol in ['usuario', 'analista', 'administrador']) {
      testWidgets('menú de $rol', (tester) async {
        await _abrir(tester, _conSesion(rol));

        final menu = destinosDelMvp
            .where((d) => d.roles.any((r) => r.name == rol))
            .map((d) => d.ruta)
            .toList();
        final visibles = [
          for (final d in destinosDelMvp)
            if (find.byKey(claveDeDestino(d.ruta)).evaluate().isNotEmpty)
              d.ruta,
        ];
        expect(visibles, menu);
        expect(find.byType(PaginaInicio), findsOneWidget);
      });
    }

    testWidgets('tocar un destino del menú abre su pantalla', (tester) async {
      final enrutador = await _abrir(tester, _conSesion('usuario'));

      await tester.tap(find.byKey(claveDeDestino(Rutas.cupo)));
      await tester.pumpAndSettle();

      expect(_ruta(enrutador), Rutas.cupo);
      expect(find.byType(PaginaMarcador), findsOneWidget);
      expect(find.text('Mi cupo'), findsWidgets);
    });

    testWidgets('el Administrador entra a Administración', (tester) async {
      final enrutador = await _abrir(tester, _conSesion('administrador'));

      await _ir(tester, enrutador, '/admin');

      expect(_ruta(enrutador), '/admin');
      expect(find.byType(PaginaMarcador), findsOneWidget);
      expect(find.text('Administración'), findsWidgets);
    });
  });

  group('CA-2: rutas de otro rol o que no existen vuelven al inicio', () {
    testWidgets('el Usuario en /admin y en /riesgo', (tester) async {
      final enrutador = await _abrir(tester, _conSesion('usuario'));

      for (final ruta in [
        '/admin',
        '/admin/usuarios',
        '/riesgo',
        '/riesgo/bandeja',
      ]) {
        await _ir(tester, enrutador, ruta);
        expect(_ruta(enrutador), Rutas.inicio, reason: ruta);
        expect(find.byType(PaginaInicio), findsOneWidget, reason: ruta);
      }
    });

    testWidgets('el Analista en /admin y en /cupo', (tester) async {
      final enrutador = await _abrir(tester, _conSesion('analista'));

      for (final ruta in ['/admin', '/admin/usuarios', '/cupo']) {
        await _ir(tester, enrutador, ruta);
        expect(_ruta(enrutador), Rutas.inicio, reason: ruta);
      }
      await _ir(tester, enrutador, '/alertas');
      expect(_ruta(enrutador), '/alertas');
    });

    testWidgets('el Administrador en /cupo', (tester) async {
      final enrutador = await _abrir(tester, _conSesion('administrador'));

      await _ir(tester, enrutador, '/cupo');

      expect(_ruta(enrutador), Rutas.inicio);
    });

    testWidgets('una ruta que no existe lleva al inicio', (tester) async {
      final enrutador = await _abrir(tester, _conSesion('usuario'));

      await _ir(tester, enrutador, '/no-existe');

      expect(_ruta(enrutador), Rutas.inicio);
      expect(find.byType(PaginaInicio), findsOneWidget);
    });

    testWidgets(
      'CA-4: /riesgo no tiene pantalla en el MVP corto, tampoco para el Administrador',
      (tester) async {
        final enrutador = await _abrir(tester, _conSesion('administrador'));

        await _ir(tester, enrutador, '/riesgo/bandeja');

        expect(_ruta(enrutador), Rutas.inicio);
        expect(find.byType(PaginaInicio), findsOneWidget);
      },
    );
  });

  group('el cambio de rol del token reconstruye el menú', () {
    testWidgets('de Usuario a Analista pierde Mi cupo y sale de /cupo', (
      tester,
    ) async {
      final repo = _conSesion('usuario');
      final enrutador = await _abrir(tester, repo);
      await _ir(tester, enrutador, '/cupo');
      expect(find.byKey(claveDeDestino(Rutas.cupo)), findsOneWidget);

      repo.sesiones.add(_sesion('analista'));
      await tester.pumpAndSettle();

      expect(find.byKey(claveDeDestino(Rutas.cupo)), findsNothing);
      expect(_ruta(enrutador), Rutas.inicio);
    });

    testWidgets('de Analista a Administrador gana Administración', (
      tester,
    ) async {
      final repo = _conSesion('analista');
      await _abrir(tester, repo);
      expect(find.byKey(claveDeDestino(Rutas.admin)), findsNothing);

      repo.sesiones.add(_sesion('administrador'));
      await tester.pumpAndSettle();

      expect(find.byKey(claveDeDestino(Rutas.admin)), findsOneWidget);
    });
  });

  group('el catálogo de componentes', () {
    testWidgets('no pide sesión aunque las guardas estén activas', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final enrutador = crearEnrutador(
        conCatalogo: true,
        accesoDeSesion: () => AccesoDeSesion.sinSesion,
      );
      addTearDown(enrutador.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entornoProvider.overrideWithValue(_entorno),
            ingresoRepositorioProvider.overrideWithValue(
              IngresoRepositorioFalso(),
            ),
          ],
          child: MaterialApp.router(
            theme: crearTema(),
            routerConfig: enrutador,
          ),
        ),
      );

      enrutador.go(RutasCatalogo.inicio);
      await tester.pumpAndSettle();

      expect(find.byType(PaginaCatalogo), findsOneWidget);
    });
  });
}

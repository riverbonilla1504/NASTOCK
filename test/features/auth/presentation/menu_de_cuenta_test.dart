import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/aplicacion.dart';
import 'package:inversiones/app/cascaron_de_navegacion.dart';
import 'package:inversiones/app/enrutador.dart';
import 'package:inversiones/app/pagina_inicio.dart';
import 'package:inversiones/app/raiz_de_providers.dart';
import 'package:inversiones/core/configuracion/entorno.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/core/realtime/canales.dart';
import 'package:inversiones/core/realtime/fuente_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/gestor_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/reloj.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/mercado/data/mercado_repositorio.dart';
import 'package:inversiones/features/mercado/presentation/mercado_provider.dart';
import 'package:inversiones/features/auth/presentation/menu_de_cuenta.dart';
import 'package:inversiones/features/auth/presentation/pagina_de_ingreso.dart';
import 'package:inversiones/shared/widgets/botones.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import '../../../core/realtime/falsos.dart';
import '../../mercado/ayudas.dart';
import '../falsos.dart';

const _entorno = Entorno(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseLlavePublicable: 'llave-publicable-de-prueba',
  googleWebClientId: 'cliente-web-de-prueba.apps.googleusercontent.com',
);

/// Un dato de la sesión anterior: debe desaparecer al cerrarla (CA-3).
class _Sonda extends Notifier<int> {
  @override
  int build() => 0;

  void sube() => state++;
}

final _sondaProvider = NotifierProvider<_Sonda, int>(_Sonda.new);

/// Anota el orden de los pasos del cierre.
class _RepositorioConBitacora extends IngresoRepositorioFalso {
  _RepositorioConBitacora(this.bitacora);

  final List<String> bitacora;

  @override
  Future<void> cerrarSesion() async {
    bitacora.add('signOut');
    await super.cerrarSesion();
  }
}

/// Un gestor que solo anota que se le pidió cerrar los canales.
class _GestorConBitacora extends GestorDeTiempoReal {
  _GestorConBitacora(FuenteFalsa fuente, this.bitacora)
    : super(fuente, const []);

  final List<String> bitacora;

  @override
  Future<void> cerrar() async => bitacora.add('canales');
}

Session _sesion(String rol) => sesionDePrueba(
  rol: rol,
  estado: 'activo',
  email: '$rol@prueba.local',
  id: 'usuario-$rol',
);

Future<void> _abrir(
  WidgetTester tester,
  IngresoRepositorioFalso repo,
  FuenteFalsa fuente, {
  double ancho = 360,
  double textoEscala = 1,
  bool conRaiz = true,
  GestorDeTiempoReal Function()? gestor,
}) async {
  tester.view.physicalSize = Size(ancho, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final overrides = <Override>[
    entornoProvider.overrideWithValue(_entorno),
    ingresoRepositorioProvider.overrideWithValue(repo),
    // La pantalla de inicio es Mercado: se le da su repositorio y su tiempo
    // real en memoria, sin Supabase.
    mercadoRepositorioProvider.overrideWithValue(MercadoRepositorioFalso()),
    fuenteDeTiempoRealProvider.overrideWithValue(fuente),
    gestorDeTiempoRealProvider.overrideWith(
      (ref) =>
          gestor?.call() ??
          GestorDeTiempoReal(fuente, canalesDeRol(RolApp.usuario, 'usuario-1')),
    ),
    relojRepositorioProvider.overrideWithValue(
      RelojRepositorioFalso(() => ahoraDePrueba),
    ),
    ahoraLocalProvider.overrideWithValue(() => ahoraDePrueba),
    segundoProvider.overrideWith((ref) => const Stream<int>.empty()),
  ];
  tester.platformDispatcher.textScaleFactorTestValue = textoEscala;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  const app = Aplicacion();
  await tester.pumpWidget(
    conRaiz
        ? RaizDeProviders(overrides: overrides, child: app)
        : ProviderScope(overrides: overrides, child: app),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _contenedor(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

Finder get _cuenta => find.byKey(BotonDeCuenta.clave);
Finder get _cerrarEnLaHoja => find.byKey(HojaDeCuenta.claveDelBotonDeCierre);

Future<void> _abrirHoja(WidgetTester tester) async {
  await tester.tap(_cuenta);
  await tester.pumpAndSettle();
}

/// Toca "Cerrar sesión" en la hoja y luego en la confirmación.
Future<void> _cerrarSesion(WidgetTester tester) async {
  await _abrirHoja(tester);
  await tester.tap(_cerrarEnLaHoja);
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Cerrar sesión'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late IngresoRepositorioFalso repo;
  late FuenteFalsa fuente;

  setUp(() {
    repo = IngresoRepositorioFalso();
    fuente = FuenteFalsa();
  });

  group(
    'el botón de cuenta es visible en toda pantalla y para los tres roles',
    () {
      for (final rol in ['usuario', 'analista', 'administrador']) {
        testWidgets('$rol, en teléfono, con 48 dp', (tester) async {
          repo.sesionActual = _sesion(rol);
          await _abrir(tester, repo, fuente);

          expect(_cuenta, findsOneWidget);
          final tamano = tester.getSize(
            find.descendant(of: _cuenta, matching: find.byType(SizedBox)).first,
          );
          expect(tamano.width, greaterThanOrEqualTo(48));
          expect(tamano.height, greaterThanOrEqualTo(48));
          // Dentro de la pantalla, sin cortarse.
          final caja = tester.getRect(_cuenta);
          expect(caja.right, lessThanOrEqualTo(360));
          expect(caja.top, greaterThanOrEqualTo(0));
        });
      }

      testWidgets('sigue visible al cambiar de pantalla', (tester) async {
        repo.sesionActual = _sesion('administrador');
        await _abrir(tester, repo, fuente);

        _contenedor(tester).read(enrutadorProvider).go(Rutas.alertas);
        await tester.pumpAndSettle();

        expect(find.byType(PaginaInicio), findsNothing);
        expect(_cuenta, findsOneWidget);
      });

      testWidgets('en ventana ancha va al pie del riel', (tester) async {
        repo.sesionActual = _sesion('usuario');
        await _abrir(tester, repo, fuente, ancho: 1280);

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(_cuenta, findsOneWidget);
        expect(
          tester.getRect(_cuenta).left,
          lessThan(tester.getRect(find.byType(NavigationRail)).right),
        );
      });

      testWidgets('no está en la pantalla de ingreso', (tester) async {
        await _abrir(tester, repo, fuente);

        expect(find.byType(PaginaDeIngreso), findsOneWidget);
        expect(_cuenta, findsNothing);
      });
    },
  );

  testWidgets('la hoja muestra quién tiene la sesión y su rol', (tester) async {
    repo.sesionActual = _sesion('administrador');
    await _abrir(tester, repo, fuente);

    await _abrirHoja(tester);

    expect(find.text('administrador@prueba.local'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('pide confirmación y cancelar no cierra nada', (tester) async {
    repo.sesionActual = _sesion('usuario');
    await _abrir(tester, repo, fuente);

    await _abrirHoja(tester);
    await tester.tap(_cerrarEnLaHoja);
    await tester.pumpAndSettle();

    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    expect(
      find.textContaining('Vas a cerrar la sesión de usuario@prueba.local'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cerrar sesión?'), findsNothing);
    expect(repo.cierresDeSesion, 0);
    expect(fuente.cierres, 0);
    expect(find.byType(PaginaInicio), findsOneWidget);
  });

  group('CA-1: cierra la sesión completa', () {
    testWidgets('cancela los canales y luego cierra la sesión de Supabase', (
      tester,
    ) async {
      final bitacora = <String>[];
      final repoConBitacora = _RepositorioConBitacora(bitacora)
        ..sesionActual = _sesion('analista');
      final fuenteLocal = FuenteFalsa();
      await _abrir(
        tester,
        repoConBitacora,
        fuenteLocal,
        gestor: () => _GestorConBitacora(fuenteLocal, bitacora),
      );
      bitacora.clear();

      await _cerrarSesion(tester);

      expect(bitacora.take(2), ['canales', 'signOut']);
      expect(repoConBitacora.cierresDeSesion, 1);
    });

    testWidgets('el repositorio cierra también la sesión de Google', (
      tester,
    ) async {
      // `IngresoRepositorio.cerrarSesion` ya cierra `google_sign_in` (HU-006,
      // probado en ingreso_repositorio_test); aquí se comprueba que el menú
      // llama a esa operación y no a `signOut` suelto.
      repo.sesionActual = _sesion('usuario');
      await _abrir(tester, repo, fuente);

      await _cerrarSesion(tester);

      expect(repo.cierresDeSesion, 1);
    });
  });

  group('CA-3: termina en /ingreso sin datos de la sesión anterior', () {
    testWidgets('lleva al ingreso y descarta todo el estado', (tester) async {
      repo.sesionActual = _sesion('administrador');
      await _abrir(tester, repo, fuente);
      _contenedor(tester).read(_sondaProvider.notifier).sube();
      expect(_contenedor(tester).read(_sondaProvider), 1);

      await _cerrarSesion(tester);

      expect(find.byType(PaginaDeIngreso), findsOneWidget);
      expect(find.byType(PaginaInicio), findsNothing);
      expect(_cuenta, findsNothing);
      expect(
        _contenedor(tester)
            .read(enrutadorProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        Rutas.ingreso,
      );
      // La sonda es de la sesión anterior: el contenedor nuevo no la conoce.
      expect(_contenedor(tester).read(_sondaProvider), 0);
    });

    testWidgets('sin raíz reiniciable igual termina en /ingreso', (
      tester,
    ) async {
      repo.sesionActual = _sesion('usuario');
      await _abrir(tester, repo, fuente, conRaiz: false);

      await _cerrarSesion(tester);

      expect(find.byType(PaginaDeIngreso), findsOneWidget);
      expect(find.byType(PaginaInicio), findsNothing);
    });

    testWidgets('otra persona entra y no ve el menú de la anterior', (
      tester,
    ) async {
      repo.sesionActual = _sesion('administrador');
      await _abrir(tester, repo, fuente);
      expect(find.byKey(claveDeDestino(Rutas.admin)), findsOneWidget);

      await _cerrarSesion(tester);
      // Entra un Usuario (en la app real, por el ingreso).
      repo.sesionActual = _sesion('usuario');
      repo.sesiones.add(repo.sesionActual);
      await tester.pumpAndSettle();

      expect(find.byType(PaginaInicio), findsOneWidget);
      expect(find.byKey(claveDeDestino(Rutas.admin)), findsNothing);
      expect(find.byKey(claveDeDestino(Rutas.cupo)), findsOneWidget);
    });
  });

  group('si no puede cerrar', () {
    testWidgets(
      'avisa sin detalle técnico, mantiene la sesión y deja reintentar',
      (tester) async {
        repo.sesionActual = _sesion('usuario');
        await _abrir(tester, repo, fuente);
        repo.error = StateError('detalle técnico que no debe verse');

        await _cerrarSesion(tester);

        expect(find.text(textoDeFalloAlCerrarSesion), findsOneWidget);
        expect(find.textContaining('detalle técnico'), findsNothing);
        expect(find.byType(PaginaDeIngreso), findsNothing);
        expect(repo.sesionActual, isNotNull);

        // Reintenta y esta vez sí.
        repo.error = null;
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(FilledButton, 'Cerrar sesión'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PaginaDeIngreso), findsOneWidget);
      },
    );
  });

  group('se ve bien', () {
    for (final oscuro in [false, true]) {
      testWidgets(
        'hoja y confirmación a 360 dp con el texto al doble, ${oscuro ? 'oscuro' : 'claro'}',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = oscuro
              ? Brightness.dark
              : Brightness.light;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          repo.sesionActual = _sesion('administrador');
          await _abrir(tester, repo, fuente, textoEscala: 2);

          await _abrirHoja(tester);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(_cerrarEnLaHoja);
          await tester.tap(_cerrarEnLaHoja);
          await tester.pumpAndSettle();

          expect(find.text('¿Cerrar sesión?'), findsOneWidget);
          expect(tester.takeException(), isNull);
          expect(
            find.widgetWithText(FilledButton, 'Cerrar sesión'),
            findsOneWidget,
          );
          expect(textoProcesando, isNotEmpty);
        },
      );
    }
  });
}

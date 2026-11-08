import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/configuracion/entorno.dart';
import 'package:inversiones/core/errores/fallo_de_ingreso.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/auth/domain/resultado_de_ingreso.dart';
import 'package:inversiones/features/auth/presentation/pagina_de_ingreso.dart';
import 'package:inversiones/shared/widgets/botones.dart';

import '../falsos.dart';

/// En las pruebas `kIsWeb` es falso: la pantalla se comporta como en Android y
/// pide el ID del cliente Web de Google.
const _completo = Entorno(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseLlavePublicable: 'llave-publicable-de-prueba',
  googleWebClientId: 'cliente-web-de-prueba.apps.googleusercontent.com',
);

const _conModoPruebas = Entorno(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseLlavePublicable: 'llave-publicable-de-prueba',
  googleWebClientId: 'cliente-web-de-prueba.apps.googleusercontent.com',
  modoPruebas: true,
);

Future<void> _abrir(
  WidgetTester tester,
  IngresoRepositorioFalso repo, {
  Entorno entorno = _completo,
  bool oscuro = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        entornoProvider.overrideWithValue(entorno),
        ingresoRepositorioProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: oscuro ? crearTemaOscuro() : crearTema(),
        home: const PaginaDeIngreso(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _botonDeGoogle => find.byKey(PaginaDeIngreso.claveDelBotonDeGoogle);

FilledButton _filledDe(WidgetTester tester, Finder boton) =>
    tester.widget<FilledButton>(
      find.descendant(of: boton, matching: find.byType(FilledButton)),
    );

void main() {
  late IngresoRepositorioFalso repo;

  setUp(() => repo = IngresoRepositorioFalso());

  testWidgets('inactivo: título, ayuda y el botón de Google', (tester) async {
    await _abrir(tester, repo);

    expect(find.text('RiTech Inversiones'), findsOneWidget);
    expect(find.text('Entra con tu cuenta de Google'), findsOneWidget);
    expect(
      find.textContaining('Solo pueden entrar las personas'),
      findsOneWidget,
    );
    expect(find.text('Entrar con Google'), findsOneWidget);
    expect(find.byKey(PaginaDeIngreso.claveDelAvisoDeFallo), findsNothing);
    expect(
      find.byKey(PaginaDeIngreso.claveDelAvisoDeConfiguracion),
      findsNothing,
    );
    expect(_filledDe(tester, _botonDeGoogle).onPressed, isNotNull);
  });

  testWidgets('ningún texto habla de cuenta corporativa ni de RiTech', (
    tester,
  ) async {
    await _abrir(tester, repo, entorno: _conModoPruebas);

    final textos = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((t) => t != 'RiTech Inversiones')
        .join(' ')
        .toLowerCase();
    expect(textos, isNot(contains('corporativ')));
    expect(textos, isNot(contains('ritech')));
  });

  testWidgets(
    'al tocar, ingresa con Google y mientras tanto dice Procesando…',
    (tester) async {
      final respuesta = Completer<ResultadoDeIngreso>();
      repo.pendiente = respuesta;
      await _abrir(tester, repo);

      await tester.tap(_botonDeGoogle);
      await tester.pump();

      expect(repo.ingresosConGoogle, 1);
      expect(find.text(textoProcesando), findsOneWidget);
      expect(_filledDe(tester, _botonDeGoogle).onPressed, isNull);

      respuesta.complete(ResultadoDeIngreso.exito);
      await tester.pumpAndSettle();
      expect(find.text('Entrar con Google'), findsOneWidget);
      expect(find.byKey(PaginaDeIngreso.claveDelAvisoDeFallo), findsNothing);
    },
  );

  testWidgets('CA-4: si cierra la ventana de Google no hay mensaje', (
    tester,
  ) async {
    repo.resultado = ResultadoDeIngreso.cancelado;
    await _abrir(tester, repo);

    await tester.tap(_botonDeGoogle);
    await tester.pumpAndSettle();

    expect(find.byKey(PaginaDeIngreso.claveDelAvisoDeFallo), findsNothing);
    expect(find.text('Entrar con Google'), findsOneWidget);
    expect(_filledDe(tester, _botonDeGoogle).onPressed, isNotNull);
  });

  group('cada fallo muestra su texto exacto, sin detalle técnico (FR-022)', () {
    const casos = <(TipoDeFalloDeIngreso, String)>[
      (
        TipoDeFalloDeIngreso.sinInvitacion,
        'Tu correo no tiene una invitación vigente. Pídele una al administrador.',
      ),
      (
        TipoDeFalloDeIngreso.dominioNoPermitido,
        'Solo se admiten cuentas de Google invitadas.',
      ),
      (
        TipoDeFalloDeIngreso.proveedorNoPermitido,
        'Solo puedes ingresar con tu cuenta de Google.',
      ),
      (
        TipoDeFalloDeIngreso.cuentaSuspendida,
        'Tu cuenta está suspendida. Comunícate con el administrador.',
      ),
      (
        TipoDeFalloDeIngreso.sinConexion,
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
      ),
      (
        TipoDeFalloDeIngreso.inesperado,
        'No pudimos iniciar tu sesión. Inténtalo de nuevo.',
      ),
    ];

    for (final (tipo, texto) in casos) {
      testWidgets('$tipo', (tester) async {
        repo.error = FalloDeIngreso(tipo);
        await _abrir(tester, repo);

        await tester.tap(_botonDeGoogle);
        await tester.pumpAndSettle();

        expect(
          find.byKey(PaginaDeIngreso.claveDelAvisoDeFallo),
          findsOneWidget,
        );
        expect(find.text(texto), findsOneWidget);
        // El botón queda activo para reintentar.
        expect(_filledDe(tester, _botonDeGoogle).onPressed, isNotNull);
      });
    }
  });

  testWidgets('un rechazo del hook muestra el texto que mandó el servidor', (
    tester,
  ) async {
    repo.error = const FalloDeIngreso(
      TipoDeFalloDeIngreso.dominioNoPermitido,
      textoDelServidor: 'Solo se admiten cuentas con otra redacción.',
    );
    await _abrir(tester, repo);

    await tester.tap(_botonDeGoogle);
    await tester.pumpAndSettle();

    expect(
      find.text('Solo se admiten cuentas con otra redacción.'),
      findsOneWidget,
    );
  });

  testWidgets('CA-6: una excepción cualquiera no muestra su texto', (
    tester,
  ) async {
    repo.error = StateError('detalle técnico que no debe verse');
    await _abrir(tester, repo);

    await tester.tap(_botonDeGoogle);
    await tester.pumpAndSettle();

    expect(find.textContaining('detalle técnico'), findsNothing);
    expect(
      find.text('No pudimos iniciar tu sesión. Inténtalo de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('el fallo que llega al volver de Google (web) se muestra', (
    tester,
  ) async {
    await _abrir(tester, repo);

    repo.fallos.add(
      const FalloDeIngreso(TipoDeFalloDeIngreso.cuentaSuspendida),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Tu cuenta está suspendida. Comunícate con el administrador.'),
      findsOneWidget,
    );
  });

  testWidgets('un nuevo intento borra el aviso anterior', (tester) async {
    repo.error = const FalloDeIngreso(TipoDeFalloDeIngreso.sinConexion);
    await _abrir(tester, repo);
    await tester.tap(_botonDeGoogle);
    await tester.pumpAndSettle();
    expect(find.byKey(PaginaDeIngreso.claveDelAvisoDeFallo), findsOneWidget);

    repo.error = null;
    repo.pendiente = Completer<ResultadoDeIngreso>();
    await tester.tap(_botonDeGoogle);
    await tester.pump();

    expect(find.byKey(PaginaDeIngreso.claveDelAvisoDeFallo), findsNothing);
  });

  group('configuración que falta (solo desarrollo)', () {
    testWidgets('sin Supabase avisa y no deja ingresar', (tester) async {
      await _abrir(
        tester,
        repo,
        entorno: const Entorno(supabaseUrl: '', supabaseLlavePublicable: ''),
      );

      expect(
        find.byKey(PaginaDeIngreso.claveDelAvisoDeConfiguracion),
        findsOneWidget,
      );
      expect(find.text(textoSinConexionConfigurada), findsOneWidget);
      expect(_filledDe(tester, _botonDeGoogle).onPressed, isNull);
    });

    testWidgets('sin el cliente Web de Google avisa y no deja ingresar', (
      tester,
    ) async {
      await _abrir(
        tester,
        repo,
        entorno: const Entorno(
          supabaseUrl: 'http://127.0.0.1:54321',
          supabaseLlavePublicable: 'llave-publicable-de-prueba',
        ),
      );

      expect(find.text(textoSinGoogleConfigurado), findsOneWidget);
      expect(_filledDe(tester, _botonDeGoogle).onPressed, isNull);
    });
  });

  group('ingreso con correo, solo con MODO_PRUEBAS', () {
    testWidgets('sin MODO_PRUEBAS el formulario no existe', (tester) async {
      await _abrir(tester, repo);

      expect(
        find.byKey(PaginaDeIngreso.claveDelFormularioDePruebas),
        findsNothing,
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.text('SOLO PRUEBAS'), findsNothing);
      expect(find.text('Entrar con correo'), findsNothing);
    });

    testWidgets('con MODO_PRUEBAS ingresa con el correo y la contraseña', (
      tester,
    ) async {
      await _abrir(tester, repo, entorno: _conModoPruebas);

      expect(find.text('SOLO PRUEBAS'), findsOneWidget);
      final contrasena = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(PaginaDeIngreso.claveDeLaContrasena),
          matching: find.byType(TextField),
        ),
      );
      expect(contrasena.obscureText, isTrue);

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
      await tester.pumpAndSettle();

      expect(repo.ingresosConCorreo, [
        ('admin@prueba.local', 'prueba-local-1234'),
      ]);
      expect(repo.ingresosConGoogle, 0);
    });

    testWidgets('el fallo del ingreso con correo sale en el mismo aviso', (
      tester,
    ) async {
      repo.error = const FalloDeIngreso(TipoDeFalloDeIngreso.sinInvitacion);
      await _abrir(tester, repo, entorno: _conModoPruebas);

      await tester.ensureVisible(
        find.byKey(PaginaDeIngreso.claveDelBotonDeCorreo),
      );
      await tester.tap(find.byKey(PaginaDeIngreso.claveDelBotonDeCorreo));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Tu correo no tiene una invitación vigente. Pídele una al administrador.',
        ),
        findsOneWidget,
      );
    });
  });

  for (final oscuro in [false, true]) {
    testWidgets(
      'texto al doble en 360 dp, ${oscuro ? 'oscuro' : 'claro'}, sin desbordar',
      (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        repo.error = const FalloDeIngreso(TipoDeFalloDeIngreso.sinInvitacion);

        await _abrir(tester, repo, entorno: _conModoPruebas, oscuro: oscuro);
        // Con el texto al doble el botón queda bajo el pliegue: la pantalla se
        // desplaza hasta él.
        await tester.ensureVisible(_botonDeGoogle);
        await tester.tap(_botonDeGoogle);
        await tester.pumpAndSettle();

        expect(
          find.byKey(PaginaDeIngreso.claveDelAvisoDeFallo),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('en una ventana ancha la hoja no pasa de 420 dp', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _abrir(tester, repo);

    final hoja = tester.getSize(
      find
          .ancestor(
            of: find.text('Entra con tu cuenta de Google'),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(hoja.width, lessThanOrEqualTo(420));
  });
}

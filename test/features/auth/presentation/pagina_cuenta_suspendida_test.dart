import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/auth/presentation/pagina_cuenta_suspendida.dart';
import 'package:inversiones/shared/widgets/botones.dart';

import '../falsos.dart';

Future<void> _abrir(
  WidgetTester tester,
  IngresoRepositorioFalso repo, {
  bool oscuro = false,
  double textoEscala = 1,
  double ancho = 360,
}) async {
  tester.view.physicalSize = Size(ancho, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [ingresoRepositorioProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: oscuro ? crearTemaOscuro() : crearTema(),
        builder: (context, hijo) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textoEscala)),
          child: hijo!,
        ),
        home: const PaginaCuentaSuspendida(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _boton => find.byKey(PaginaCuentaSuspendida.claveDelBotonDeCierre);

OutlinedButton _outlined(WidgetTester tester) => tester.widget<OutlinedButton>(
  find.descendant(of: _boton, matching: find.byType(OutlinedButton)),
);

void main() {
  late IngresoRepositorioFalso repo;

  setUp(() => repo = IngresoRepositorioFalso());

  testWidgets(
    'CA-3: dice que la cuenta está suspendida con el texto de 04 §11',
    (tester) async {
      await _abrir(tester, repo);

      expect(find.text('Cuenta suspendida'), findsOneWidget);
      expect(
        find.text(
          'Tu cuenta está suspendida. Comunícate con el administrador.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cerrar sesión'), findsOneWidget);
    },
  );

  testWidgets('no tiene menú ni otra salida que cerrar la sesión', (
    tester,
  ) async {
    await _abrir(tester, repo);

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('cerrar la sesión la cierra y mientras tanto dice Procesando…', (
    tester,
  ) async {
    await _abrir(tester, repo);

    await tester.tap(_boton);
    await tester.pumpAndSettle();

    expect(repo.cierresDeSesion, 1);
  });

  testWidgets('mientras cierra el botón se deshabilita', (tester) async {
    final espera = Completer<void>();
    final lento = _RepositorioLento(espera.future);
    await _abrir(tester, lento);

    await tester.tap(_boton);
    await tester.pump();

    expect(find.text(textoProcesando), findsOneWidget);
    expect(_outlined(tester).onPressed, isNull);

    espera.complete();
    await tester.pumpAndSettle();
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(_outlined(tester).onPressed, isNotNull);
  });

  testWidgets(
    'si no puede cerrar, no muestra detalle técnico y deja reintentar',
    (tester) async {
      repo.error = StateError('detalle técnico que no debe verse');
      await _abrir(tester, repo);

      await tester.tap(_boton);
      await tester.pumpAndSettle();

      expect(find.textContaining('detalle técnico'), findsNothing);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(_outlined(tester).onPressed, isNotNull);
    },
  );

  for (final oscuro in [false, true]) {
    for (final ancho in [360.0, 1280.0]) {
      testWidgets(
        '${oscuro ? 'oscuro' : 'claro'} a ${ancho.toInt()} dp con el texto al doble, sin desbordar',
        (tester) async {
          await _abrir(
            tester,
            repo,
            oscuro: oscuro,
            textoEscala: 2,
            ancho: ancho,
          );

          expect(find.text('Cuenta suspendida'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

/// Un repositorio cuyo cierre de sesión espera a que la prueba lo libere.
class _RepositorioLento extends IngresoRepositorioFalso {
  _RepositorioLento(this._espera);

  final Future<void> _espera;

  @override
  Future<void> cerrarSesion() async {
    await _espera;
    cierresDeSesion++;
  }
}

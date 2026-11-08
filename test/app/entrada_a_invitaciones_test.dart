import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inversiones/app/aplicacion.dart';
import 'package:inversiones/app/enrutador.dart';
import 'package:inversiones/app/pagina_inicio.dart';
import 'package:inversiones/core/configuracion/entorno.dart';
import 'package:inversiones/features/admin/presentation/pagina_administracion.dart';
import 'package:inversiones/features/admin/usuarios/presentation/pagina_invitaciones.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';

import '../features/admin/usuarios/ayudas.dart';
import '../features/auth/falsos.dart';

const _entorno = Entorno(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseLlavePublicable: 'llave-publicable-de-prueba',
);

/// Abre la app completa con la sesión de [rol] y estado [estado].
Future<GoRouter> _abrir(
  WidgetTester tester, {
  String? rol,
  String? estado = 'activo',
}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        entornoProvider.overrideWithValue(_entorno),
        ingresoRepositorioProvider.overrideWithValue(
          IngresoRepositorioFalso()
            ..sesionActual = sesionDePrueba(rol: rol, estado: estado),
        ),
        ...overridesDe(RepositorioFalso()),
      ],
      child: const Aplicacion(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(Aplicacion)))
      .read(enrutadorProvider);
}

/// La ruta que se ve, también tras un `push` (que no actualiza el proveedor de
/// información de ruta).
String _ruta(GoRouter enrutador) =>
    enrutador.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('el Administrador llega a Invitaciones desde Administración', (
    tester,
  ) async {
    final enrutador = await _abrir(tester, rol: 'administrador');

    enrutador.go(Rutas.admin);
    await tester.pumpAndSettle();
    expect(find.byType(PaginaAdministracion), findsOneWidget);

    await tester.tap(find.byKey(claveDeEntradaAInvitaciones));
    await tester.pumpAndSettle();

    expect(_ruta(enrutador), Rutas.adminUsuarios);
    expect(find.byType(PaginaInvitaciones), findsOneWidget);
    expect(find.text('Invitar a una persona'), findsOneWidget);
  });

  testWidgets('la pantalla de inicio no trae la entrada a Invitaciones', (
    tester,
  ) async {
    await _abrir(tester, rol: 'administrador');

    expect(find.byType(PaginaInicio), findsOneWidget);
    expect(find.byKey(claveDeEntradaAInvitaciones), findsNothing);
  });

  testWidgets('/admin/usuarios abre las invitaciones y se vuelve con atrás', (
    tester,
  ) async {
    final enrutador = await _abrir(tester, rol: 'administrador');

    enrutador.go(Rutas.adminUsuarios);
    await tester.pumpAndSettle();
    expect(find.byType(PaginaInvitaciones), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(_ruta(enrutador), Rutas.admin);
    expect(find.byType(PaginaAdministracion), findsOneWidget);
  });

  for (final rol in ['usuario', 'analista']) {
    testWidgets('un $rol en /admin/usuarios vuelve al inicio (HU-006)', (
      tester,
    ) async {
      final enrutador = await _abrir(tester, rol: rol);

      for (final ruta in [Rutas.adminUsuarios, Rutas.admin]) {
        enrutador.go(ruta);
        await tester.pumpAndSettle();

        expect(_ruta(enrutador), Rutas.inicio, reason: ruta);
        expect(find.byType(PaginaInvitaciones), findsNothing, reason: ruta);
        expect(find.byKey(claveDeEntradaAInvitaciones), findsNothing);
      }
    });
  }

  testWidgets('una cuenta suspendida no llega a las invitaciones', (
    tester,
  ) async {
    final enrutador = await _abrir(
      tester,
      rol: 'administrador',
      estado: 'suspendido',
    );

    enrutador.go(Rutas.adminUsuarios);
    await tester.pumpAndSettle();

    expect(_ruta(enrutador), Rutas.cuentaSuspendida);
    expect(find.byType(PaginaInvitaciones), findsNothing);
  });
}

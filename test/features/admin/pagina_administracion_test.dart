import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/features/admin/data/fondo_repositorio.dart';
import 'package:inversiones/features/admin/presentation/guia_de_primeros_pasos.dart';
import 'package:inversiones/features/admin/presentation/pagina_administracion.dart';

class _FondoFalso implements FondoRepositorio {
  _FondoFalso(this.respuesta);

  Future<bool> Function() respuesta;
  int lecturas = 0;

  @override
  Future<bool> tieneCapital() {
    lecturas++;
    return respuesta();
  }
}

Future<void> _montar(WidgetTester tester, _FondoFalso fondo) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [fondoRepositorioProvider.overrideWithValue(fondo)],
      child: MaterialApp.router(
        theme: crearTema(),
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const PaginaAdministracion()),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra solo las entradas del MVP corto (CA-1)', (tester) async {
    await _montar(tester, _FondoFalso(() async => true));

    for (final titulo in [
      'Usuarios e invitaciones',
      'Capital',
      'Cupos',
      'Parámetros e interruptores',
    ]) {
      expect(find.text(titulo), findsOneWidget, reason: titulo);
    }
    for (final fueraDelMvp in [
      'Rebalanceos',
      'Lista blanca',
      'Salud e integraciones',
      'Bitácora',
      'Prompts',
    ]) {
      expect(find.text(fueraDelMvp), findsNothing, reason: fueraDelMvp);
    }
  });

  testWidgets('sin capital muestra la guía con sus cuatro pasos (CA-2)', (
    tester,
  ) async {
    await _montar(tester, _FondoFalso(() async => false));

    expect(find.byKey(claveDeGuiaDePrimerosPasos), findsOneWidget);
    expect(find.text('Fondo sin capital'), findsOneWidget);
    for (final paso in pasosDePrimerosPasos) {
      expect(find.text(paso.titulo), findsOneWidget, reason: paso.titulo);
    }
    expect(pasosDePrimerosPasos, hasLength(4));
  });

  testWidgets('con un aporte confirmado la guía no aparece (CA-3)', (
    tester,
  ) async {
    await _montar(tester, _FondoFalso(() async => true));

    expect(find.byKey(claveDeGuiaDePrimerosPasos), findsNothing);
    expect(find.text('Fondo sin capital'), findsNothing);
  });

  testWidgets('mientras lee y si la lectura falla no muestra la guía', (
    tester,
  ) async {
    final espera = Completer<bool>();
    final fondo = _FondoFalso(() => espera.future);
    await _montar(tester, fondo);
    // Aún sin respuesta (pumpAndSettle no espera a un Completer).
    expect(find.byKey(claveDeGuiaDePrimerosPasos), findsNothing);

    espera.completeError(StateError('sin conexión'));
    await tester.pumpAndSettle();
    expect(find.byKey(claveDeGuiaDePrimerosPasos), findsNothing);
    expect(find.text('Capital'), findsOneWidget);
  });

  testWidgets('las secciones sin pantalla quedan deshabilitadas', (
    tester,
  ) async {
    await _montar(tester, _FondoFalso(() async => true));

    // Invitaciones tiene pantalla; las demás aún no están registradas aquí.
    expect(find.text('Próximamente'), findsWidgets);
    expect(find.byKey(claveDeEntradaAInvitaciones), findsOneWidget);
  });
}

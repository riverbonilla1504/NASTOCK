import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/features/alertas/data/alertas_repositorio.dart';
import 'package:inversiones/features/alertas/domain/alerta.dart';
import 'package:inversiones/features/alertas/presentation/pagina_alertas.dart';
import 'package:inversiones/shared/widgets/estados.dart';

import '../../core/realtime/falsos.dart';

class _Repositorio implements AlertasRepositorio {
  _Repositorio(this.respuesta);
  final Future<List<Alerta>> Function() respuesta;
  @override
  Future<List<Alerta>> listar() => respuesta();
  @override
  Future<Alerta?> obtener(String id) async => null;
}

Future<void> montar(
  WidgetTester tester,
  Future<List<Alerta>> Function() respuesta, {
  double ancho = 360,
  bool oscuro = false,
  double escala = 1,
  bool esperar = true,
}) async {
  tester.view.physicalSize = Size(ancho, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...tiempoRealEnMemoria(),
        alertasRepositorioProvider.overrideWithValue(_Repositorio(respuesta)),
      ],
      child: MaterialApp(
        theme: oscuro ? crearTemaOscuro() : crearTema(),
        builder: (context, hijo) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(escala)),
          child: hijo!,
        ),
        home: const PaginaAlertas(),
      ),
    ),
  );
  if (esperar) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('vacío explica que solo muestra alertas activas', (tester) async {
    await montar(tester, () async => []);
    expect(find.text('No tienes alertas activas'), findsOneWidget);
  });
  testWidgets('carga sin inventar alertas y error con reintento', (
    tester,
  ) async {
    final respuesta = Completer<List<Alerta>>();
    await montar(tester, () => respuesta.future, esperar: false);
    expect(find.byType(EstadoCargando), findsOneWidget);
    respuesta.completeError(StateError('sin conexión'));
    await tester.pumpAndSettle();
    expect(find.byType(EstadoDeError), findsOneWidget);
  });
  for (final oscuro in [false, true]) {
    testWidgets('severidades legibles a 360dp y texto x2, oscuro=$oscuro', (
      tester,
    ) async {
      await montar(
        tester,
        () async => [
          for (final severidad in ['info', 'advertencia', 'critica'])
            Alerta(
              id: severidad,
              titulo: 'Aviso $severidad',
              cuerpo: 'La acción dejó de estar disponible.',
              severidad: severidad,
              creadaEn: DateTime.utc(2026, 11, 15),
            ),
        ],
        oscuro: oscuro,
        escala: 2,
      );
      expect(find.text('Aviso info'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

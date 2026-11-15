import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/features/ordenes/data/mis_ordenes_repositorio.dart';
import 'package:inversiones/features/ordenes/domain/mi_orden.dart';
import 'package:inversiones/features/ordenes/presentation/pagina_mis_ordenes.dart';

import '../../core/realtime/falsos.dart';

MiOrden orden({
  String estado = 'aceptada',
  bool pendiente = false,
  double llenada = 0,
}) => MiOrden(
  id: 'orden-1',
  simbolo: 'AAPL',
  lado: 'compra',
  estado: estado,
  cantidad: 2,
  llenada: llenada,
  retencion: 100,
  creadaEn: DateTime.utc(2026, 11, 15),
  cancelacionSolicitada: pendiente,
);

class _Repo implements MisOrdenesRepositorio {
  List<MiOrden> filas = [];
  int cancelaciones = 0;
  @override
  Future<List<MiOrden>> listar() async => filas;
  @override
  Future<MiOrden?> obtener(String id) async => filas.first;
  @override
  Future<void> cancelar(String id) async {
    cancelaciones++;
    filas = [orden(pendiente: true)];
  }
}

Future<void> _montar(WidgetTester tester, _Repo repo) async {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...tiempoRealEnMemoria(),
        misOrdenesRepositorioProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(theme: crearTema(), home: const PaginaMisOrdenes()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista vacía explica dónde aparecen las órdenes', (tester) async {
    await _montar(tester, _Repo());
    expect(find.text('Aún no tienes órdenes'), findsOneWidget);
  });
  testWidgets(
    'solicita tras confirmar y muestra pendiente sin cancelar falsamente',
    (tester) async {
      final repo = _Repo()..filas = [orden()];
      await _montar(tester, repo);
      await tester.tap(find.text('Cancelar orden'));
      await tester.pumpAndSettle();
      expect(repo.cancelaciones, 0);
      await tester.tap(find.text('Solicitar cancelación'));
      await tester.pumpAndSettle();
      expect(repo.cancelaciones, 1);
      expect(find.textContaining('Cancelación solicitada.'), findsOneWidget);
      expect(find.text('Cancelar orden'), findsNothing);
      expect(find.text('Aceptada'), findsOneWidget);
    },
  );
  testWidgets(
    'un llenado que gana informa el resultado y no permite cancelar',
    (tester) async {
      await _montar(
        tester,
        _Repo()
          ..filas = [orden(estado: 'llenada', pendiente: true, llenada: 2)],
      );
      expect(find.textContaining('se llenó antes'), findsOneWidget);
      expect(find.text('Cancelar orden'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'parcial muestra cantidad conservada y permite pedir cancelar el resto',
    (tester) async {
      await _montar(
        tester,
        _Repo()..filas = [orden(estado: 'parcialmente_llenada', llenada: 1)],
      );
      expect(find.text('Llenadas: 1.0 de 2.0'), findsOneWidget);
      expect(find.text('Cancelar orden'), findsOneWidget);
    },
  );
}

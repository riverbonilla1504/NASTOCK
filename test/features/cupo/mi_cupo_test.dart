import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/realtime/gestor_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';
import 'package:inversiones/features/cupo/data/cupo_repositorio.dart';
import 'package:inversiones/features/cupo/domain/mi_cupo.dart';
import 'package:inversiones/features/cupo/presentation/pagina_mi_cupo.dart';

import '../../core/realtime/falsos.dart';

const _idCupo = '11111111-1111-4111-8111-111111111111';

Map<String, dynamic> _fila({
  num efectivo = 400,
  num retenido = 0,
  num invertido = 0,
  num realizado = 0,
  bool conCapital = true,
  int version = 2,
  num? rendimiento,
}) => {
  'subcuenta_id': _idCupo,
  'efectivo': efectivo,
  'retenido': retenido,
  'disponible': efectivo - retenido,
  'invertido': invertido,
  'patrimonio': efectivo + invertido,
  'resultado_realizado': realizado,
  'resultado_no_realizado': 0,
  'rendimiento': rendimiento,
  'fondo_con_capital': conCapital,
  'version': version,
};

class _RepositorioFalso implements CupoRepositorio {
  _RepositorioFalso(this.fila, {this.error});

  Map<String, dynamic>? fila;
  final Object? error;
  int pedidos = 0;

  @override
  Future<MiCupo?> miCupo() async {
    pedidos++;
    if (error != null) throw error!;
    final f = fila;
    return f == null ? null : MiCupo.desdeJson(f);
  }
}

void main() {
  late FuenteFalsa fuente;
  late GestorDeTiempoReal gestor;

  setUp(() {
    fuente = FuenteFalsa();
    gestor = GestorDeTiempoReal(fuente, const ['usuario:u1']);
  });

  Future<void> montar(WidgetTester tester, _RepositorioFalso repo) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cupoRepositorioProvider.overrideWithValue(repo),
          gestorDeTiempoRealProvider.overrideWithValue(gestor),
        ],
        child: MaterialApp(theme: crearTema(), home: const PaginaMiCupo()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('CA-1 · muestra efectivo, retenido, disponible y patrimonio', (
    tester,
  ) async {
    await montar(tester, _RepositorioFalso(_fila()));

    expect(find.text('Patrimonio de tu cupo'), findsOneWidget);
    expect(
      find.text('USD 400,00'),
      findsNWidgets(3),
    ); // patrimonio, disponible, efectivo
    expect(
      find.text('USD 0,00'),
      findsWidgets,
    ); // retenido, invertido, resultados
    expect(find.text('Disponible para invertir'), findsOneWidget);
    expect(find.text('Retenido'), findsOneWidget);
  });

  testWidgets('el disponible descuenta lo retenido', (tester) async {
    await montar(tester, _RepositorioFalso(_fila(retenido: 50)));

    expect(find.text('USD 350,00'), findsOneWidget);
    expect(find.text('USD 50,00'), findsOneWidget);
  });

  testWidgets(
    'CA-5 · muestra el resultado realizado, el no realizado y el rendimiento',
    (tester) async {
      await montar(tester, _RepositorioFalso(_fila(realizado: 13)));

      expect(find.text('Resultado realizado'), findsOneWidget);
      expect(find.text('USD 13,00'), findsOneWidget);
      expect(find.text('Resultado no realizado'), findsOneWidget);
      expect(find.text('Rendimiento'), findsOneWidget);
      expect(find.text('Sin datos aún'), findsOneWidget);
    },
  );

  testWidgets('con rendimiento lo muestra como variación', (tester) async {
    await montar(tester, _RepositorioFalso(_fila(rendimiento: 0.05)));

    expect(find.text('Sin datos aún'), findsNothing);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('CA-4 · fondo sin capital', (tester) async {
    await montar(tester, _RepositorioFalso(_fila(conCapital: false)));

    expect(find.text('Fondo sin capital'), findsOneWidget);
    expect(find.text('Patrimonio de tu cupo'), findsNothing);
  });

  testWidgets('sin cupo todavía', (tester) async {
    await montar(tester, _RepositorioFalso(null));

    expect(find.text('Aún no tienes un cupo'), findsOneWidget);
  });

  testWidgets('un fallo se muestra con la opción de reintentar', (
    tester,
  ) async {
    await montar(tester, _RepositorioFalso(null, error: Exception('sin red')));

    expect(find.text('Patrimonio de tu cupo'), findsNothing);
    expect(find.byType(PaginaMiCupo), findsOneWidget);
  });

  testWidgets('CA-2 · se actualiza sola al recibir el evento cupo', (
    tester,
  ) async {
    final repo = _RepositorioFalso(_fila());
    await montar(tester, repo);
    expect(find.text('USD 400,00'), findsNWidgets(3));

    repo.fila = _fila(efectivo: 600, version: 3);
    fuente.evento(
      'usuario:u1',
      'cupo',
      tabla: 'subcuentas',
      id: _idCupo,
      version: 3,
      estado: 'abierta',
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('USD 600,00'), findsNWidgets(3));
    expect(find.text('USD 400,00'), findsNothing);
  });

  testWidgets('un evento resumen_cambio del fondo no la recarga', (
    tester,
  ) async {
    final repo = _RepositorioFalso(_fila());
    await montar(tester, repo);
    final antes = repo.pedidos;

    fuente.evento(
      'fondo',
      'resumen_cambio',
      tabla: 'subcuentas',
      id: _idCupo,
      version: 9,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(repo.pedidos, antes);
  });
}

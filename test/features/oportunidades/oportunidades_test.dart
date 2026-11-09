import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/features/oportunidades/data/oportunidades_repositorio.dart';
import 'package:inversiones/features/oportunidades/domain/oportunidad.dart';
import 'package:inversiones/features/oportunidades/presentation/pagina_oportunidades.dart';

class _RepositorioFalso implements OportunidadesRepositorio {
  _RepositorioFalso(this.filas, {this.error});

  final List<Map<String, dynamic>> filas;
  final Object? error;
  int pedidos = 0;

  @override
  Future<List<Oportunidad>> listar({BolsilloIa? bolsillo}) async {
    pedidos++;
    if (error != null) throw error!;
    return [for (final f in filas) Oportunidad.desdeJson(f)];
  }
}

Map<String, dynamic> _fila({
  String simbolo = 'NVDA',
  String bolsillo = 'arriesgadas',
  String resultado = 'elegida',
  double puntaje = 0.78,
  double? confianza = 0.81,
  String que = 'Recomendación: considerar comprar NVDA (horizonte: unos días).',
}) => {
  'ciclo_id': 'c1',
  'ciclo_terminado_en': DateTime.now()
      .subtract(const Duration(minutes: 3))
      .toUtc()
      .toIso8601String(),
  'bolsillo': bolsillo,
  'simbolo': simbolo,
  'tipo': 'entrada',
  'resultado': resultado,
  'calidad_datos': 'ok',
  'puntaje_cuantitativo': 0.9,
  'puntaje_compuesto': puntaje,
  'confianza': confianza,
  'estado_contexto': 'sin_contexto',
  'modelo_jev': 'jev-1.13.0',
  'aportes': {
    'Q': {'peso': 0.3, 'valor': 0.9, 'aporte': 0.27, 'neutral': false},
    'C': {'peso': 0.1, 'valor': 0.5, 'aporte': 0.05, 'neutral': true},
    'V': {'peso': 0.15, 'valor': 0.4, 'aporte': 0.06, 'neutral': false},
  },
  'metricas': {
    'rendimiento_20d': 0.0832,
    'volatilidad_20d': 0.42,
    'rsi_14': 61.2,
  },
  'explicacion': {
    'que': que,
    'por_que': ['Rendimiento frente al riesgo: rinde bien para el riesgo que asumió.'],
    'frena': ['Volatilidad: se mueve con fuerza.'],
    'advertencias': ['Sin contexto: no se leyeron noticias.'],
    'resumen': que,
  },
};

Future<void> _montar(WidgetTester tester, _RepositorioFalso repositorio) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [oportunidadesRepositorioProvider.overrideWithValue(repositorio)],
      child: MaterialApp(
        theme: crearTema(),
        home: const PaginaOportunidades(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra la candidata con puntaje, confianza y explicación', (
    tester,
  ) async {
    await _montar(tester, _RepositorioFalso([_fila()]));

    expect(find.text('NVDA'), findsOneWidget);
    expect(find.text('RECOMENDADA'), findsOneWidget);
    expect(find.text('0,78'), findsOneWidget);
    expect(find.text('81 %'), findsOneWidget);
    expect(find.textContaining('considerar comprar NVDA'), findsOneWidget);
    // Es una recomendación: no hay botón para aprobarla (D-65).
    expect(find.text('Aprobar'), findsNothing);
  });

  testWidgets('al tocar abre el detalle con por qué, qué la frena y advertencias', (
    tester,
  ) async {
    await _montar(tester, _RepositorioFalso([_fila()]));

    await tester.tap(find.text('NVDA'));
    await tester.pumpAndSettle();

    expect(find.text('Por qué'), findsOneWidget);
    expect(find.text('Qué la frena'), findsOneWidget);
    expect(find.text('Cómo se compone el puntaje'), findsOneWidget);
    expect(find.text('Contexto (neutro)'), findsOneWidget);
    expect(find.textContaining('Sin contexto: no se leyeron noticias'), findsOneWidget);
    expect(find.text('Modelo: jev-1.13.0'), findsOneWidget);
    expect(find.text('Rendimiento a 20 días: +8,32 %'), findsOneWidget);
  });

  testWidgets('sin evaluaciones muestra el estado vacío', (tester) async {
    await _montar(tester, _RepositorioFalso([]));

    expect(find.text('Aún no hay evaluaciones'), findsOneWidget);
  });

  testWidgets('un error muestra el aviso y permite reintentar', (tester) async {
    final repositorio = _RepositorioFalso([], error: Exception('falló'));
    await _montar(tester, repositorio);

    expect(find.text('Reintentar'), findsOneWidget);
    final antes = repositorio.pedidos;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repositorio.pedidos, greaterThan(antes));
  });

  testWidgets('con dos bolsillos ofrece el selector y filtra la lista', (
    tester,
  ) async {
    await _montar(
      tester,
      _RepositorioFalso([
        _fila(simbolo: 'NVDA'),
        _fila(
          simbolo: 'QQQ',
          bolsillo: 'usuarios',
          resultado: 'no_elegible:espera',
          que: 'No se recomienda comprar QQQ por ahora.',
        ),
      ]),
    );

    expect(find.text('NVDA'), findsOneWidget);
    expect(find.text('QQQ'), findsNothing);

    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();

    expect(find.text('QQQ'), findsOneWidget);
    expect(find.text('SIN RECOMENDAR'), findsOneWidget);
    expect(find.text('NVDA'), findsNothing);
  });

  testWidgets('las excluidas se listan aparte con su motivo', (tester) async {
    await _montar(
      tester,
      _RepositorioFalso([
        _fila(),
        _fila(
          simbolo: 'XYZ',
          resultado: 'excluida:datos_viejos',
          que: 'XYZ quedó fuera de este ciclo: datos viejos.',
        )..['puntaje_compuesto'] = null,
      ]),
    );

    expect(find.text('Excluidas por la calidad de sus datos'), findsOneWidget);
    expect(find.textContaining('XYZ quedó fuera de este ciclo'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/errores/traduccion_de_errores.dart';
import 'package:inversiones/core/realtime/gestor_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';
import 'package:inversiones/features/admin/cupos/data/cupos_repositorio.dart';
import 'package:inversiones/features/admin/cupos/domain/subcuenta_de_cupo.dart';
import 'package:inversiones/features/admin/cupos/presentation/formulario_de_movimiento_de_cupo.dart';
import 'package:inversiones/features/admin/cupos/presentation/pagina_cupos.dart';
import 'package:inversiones/shared/widgets/dialogo_de_confirmacion.dart';

import '../../../core/realtime/falsos.dart';

const _bolsaId = 'bolsa-1';

Map<String, dynamic> _bolsa({num efectivo = 2500, int version = 1}) => {
  'id': _bolsaId,
  'tipo': 'usuarios_comun',
  'usuario_id': null,
  'efectivo': efectivo,
  'retenido': 0,
  'invertido': 0,
  'version': version,
  'perfiles': null,
};

Map<String, dynamic> _cupo(
  String usuario,
  String nombre, {
  num efectivo = 400,
  num retenido = 0,
  num invertido = 0,
  int version = 1,
}) => {
  'id': 'cupo-$usuario',
  'tipo': 'cupo',
  'usuario_id': usuario,
  'efectivo': efectivo,
  'retenido': retenido,
  'invertido': invertido,
  'version': version,
  'perfiles': {'nombre': nombre, 'email': '$usuario@gmail.com'},
};

class _RepositorioFalso implements CuposRepositorio {
  _RepositorioFalso(this.filas, {this.error});

  List<Map<String, dynamic>> filas;
  Object? error;
  final List<String> llamadas = [];

  @override
  Future<List<SubcuentaDeCupo>> listar() async => [
    for (final f in filas) SubcuentaDeCupo.desdeJson(f),
  ];

  @override
  Future<SubcuentaDeCupo?> una(String id) async {
    for (final f in filas) {
      if (f['id'] == id) return SubcuentaDeCupo.desdeJson(f);
    }
    return null;
  }

  @override
  Future<void> asignar(String usuarioId, double monto) async {
    llamadas.add('asignar $usuarioId $monto');
    if (error != null) throw error!;
  }

  @override
  Future<void> reducir(String usuarioId, double monto) async {
    llamadas.add('reducir $usuarioId $monto');
    if (error != null) throw error!;
  }
}

void main() {
  late FuenteFalsa fuente;
  late GestorDeTiempoReal gestor;

  setUp(() {
    fuente = FuenteFalsa();
    gestor = GestorDeTiempoReal(fuente, const ['fondo']);
  });

  Future<void> montar(WidgetTester tester, _RepositorioFalso repo) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cuposRepositorioProvider.overrideWithValue(repo),
          gestorDeTiempoRealProvider.overrideWithValue(gestor),
        ],
        child: MaterialApp(theme: crearTema(), home: const PaginaCupos()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> abrirFormulario(
    WidgetTester tester,
    Key boton,
    String monto,
  ) async {
    await tester.tap(find.byKey(boton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(FormularioDeMovimientoDeCupo.claveDelMonto),
        matching: find.byType(TextField),
      ),
      monto,
    );
    await tester.tap(find.byKey(FormularioDeMovimientoDeCupo.claveDelBoton));
    await tester.pumpAndSettle();
  }

  Finder enElDialogo(Finder f) =>
      find.descendant(of: find.byType(DialogoDeConfirmacion), matching: f);

  testWidgets('CA-1 · muestra la bolsa común y cada cupo con sus cifras', (
    tester,
  ) async {
    await montar(
      tester,
      _RepositorioFalso([
        _cupo('u2', 'Zoe Vega', efectivo: 100),
        _bolsa(),
        _cupo('u1', 'Ana Ríos', efectivo: 400, retenido: 50, invertido: 110.2),
      ]),
    );

    expect(find.text('Bolsa común de Usuarios'), findsOneWidget);
    expect(find.text('USD 2.500,00'), findsOneWidget);
    expect(find.text('Ana Ríos'), findsOneWidget);
    expect(find.text('ana@gmail.com'), findsNothing);
    expect(find.text('u1@gmail.com'), findsOneWidget);
    // Efectivo 400, disponible 350 y patrimonio 510,20 del cupo de Ana.
    expect(find.text('USD 400,00'), findsOneWidget);
    expect(find.text('USD 350,00'), findsOneWidget);
    expect(find.text('USD 510,20'), findsOneWidget);
    // Orden alfabético: Ana antes que Zoe.
    expect(
      tester.getTopLeft(find.text('Ana Ríos')).dy,
      lessThan(tester.getTopLeft(find.text('Zoe Vega')).dy),
    );
  });

  testWidgets('sin cupos explica de dónde salen', (tester) async {
    await montar(tester, _RepositorioFalso([_bolsa()]));

    expect(find.text('Aún no hay cupos'), findsOneWidget);
  });

  testWidgets('CA-2 · asignar pide confirmación y llama a la RPC', (
    tester,
  ) async {
    final repo = _RepositorioFalso([_bolsa(), _cupo('u1', 'Ana Ríos')]);
    await montar(tester, repo);

    await abrirFormulario(tester, claveDeAsignar('u1'), '150,50');
    expect(find.byType(DialogoDeConfirmacion), findsOneWidget);
    expect(enElDialogo(find.text('USD 150,50')), findsWidgets);
    expect(repo.llamadas, isEmpty, reason: 'nada se envía sin confirmar');

    await tester.tap(enElDialogo(find.text('Asignar')));
    await tester.pumpAndSettle();

    expect(repo.llamadas, ['asignar u1 150.5']);
    expect(find.byType(DialogoDeConfirmacion), findsNothing);
    expect(find.byType(FormularioDeMovimientoDeCupo), findsNothing);
  });

  testWidgets('CA-2 · reducir llama a la RPC de reducción', (tester) async {
    final repo = _RepositorioFalso([_bolsa(), _cupo('u1', 'Ana Ríos')]);
    await montar(tester, repo);

    await abrirFormulario(tester, claveDeReducir('u1'), '20');
    await tester.tap(enElDialogo(find.text('Reducir')));
    await tester.pumpAndSettle();

    expect(repo.llamadas, ['reducir u1 20.0']);
  });

  testWidgets('CA-2 · FONDOS_INSUFICIENTES se muestra y se puede cancelar', (
    tester,
  ) async {
    final repo = _RepositorioFalso([
      _bolsa(),
      _cupo('u1', 'Ana Ríos'),
    ], error: const ErrorDeNegocio('FONDOS_INSUFICIENTES'));
    await montar(tester, repo);

    await abrirFormulario(tester, claveDeAsignar('u1'), '9999');
    await tester.tap(enElDialogo(find.text('Asignar')));
    await tester.pumpAndSettle();

    expect(find.text(traducirCodigo('FONDOS_INSUFICIENTES')), findsOneWidget);
    expect(find.byType(DialogoDeConfirmacion), findsOneWidget);
  });

  testWidgets('CA-2 · CUPO_SUPERA_MAXIMO se muestra', (tester) async {
    final repo = _RepositorioFalso([
      _bolsa(),
      _cupo('u1', 'Ana Ríos'),
    ], error: const ErrorDeNegocio('CUPO_SUPERA_MAXIMO'));
    await montar(tester, repo);

    await abrirFormulario(tester, claveDeAsignar('u1'), '600');
    await tester.tap(enElDialogo(find.text('Asignar')));
    await tester.pumpAndSettle();

    expect(find.text(traducirCodigo('CUPO_SUPERA_MAXIMO')), findsOneWidget);
  });

  testWidgets('un monto inválido no abre la confirmación', (tester) async {
    final repo = _RepositorioFalso([_bolsa(), _cupo('u1', 'Ana Ríos')]);
    await montar(tester, repo);

    for (final monto in ['', '0', 'abc', '1,234']) {
      await abrirFormulario(tester, claveDeAsignar('u1'), monto);
      expect(find.byType(DialogoDeConfirmacion), findsNothing, reason: monto);
      expect(find.textContaining('Escribe un monto'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10)); // cierra la hoja
      await tester.pumpAndSettle();
    }
    expect(repo.llamadas, isEmpty);
  });

  testWidgets('CA-3 · se actualiza sola al llegar un evento de saldo', (
    tester,
  ) async {
    final repo = _RepositorioFalso([_bolsa(), _cupo('u1', 'Ana Ríos')]);
    await montar(tester, repo);
    expect(find.text('USD 2.500,00'), findsOneWidget);

    repo.filas = [_bolsa(efectivo: 2100, version: 2), _cupo('u1', 'Ana Ríos')];
    fuente.evento(
      'fondo',
      'resumen_cambio',
      tabla: 'subcuentas',
      id: _bolsaId,
      version: 2,
      estado: 'abierta',
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('USD 2.100,00'), findsOneWidget);
    expect(find.text('USD 2.500,00'), findsNothing);
  });

  testWidgets('un fallo de la foto se muestra con reintento', (tester) async {
    final repo = _RepositorioFalso([]);
    await montar(tester, repo);
    expect(find.text('Aún no hay cupos'), findsOneWidget);
  });
}

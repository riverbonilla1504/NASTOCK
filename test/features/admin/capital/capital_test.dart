import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/realtime/gestor_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';
import 'package:inversiones/features/admin/capital/data/capital_repositorio.dart';
import 'package:inversiones/features/admin/capital/domain/movimiento_de_capital.dart';
import 'package:inversiones/features/admin/capital/presentation/capital_provider.dart';
import 'package:inversiones/features/admin/capital/presentation/formulario_de_aporte.dart';
import 'package:inversiones/features/admin/capital/presentation/lista_de_aportes.dart';
import 'package:inversiones/features/admin/capital/presentation/pagina_capital.dart';

import '../../../core/realtime/falsos.dart';

MovimientoDeCapital aporte({
  String id = 'a1',
  double monto = 10000,
  EstadoMovCapital estado = EstadoMovCapital.registrado,
  String? referencia = 'paper-inicial',
  String? motivo,
}) => MovimientoDeCapital(
  id: id,
  tipo: 'aporte',
  monto: monto,
  estado: estado,
  referencia: referencia,
  registradoPor: 'Ana Admin',
  registradoEn: DateTime.utc(2026, 11, 9, 15),
  confirmadoEn: estado == EstadoMovCapital.confirmado
      ? DateTime.utc(2026, 11, 9, 15, 5)
      : null,
  anuladoEn: estado == EstadoMovCapital.anulado
      ? DateTime.utc(2026, 11, 9, 15, 5)
      : null,
  motivoAnulacion: motivo,
);

class CapitalFalso implements CapitalRepositorio {
  CapitalFalso([List<MovimientoDeCapital> aportes = const []])
    : aportes = [...aportes];

  List<MovimientoDeCapital> aportes;
  Object? errorAlListar;
  Object? errorAlRegistrar;
  Object? errorAlAnular;
  int listados = 0;
  final List<({double monto, String? referencia, String? nota})> registrados =
      [];
  final List<({String id, String motivo})> anulados = [];

  @override
  Future<List<MovimientoDeCapital>> listarAportes() async {
    listados++;
    if (errorAlListar != null) throw errorAlListar!;
    return [...aportes];
  }

  @override
  Future<MovimientoDeCapital> registrar({
    required double monto,
    String? referencia,
    String? nota,
  }) async {
    if (errorAlRegistrar != null) throw errorAlRegistrar!;
    registrados.add((monto: monto, referencia: referencia, nota: nota));
    final nuevo = aporte(id: 'n${registrados.length}', monto: monto);
    aportes = [nuevo, ...aportes];
    return nuevo;
  }

  @override
  Future<MovimientoDeCapital> anular({
    required String id,
    required String motivo,
  }) async {
    if (errorAlAnular != null) throw errorAlAnular!;
    anulados.add((id: id, motivo: motivo));
    aportes = [
      for (final a in aportes)
        if (a.id == id)
          aporte(
            id: id,
            monto: a.monto,
            estado: EstadoMovCapital.anulado,
            motivo: motivo,
          )
        else
          a,
    ];
    return aportes.firstWhere((a) => a.id == id);
  }
}

Future<void> montar(
  WidgetTester tester,
  CapitalFalso repo, {
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [capitalRepositorioProvider.overrideWithValue(repo), ...extra],
      child: MaterialApp(theme: crearTema(), home: const PaginaCapital()),
    ),
  );
  await tester.pumpAndSettle();
}

/// El botón de confirmar del diálogo (el de la página lleva el mismo texto).
Finder _botonDelDialogo() => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.text(textoRegistrarAporte),
);

void main() {
  group('MovimientoDeCapital', () {
    test('lee la fila con el nombre de quien registró', () {
      final m = MovimientoDeCapital.desdeJson({
        'id': 'x',
        'tipo': 'aporte',
        'monto': 10000,
        'estado': 'registrado',
        'referencia_externa': 'paper-inicial',
        'nota': null,
        'registrado_en': '2026-11-09T15:00:00+00:00',
        'confirmado_en': null,
        'anulado_en': null,
        'motivo_anulacion': null,
        'registrador': {'nombre': 'Ana Admin'},
      });
      expect(m.monto, 10000);
      expect(m.registradoPor, 'Ana Admin');
      expect(m.sePuedeAnular, isTrue);
    });

    test('lo que devuelve una RPC no trae registrador', () {
      final m = MovimientoDeCapital.desdeJson({
        'id': 'x',
        'tipo': 'aporte',
        'monto': 1000.03,
        'estado': 'confirmado',
        'registrado_en': '2026-11-09T15:00:00+00:00',
        'confirmado_en': '2026-11-09T15:05:00+00:00',
      });
      expect(m.registradoPor, isNull);
      expect(m.sePuedeAnular, isFalse);
    });

    test('un estado desconocido falla en vez de inventar', () {
      expect(
        () => MovimientoDeCapital.desdeJson({
          'id': 'x',
          'tipo': 'aporte',
          'monto': 1,
          'estado': 'raro',
          'registrado_en': '2026-11-09T15:00:00+00:00',
        }),
        throwsFormatException,
      );
    });
  });

  group('lista', () {
    testWidgets('muestra monto, referencia, estado y quién registró (CA-1)', (
      tester,
    ) async {
      await montar(
        tester,
        CapitalFalso([
          aporte(),
          aporte(
            id: 'a2',
            monto: 500,
            estado: EstadoMovCapital.confirmado,
            referencia: null,
          ),
        ]),
      );

      expect(find.text('USD 10.000,00'), findsOneWidget);
      expect(find.textContaining('Ref. paper-inicial'), findsOneWidget);
      expect(find.textContaining('por Ana Admin'), findsNWidgets(2));
      expect(find.text('Registrado'), findsOneWidget);
      expect(find.text('Confirmado'), findsOneWidget);
    });

    testWidgets('sin aportes muestra el vacío', (tester) async {
      await montar(tester, CapitalFalso());
      expect(find.byKey(ListaDeAportes.claveDelVacio), findsOneWidget);
    });

    testWidgets('si la lectura falla muestra el error con reintento', (
      tester,
    ) async {
      final repo = CapitalFalso()..errorAlListar = StateError('sin conexión');
      await montar(tester, repo);
      expect(find.byKey(ListaDeAportes.claveDelError), findsOneWidget);
    });

    testWidgets('solo un aporte registrado ofrece anular (CA-3)', (
      tester,
    ) async {
      await montar(
        tester,
        CapitalFalso([
          aporte(),
          aporte(id: 'a2', estado: EstadoMovCapital.confirmado),
          aporte(id: 'a3', estado: EstadoMovCapital.anulado, motivo: 'error'),
        ]),
      );
      expect(find.text('Anular'), findsOneWidget);
      expect(find.text('Motivo: error'), findsOneWidget);
    });

    testWidgets('anular pide el motivo y lo envía', (tester) async {
      final repo = CapitalFalso([aporte()]);
      await montar(tester, repo);

      await tester.tap(find.text('Anular'));
      await tester.pumpAndSettle();
      // Sin motivo no avanza.
      await tester.tap(find.text('Anular aporte'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe el motivo de la anulación.'), findsOneWidget);
      expect(repo.anulados, isEmpty);

      await tester.enterText(
        find.byKey(ListaDeAportes.claveDelMotivo),
        'Monto equivocado',
      );
      await tester.tap(find.text('Anular aporte'));
      await tester.pumpAndSettle();

      expect(repo.anulados, [(id: 'a1', motivo: 'Monto equivocado')]);
      expect(find.text('Anulado'), findsOneWidget);
      expect(find.text('Anular'), findsNothing);
    });

    testWidgets('cancelar la anulación no envía nada', (tester) async {
      final repo = CapitalFalso([aporte()]);
      await montar(tester, repo);
      await tester.tap(find.text('Anular'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.anulados, isEmpty);
    });

    testWidgets('si la anulación falla muestra el error traducido', (
      tester,
    ) async {
      final repo = CapitalFalso([aporte()])
        ..errorAlAnular = Exception('ESTADO_INVALIDO');
      await montar(tester, repo);
      await tester.tap(find.text('Anular'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ListaDeAportes.claveDelMotivo), 'x');
      await tester.tap(find.text('Anular aporte'));
      await tester.pumpAndSettle();
      expect(repo.listados, greaterThan(1), reason: 'recarga igual');
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('formulario', () {
    testWidgets('un monto mal escrito o en cero no abre la confirmación', (
      tester,
    ) async {
      final repo = CapitalFalso();
      await montar(tester, repo);

      for (final malo in ['', 'abc', '0', '10.005']) {
        await tester.enterText(
          find.byKey(FormularioDeAporte.claveDelMonto),
          malo,
        );
        await tester.tap(find.text(textoRegistrarAporte));
        await tester.pumpAndSettle();
        expect(
          find.text('¿Registrar este aporte?'),
          findsNothing,
          reason: malo,
        );
      }
      expect(repo.registrados, isEmpty);
    });

    testWidgets(
      'registra tras confirmar y el aporte aparece registrado (CA-2)',
      (tester) async {
        final repo = CapitalFalso();
        await montar(tester, repo);

        await tester.enterText(
          find.byKey(FormularioDeAporte.claveDelMonto),
          '10000',
        );
        await tester.enterText(
          find.byKey(FormularioDeAporte.claveDeLaReferencia),
          'paper-inicial',
        );
        await tester.tap(find.text(textoRegistrarAporte));
        await tester.pumpAndSettle();

        expect(find.text('¿Registrar este aporte?'), findsOneWidget);
        expect(repo.registrados, isEmpty, reason: 'aún sin confirmar');
        await tester.tap(_botonDelDialogo());
        await tester.pumpAndSettle();

        expect(repo.registrados, [
          (monto: 10000.0, referencia: 'paper-inicial', nota: null),
        ]);
        expect(
          find.byKey(FormularioDeAporte.claveDelAvisoDeRegistrado),
          findsOneWidget,
        );
        expect(find.text('Registrado'), findsOneWidget);
      },
    );

    testWidgets('cancelar la confirmación no registra', (tester) async {
      final repo = CapitalFalso();
      await montar(tester, repo);
      await tester.enterText(
        find.byKey(FormularioDeAporte.claveDelMonto),
        '50,5',
      );
      await tester.tap(find.text(textoRegistrarAporte));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.registrados, isEmpty);
    });

    testWidgets('si la RPC falla el diálogo muestra el error', (tester) async {
      final repo = CapitalFalso()
        ..errorAlRegistrar = Exception('NO_AUTORIZADO');
      await montar(tester, repo);
      await tester.enterText(
        find.byKey(FormularioDeAporte.claveDelMonto),
        '100',
      );
      await tester.tap(find.text(textoRegistrarAporte));
      await tester.pumpAndSettle();
      await tester.tap(_botonDelDialogo());
      await tester.pumpAndSettle();
      expect(find.text('¿Registrar este aporte?'), findsOneWidget);
      expect(repo.registrados, isEmpty);
      expect(
        find.byKey(FormularioDeAporte.claveDelAvisoDeRegistrado),
        findsNothing,
      );
    });
  });

  group('tiempo real', () {
    testWidgets('el evento capital confirma el aporte sin recargar (CA-2)', (
      tester,
    ) async {
      final repo = CapitalFalso([aporte()]);
      final fuente = FuenteFalsa();
      final gestor = GestorDeTiempoReal(fuente, ['admin']);
      addTearDown(gestor.cerrar);
      await montar(
        tester,
        repo,
        extra: [gestorDeTiempoRealProvider.overrideWithValue(gestor)],
      );
      expect(find.text('Registrado'), findsOneWidget);
      expect(find.text('Anular'), findsOneWidget);

      // La conciliación confirma el aporte; la base publica el evento.
      repo.aportes = [aporte(estado: EstadoMovCapital.confirmado)];
      fuente.evento(
        'admin',
        'capital',
        tabla: 'movimientos_capital',
        id: 'a1',
        estado: 'confirmado',
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.text('Anular'), findsNothing);
    });

    testWidgets('un evento de otro canal o de otro nombre se ignora', (
      tester,
    ) async {
      final repo = CapitalFalso([aporte()]);
      final fuente = FuenteFalsa();
      final gestor = GestorDeTiempoReal(fuente, ['admin', 'supervision']);
      addTearDown(gestor.cerrar);
      await montar(
        tester,
        repo,
        extra: [gestorDeTiempoRealProvider.overrideWithValue(gestor)],
      );
      final antes = repo.listados;
      fuente.evento('admin', 'invitacion', tabla: 'invitaciones', id: 'i');
      fuente.evento(
        'supervision',
        'conciliacion',
        tabla: 'conciliaciones',
        id: 'c',
      );
      await tester.pumpAndSettle();
      expect(repo.listados, antes);
    });
  });

  test('aportesProvider carga la foto', () async {
    final repo = CapitalFalso([aporte()]);
    final contenedor = ProviderContainer(
      overrides: [capitalRepositorioProvider.overrideWithValue(repo)],
    );
    addTearDown(contenedor.dispose);
    expect((await contenedor.read(aportesProvider.future)).single.id, 'a1');
  });
}

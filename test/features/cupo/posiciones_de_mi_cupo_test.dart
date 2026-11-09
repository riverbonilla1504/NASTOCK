import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/formato/formato_dinero.dart';
import 'package:inversiones/features/cupo/data/cupo_repositorio.dart';
import 'package:inversiones/features/cupo/domain/mi_cupo.dart';
import 'package:inversiones/features/cupo/domain/posicion.dart';
import 'package:inversiones/features/cupo/presentation/pagina_mi_cupo.dart';
import 'package:inversiones/features/cupo/presentation/tarjeta_de_posicion.dart';
import 'package:inversiones/features/mercado/data/mercado_repositorio.dart';
import 'package:inversiones/core/realtime/gestor_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/canales.dart';
import 'package:inversiones/core/realtime/fuente_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/reloj.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/shared/widgets/estados.dart';

import '../../core/realtime/falsos.dart';
import '../mercado/ayudas.dart';

const _idCupo = '11111111-1111-4111-8111-111111111111';

Map<String, dynamic> _fila() => {
  'subcuenta_id': _idCupo,
  'efectivo': 400,
  'retenido': 0,
  'disponible': 400,
  'invertido': 1000,
  'patrimonio': 1400,
  'resultado_realizado': 0,
  'resultado_no_realizado': 0,
  'rendimiento': null,
  'fondo_con_capital': true,
  'version': 2,
};

PosicionDeCupo _posicion(
  String id,
  String simbolo, {
  double cantidad = 10,
  double costoPromedio = 100,
  ProteccionDePosicion? proteccion,
}) => PosicionDeCupo(
  id: id,
  simbolo: simbolo,
  cantidad: cantidad,
  costoPromedio: costoPromedio,
  costoTotal: cantidad * costoPromedio,
  resultadoRealizado: 0,
  version: 1,
  proteccion: proteccion,
);

const _proteccion = ProteccionDePosicion(
  id: 'pr1',
  tipo: 'nativa',
  estado: 'activa',
  stopPrecio: 95,
  objetivoPrecio: 130,
);

class _Repo implements CupoRepositorio {
  _Repo(this.posicionesDelCupo);

  List<PosicionDeCupo> posicionesDelCupo;
  Object? errorAlLeer;
  final List<String> pedidas = [];

  @override
  Future<MiCupo?> miCupo() async => MiCupo.desdeJson(_fila());

  @override
  Future<List<PosicionDeCupo>> posiciones(String idCupo) async {
    pedidas.add(idCupo);
    if (errorAlLeer != null) throw errorAlLeer!;
    return posicionesDelCupo;
  }
}

void main() {
  late FuenteFalsa fuente;

  setUp(() => fuente = FuenteFalsa());

  Future<void> montar(
    WidgetTester tester,
    _Repo repo, {
    MercadoRepositorioFalso? mercado,
    bool oscuro = false,
    double textoEscala = 1,
    double ancho = 360,
  }) async {
    tester.view.physicalSize = Size(ancho, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textoEscala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cupoRepositorioProvider.overrideWithValue(repo),
          mercadoRepositorioProvider.overrideWithValue(
            mercado ?? MercadoRepositorioFalso(),
          ),
          fuenteDeTiempoRealProvider.overrideWithValue(fuente),
          gestorDeTiempoRealProvider.overrideWith((ref) {
            final gestor = GestorDeTiempoReal(
              fuente,
              canalesDeRol(RolApp.usuario, 'usuario-1'),
            );
            ref.onDispose(gestor.cerrar);
            return gestor;
          }),
          relojRepositorioProvider.overrideWithValue(
            RelojRepositorioFalso(() => ahoraDePrueba),
          ),
          ahoraLocalProvider.overrideWithValue(() => ahoraDePrueba),
        ],
        child: MaterialApp(
          theme: oscuro ? crearTemaOscuro() : crearTema(),
          home: const PaginaMiCupo(),
        ),
      ),
    );
    await asentar(tester);
  }

  group('posiciones en Mi cupo', () {
    testWidgets(
      'CA-1: cantidad, costo promedio, precio, valor y resultado no realizado',
      (tester) async {
        await montar(tester, _Repo([_posicion('p1', 'QLD')]));

        expect(find.text('Posiciones'), findsOneWidget);
        expect(find.text('QLD'), findsOneWidget);
        expect(find.text('10'), findsOneWidget); // cantidad
        expect(find.text('Costo promedio'), findsOneWidget);
        expect(find.text(formatearUsd(100)), findsOneWidget);
        // Precio de la foto: QLD 110,25 → valor 1.102,50 y no realizado 102,50.
        expect(find.text(formatearUsd(110.25)), findsOneWidget);
        expect(find.text(formatearUsd(1102.5)), findsOneWidget);
        expect(find.text(formatearUsd(102.5)), findsOneWidget);
        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
        // La antigüedad del precio.
        expect(find.textContaining('hace'), findsOneWidget);
      },
    );

    testWidgets('una pérdida baja con su flecha y su signo', (tester) async {
      final mercado = MercadoRepositorioFalso(
        cotizaciones: [cotizacion('QLD', 90)],
      );
      await montar(tester, _Repo([_posicion('p1', 'QLD')]), mercado: mercado);

      expect(find.text(formatearUsd(-100)), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets(
      'CA-2: un precio nuevo cambia el valor y la ganancia en pantalla',
      (tester) async {
        await montar(tester, _Repo([_posicion('p1', 'QLD')]));
        expect(find.text(formatearUsd(1102.5)), findsOneWidget);

        fuente.crudo('mercado', 'cotizaciones', {
          'momento': ahoraDePrueba.toIso8601String(),
          'datos': [
            {'s': 'QLD', 'p': 120.0},
          ],
        });
        await asentar(tester);

        expect(find.text(formatearUsd(1102.5)), findsNothing);
        expect(find.text(formatearUsd(1200)), findsOneWidget);
        expect(find.text(formatearUsd(200)), findsOneWidget);
      },
    );

    testWidgets('CA-3: la protección con su tipo, estado, stop y objetivo', (
      tester,
    ) async {
      await montar(
        tester,
        _Repo([_posicion('p1', 'QLD', proteccion: _proteccion)]),
      );

      expect(find.text('Protección nativa'), findsOneWidget);
      expect(find.text('ACTIVA'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text(formatearUsd(95)), findsOneWidget);
      expect(find.text('Objetivo'), findsOneWidget);
      expect(find.text(formatearUsd(130)), findsOneWidget);
    });

    testWidgets('sin objetivo lo dice y una protección pendiente lo marca', (
      tester,
    ) async {
      const sinObjetivo = ProteccionDePosicion(
        id: 'pr2',
        tipo: 'nativa',
        estado: 'pendiente',
        stopPrecio: 95,
      );
      await montar(
        tester,
        _Repo([_posicion('p1', 'QLD', proteccion: sinObjetivo)]),
      );

      expect(find.text('Sin objetivo'), findsOneWidget);
      expect(find.text('PENDIENTE'), findsOneWidget);
    });

    testWidgets('una posición sin protección lo dice', (tester) async {
      await montar(tester, _Repo([_posicion('p1', 'QLD')]));

      expect(find.text('Sin protección'), findsOneWidget);
    });

    testWidgets('sin cotización todavía la posición se ve sin valor', (
      tester,
    ) async {
      await montar(tester, _Repo([_posicion('p1', 'ZZZZ')]));

      expect(find.text('ZZZZ'), findsOneWidget);
      expect(find.text('Sin precio aún'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('varias posiciones, ordenadas por símbolo', (tester) async {
      await montar(
        tester,
        _Repo([_posicion('p2', 'QLD'), _posicion('p1', 'AAPL', cantidad: 3)]),
      );

      final aapl = tester.getTopLeft(find.text('AAPL')).dy;
      final qld = tester.getTopLeft(find.text('QLD')).dy;
      expect(aapl, lessThan(qld));
    });

    testWidgets('sin posiciones, un estado vacío claro', (tester) async {
      await montar(tester, _Repo(const []));

      expect(find.text('Aún no tienes posiciones'), findsOneWidget);
      expect(find.byType(TarjetaDePosicion), findsNothing);
    });

    testWidgets('si no puede leerlas, avisa y deja reintentar', (tester) async {
      final repo = _Repo([_posicion('p1', 'QLD')])
        ..errorAlLeer = StateError('detalle técnico');
      await montar(tester, repo);

      expect(find.byType(EstadoDeError), findsOneWidget);
      expect(find.textContaining('detalle técnico'), findsNothing);

      repo.errorAlLeer = null;
      await tester.tap(find.text('Reintentar'));
      await asentar(tester);

      expect(find.byType(EstadoDeError), findsNothing);
      expect(find.text('QLD'), findsOneWidget);
    });

    testWidgets('el evento posicion trae la posición nueva', (tester) async {
      final repo = _Repo(const []);
      await montar(tester, repo);
      expect(find.text('Aún no tienes posiciones'), findsOneWidget);

      repo.posicionesDelCupo = [_posicion('p9', 'NVDA', cantidad: 2)];
      fuente.evento(
        'usuario:usuario-1',
        'posicion',
        tabla: 'posiciones',
        id: 'p9',
        version: 1,
        estado: 'abierta',
      );
      await asentar(tester);

      expect(find.text('NVDA'), findsOneWidget);
      expect(find.text('Aún no tienes posiciones'), findsNothing);
    });

    testWidgets('pide solo las posiciones de mi cupo', (tester) async {
      final repo = _Repo([_posicion('p1', 'QLD')]);
      await montar(tester, repo);

      expect(repo.pedidas, isNotEmpty);
      expect(repo.pedidas.every((id) => id == _idCupo), isTrue);
    });

    for (final oscuro in [false, true]) {
      testWidgets(
        'a 360 dp con el texto al doble, ${oscuro ? 'oscuro' : 'claro'}, sin desbordar',
        (tester) async {
          await montar(
            tester,
            _Repo([_posicion('p1', 'QLD', proteccion: _proteccion)]),
            oscuro: oscuro,
            textoEscala: 2,
          );

          expect(find.text('QLD'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('cálculo y formato', () {
    test('valor, ganancia no realizada y porcentaje al último precio', () {
      final v = PosicionValorada(
        posicion: _posicion('p', 'QLD'),
        precio: 110.25,
      );

      expect(v.valor, 1102.5);
      expect(v.noRealizado, 102.5);
      expect(v.noRealizadoPct, closeTo(10.25, 1e-9));
    });

    test('sin precio no hay valor ni ganancia', () {
      final v = PosicionValorada(posicion: _posicion('p', 'QLD'));

      expect(v.valor, isNull);
      expect(v.noRealizado, isNull);
      expect(v.noRealizadoPct, isNull);
    });

    test('la cantidad no lleva ceros de sobra', () {
      expect(formatearCantidad(10), '10');
      expect(formatearCantidad(2.5), '2,5');
      expect(formatearCantidad(0.123456789), '0,123456789');
    });

    test('lee una posición y su protección de las filas de la API', () {
      final p = PosicionDeCupo.desdeJson({
        'id': 'p1',
        'simbolo': 'QLD',
        'cantidad': '10.000000000',
        'costo_promedio': 100.5,
        'costo_total': 1005,
        'resultado_realizado': 0,
        'version': 3,
      });
      final pr = ProteccionDePosicion.desdeJson({
        'id': 'pr1',
        'tipo': 'nativa',
        'estado': 'activa',
        'stop_precio': 95.0,
        'objetivo_precio': null,
      });

      expect(p.cantidad, 10);
      expect(p.costoPromedio, 100.5);
      expect(pr.objetivoPrecio, isNull);
      expect(pr.etiquetaDelTipo, 'Nativa');
      expect(pr.etiquetaDelEstado, 'Activa');
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/errores/traduccion_de_errores.dart';
import 'package:inversiones/core/realtime/gestor_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';
import 'package:inversiones/features/admin/parametros/data/parametros_repositorio.dart';
import 'package:inversiones/features/admin/parametros/domain/parametro.dart';
import 'package:inversiones/features/admin/parametros/domain/valor_de_parametro.dart';
import 'package:inversiones/features/admin/parametros/presentation/edicion_de_parametro.dart';
import 'package:inversiones/features/admin/parametros/presentation/pagina_parametros.dart';
import 'package:inversiones/features/admin/parametros/presentation/panel_de_interruptores.dart';

import '../../../core/realtime/falsos.dart';

Map<String, dynamic> _p(
  String clave,
  Object? valor, {
  String tipo = 'numero',
  num? min,
  num? max,
  String descripcion = 'Descripción',
}) => {
  'clave': clave,
  'valor': valor,
  'tipo': tipo,
  'minimo': min,
  'maximo': max,
  'descripcion': descripcion,
  'version': 1,
};

class _Repo implements ParametrosRepositorio {
  _Repo({this.errorAlActualizar, this.errorAlReanudar});

  List<Map<String, dynamic>> filas = [
    _p('reparto.pct_reserva', 50, min: 0, max: 100),
    _p('reparto.pct_arriesgadas', 25, min: 0, max: 100),
    _p('reparto.pct_usuarios', 25, min: 0, max: 100),
    _p(
      'riesgo.orden_minima_usd',
      10,
      min: 1,
      max: 1000,
      descripcion: 'Monto mínimo de una orden',
    ),
    _p('jev.confianza_minima', 0.65, min: 0.5, max: 0.95),
    _p('cupos.maximo_usd', null),
  ];
  Map<String, dynamic> fondo = {
    'ia_activa': false,
    'trading_activo': true,
    'motivo_pausa': 'Revisión del broker',
    'pausado_en': '2031-03-10T16:00:00Z',
    'perfiles': {'nombre': 'Ana Admin'},
  };
  final Object? errorAlActualizar;
  final Object? errorAlReanudar;
  final List<String> llamadas = [];

  @override
  Future<List<Parametro>> listar() async => [
    for (final f in filas) Parametro.desdeJson(f),
  ];

  @override
  Future<List<CambioDeParametro>> historial(String clave) async => [
    CambioDeParametro(
      valorAnterior: 8,
      valorNuevo: 10,
      cambiadoEn: DateTime.utc(2031, 3, 9, 15),
      motivo: 'Ajuste de prueba',
    ),
  ];

  @override
  Future<void> actualizar(String clave, Object? valor, String motivo) async {
    llamadas.add('actualizar $clave $valor $motivo');
    if (errorAlActualizar != null) throw errorAlActualizar!;
  }

  @override
  Future<Interruptores> interruptores() async => Interruptores.desdeJson(fondo);

  @override
  Future<void> reanudar(Interruptor interruptor) async {
    llamadas.add('reanudar ${interruptor.clave}');
    if (errorAlReanudar != null) throw errorAlReanudar!;
    fondo = {...fondo, interruptor.clave: true};
  }

  @override
  Future<void> frenar(Interruptor interruptor, String motivo) async {
    llamadas.add('frenar ${interruptor.clave} $motivo');
    fondo = {...fondo, interruptor.clave: false, 'motivo_pausa': motivo};
  }
}

void main() {
  group('lectura de valores', () {
    final numero = Parametro.desdeJson(_p('x', 1));
    test('un número con coma o punto', () {
      expect(leerValor(numero, '0,65').valor, 0.65);
      expect(leerValor(numero, '20').valor, 20);
      expect(leerValor(numero, 'abc').esValido, isFalse);
    });
    test('cupos.maximo_usd vacío es sin límite', () {
      final maximo = Parametro.desdeJson(_p('cupos.maximo_usd', null));
      expect(leerValor(maximo, '').valor, isNull);
      expect(leerValor(maximo, '').esValido, isTrue);
      expect(leerValor(numero, '').esValido, isFalse);
    });
    test('una lista separa por comas', () {
      final lista = Parametro.desdeJson(_p('x', [], tipo: 'lista'));
      expect(leerValor(lista, 'a.com, b.com').valor, ['a.com', 'b.com']);
    });
    test('CA-3 · el reparto exige sumar 100', () {
      final bien = leerReparto(
        reserva: '50',
        arriesgadas: '25',
        usuarios: '25',
      );
      expect(bien.valor, {
        'pct_reserva': 50,
        'pct_arriesgadas': 25,
        'pct_usuarios': 25,
      });
      final mal = leerReparto(reserva: '50', arriesgadas: '25', usuarios: '30');
      expect(mal.esValido, isFalse);
      expect(mal.error, contains('suman 105'));
      expect(
        leerReparto(reserva: 'x', arriesgadas: '25', usuarios: '25').esValido,
        isFalse,
      );
      expect(
        leerReparto(
          reserva: '120',
          arriesgadas: '-10',
          usuarios: '-10',
        ).esValido,
        isFalse,
      );
    });
    test('el rango y el valor se leen en español', () {
      final p = Parametro.desdeJson(_p('x', 0.65, min: 0.5, max: 0.95));
      expect(p.valorEnTexto, '0,65');
      expect(p.rango, '0,5 a 0,95');
      expect(textoDeValor(null), 'Sin límite');
    });
  });

  group('pantalla', () {
    late FuenteFalsa fuente;
    late GestorDeTiempoReal gestor;

    setUp(() {
      fuente = FuenteFalsa();
      gestor = GestorDeTiempoReal(fuente, const ['admin']);
    });

    Future<void> montar(WidgetTester tester, _Repo repo) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            parametrosRepositorioProvider.overrideWithValue(repo),
            gestorDeTiempoRealProvider.overrideWithValue(gestor),
          ],
          child: MaterialApp(
            theme: crearTema(),
            home: const PaginaParametros(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> escribir(WidgetTester tester, Key clave, String texto) async {
      await tester.enterText(
        find.descendant(
          of: find.byKey(clave),
          matching: find.byType(TextField),
        ),
        texto,
      );
    }

    testWidgets('CA-1 · agrupa por tema con valor, rango y descripción', (
      tester,
    ) async {
      await montar(tester, _Repo());

      expect(find.text('Reparto de aportes'), findsOneWidget);
      expect(find.text('50 / 25 / 25'), findsOneWidget);
      expect(find.text('Riesgo'), findsOneWidget);
      expect(find.text('riesgo.orden_minima_usd'), findsOneWidget);
      expect(find.text('Monto mínimo de una orden'), findsOneWidget);
      expect(find.text('Rango: 1 a 1000'), findsOneWidget);
      expect(find.text('Decisión de JEV'), findsOneWidget);
      expect(find.text('0,65'), findsOneWidget);
      expect(find.text('Sin límite'), findsOneWidget);
      // El reparto se edita junto: no hay filas sueltas de cada porcentaje.
      expect(find.text('reparto.pct_reserva'), findsNothing);
    });

    testWidgets(
      'CA-2 · cambia un parámetro con motivo y muestra el historial',
      (tester) async {
        final repo = _Repo();
        await montar(tester, repo);

        await tester.tap(
          find.byKey(claveDeParametro('riesgo.orden_minima_usd')),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Ajuste de prueba'),
          findsOneWidget,
          reason: 'historial',
        );

        await escribir(tester, claveDelValorNuevo, '15,5');
        await tester.tap(find.byKey(claveDeGuardar));
        await tester.pumpAndSettle();
        expect(
          find.text('Escribe el motivo del cambio.'),
          findsOneWidget,
          reason: 'el motivo es obligatorio',
        );
        expect(repo.llamadas, isEmpty);

        await escribir(tester, claveDelMotivo, 'Prueba de la presentación');
        await tester.tap(find.byKey(claveDeGuardar));
        await tester.pumpAndSettle();
        expect(repo.llamadas, [
          'actualizar riesgo.orden_minima_usd 15.5 Prueba de la presentación',
        ]);
        expect(
          find.byKey(claveDelValorNuevo),
          findsNothing,
          reason: 'se cierra',
        );
      },
    );

    testWidgets('CA-2 · un valor fuera de rango muestra su mensaje', (
      tester,
    ) async {
      final repo = _Repo(
        errorAlActualizar: const ErrorDeNegocio('PARAMETRO_FUERA_DE_RANGO'),
      );
      await montar(tester, repo);

      await tester.tap(find.byKey(claveDeParametro('riesgo.orden_minima_usd')));
      await tester.pumpAndSettle();
      await escribir(tester, claveDelValorNuevo, '5000');
      await escribir(tester, claveDelMotivo, 'Probar el rango');
      await tester.tap(find.byKey(claveDeGuardar));
      await tester.pumpAndSettle();

      expect(
        find.text(traducirCodigo('PARAMETRO_FUERA_DE_RANGO')),
        findsOneWidget,
      );
      expect(
        find.byKey(claveDelValorNuevo),
        findsOneWidget,
        reason: 'sigue abierta',
      );
    });

    testWidgets('CA-3 · el reparto no se guarda si no suma 100', (
      tester,
    ) async {
      final repo = _Repo();
      await montar(tester, repo);

      await tester.tap(find.byKey(claveDeParametro('reparto')));
      await tester.pumpAndSettle();
      await escribir(tester, claveDelRepartoUsuarios, '30');
      await escribir(tester, claveDelMotivo, 'Cambiar el reparto');
      await tester.tap(find.byKey(claveDeGuardar));
      await tester.pumpAndSettle();
      expect(find.textContaining('deben sumar 100'), findsOneWidget);
      expect(repo.llamadas, isEmpty);

      await escribir(tester, claveDelRepartoReserva, '45');
      await tester.tap(find.byKey(claveDeGuardar));
      await tester.pumpAndSettle();
      expect(repo.llamadas, hasLength(1));
      expect(repo.llamadas.single, startsWith('actualizar reparto {'));
      expect(repo.llamadas.single, contains('pct_reserva: 45'));
    });

    testWidgets('CA-4 · muestra el estado, el motivo, el autor y la hora', (
      tester,
    ) async {
      await montar(tester, _Repo());
      await tester.tap(find.text('Interruptores'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(claveDeInterruptor(Interruptor.iaActiva)),
        findsOneWidget,
      );
      expect(find.text('Apagado'), findsOneWidget); // IA
      expect(find.text('Encendido'), findsOneWidget); // trading
      expect(
        find.text('Motivo de la pausa: Revisión del broker'),
        findsOneWidget,
      );
      expect(find.textContaining('Por Ana Admin'), findsOneWidget);
    });

    testWidgets('CA-4 · enciende con confirmación y apaga con motivo', (
      tester,
    ) async {
      final repo = _Repo();
      await montar(tester, repo);
      await tester.tap(find.text('Interruptores'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(claveDeAccionDeInterruptor(Interruptor.iaActiva)),
      );
      await tester.pumpAndSettle();
      expect(repo.llamadas, isEmpty, reason: 'nada sin confirmar');
      await tester.tap(find.byKey(claveDeConfirmarInterruptor));
      await tester.pumpAndSettle();
      expect(repo.llamadas, ['reanudar ia_activa']);

      await tester.tap(
        find.byKey(claveDeAccionDeInterruptor(Interruptor.tradingActivo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(claveDeConfirmarInterruptor));
      await tester.pumpAndSettle();
      expect(find.text('Escribe por qué lo apagas.'), findsOneWidget);
      await escribir(tester, claveDelMotivoDelFreno, 'Algo raro');
      await tester.tap(find.byKey(claveDeConfirmarInterruptor));
      await tester.pumpAndSettle();
      expect(repo.llamadas.last, 'frenar trading_activo Algo raro');
    });

    testWidgets('CA-4 · sin capital muestra FONDO_SIN_CAPITAL', (tester) async {
      final repo = _Repo(
        errorAlReanudar: const ErrorDeNegocio('FONDO_SIN_CAPITAL'),
      );
      await montar(tester, repo);
      await tester.tap(find.text('Interruptores'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(claveDeAccionDeInterruptor(Interruptor.iaActiva)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(claveDeConfirmarInterruptor));
      await tester.pumpAndSettle();

      expect(find.text(traducirCodigo('FONDO_SIN_CAPITAL')), findsOneWidget);
    });

    testWidgets('se actualiza sola con los eventos parametro e interruptor', (
      tester,
    ) async {
      final repo = _Repo();
      await montar(tester, repo);
      expect(find.text('10'), findsOneWidget);

      repo.filas = [
        for (final f in repo.filas)
          f['clave'] == 'riesgo.orden_minima_usd' ? {...f, 'valor': 12} : f,
      ];
      fuente.evento('admin', 'parametro', tabla: 'parametros', id: 'x');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);

      await tester.tap(find.text('Interruptores'));
      await tester.pumpAndSettle();
      expect(find.text('Apagado'), findsOneWidget);
      repo.fondo = {...repo.fondo, 'ia_activa': true};
      fuente.evento('admin', 'interruptor', tabla: 'fondos', id: 'f');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Apagado'), findsNothing);
      expect(find.text('Encendido'), findsNWidgets(2));
    });
  });
}

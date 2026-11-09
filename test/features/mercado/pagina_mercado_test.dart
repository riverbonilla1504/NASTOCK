import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/features/mercado/domain/mercado.dart';
import 'package:inversiones/shared/widgets/lista_desplegable.dart';
import 'package:inversiones/shared/widgets/selector_de_rango.dart';
import 'package:inversiones/features/mercado/presentation/grafica_de_mercado.dart';
import 'package:inversiones/features/mercado/presentation/mercado_provider.dart';

import '../../core/realtime/falsos.dart';
import 'ayudas.dart';

void main() {
  late MercadoRepositorioFalso repo;
  late FuenteFalsa fuente;

  setUp(() {
    repo = MercadoRepositorioFalso();
    fuente = FuenteFalsa();
  });

  testWidgets(
    'CA-1: muestra las cotizaciones con su variación y el estado del mercado a 360 dp',
    (tester) async {
      await abrirMercado(tester, overridesDeMercado(repo, fuente));

      expect(find.text('Mercado abierto'), findsOneWidget);
      expect(find.text('QQQ'), findsWidgets);
      expect(find.text('USD 478,62'), findsWidgets);
      expect(find.text('NVIDIA'), findsOneWidget);
      expect(find.text('USD 920,40'), findsOneWidget);
      expect(find.byType(GraficaDeMercado), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('CA-2: un evento cotizaciones cambia el precio sin recargar', (
    tester,
  ) async {
    await abrirMercado(tester, overridesDeMercado(repo, fuente));
    expect(find.text('USD 920,40'), findsOneWidget);
    final fotos = repo.fotos;

    fuente.crudo('mercado', 'cotizaciones', {
      'momento': '2026-11-09T15:30:15Z',
      'datos': [
        {'s': 'NVDA', 'p': 925.5, 'b': 925.4, 'a': 925.6, 'vd': 2.8},
      ],
    });
    await asentar(tester);

    expect(find.text('USD 920,40'), findsNothing);
    expect(find.text('USD 925,50'), findsOneWidget);
    expect(repo.fotos, fotos, reason: 'no volvió a pedir la foto');
  });

  testWidgets('CA-2: al invalidar vuelve a pedir la foto completa', (
    tester,
  ) async {
    final contenedor = await abrirMercado(
      tester,
      overridesDeMercado(repo, fuente),
    );
    final fotos = repo.fotos;

    repo.cotizacionesDeFoto = [cotizacion('QQQ', 480, variacion: 1)];
    contenedor.invalidate(cotizacionesProvider);
    await asentar(tester);

    expect(repo.fotos, fotos + 1);
    expect(find.text('USD 480,00'), findsWidgets);
  });

  testWidgets('CA-3: mercado abierto, cuenta regresiva al cierre', (
    tester,
  ) async {
    await abrirMercado(tester, overridesDeMercado(repo, fuente));

    expect(find.textContaining('Cierra en'), findsOneWidget);
    expect(find.textContaining('02:14:33'), findsOneWidget);
    // Hora de Bogotá: 17:44:33 UTC − 5 h = 12:44.
    expect(find.textContaining('09/11/2026 12:44'), findsOneWidget);
    expect(find.textContaining('hora de Bogotá'), findsOneWidget);
  });

  testWidgets('CA-3: mercado cerrado, cuenta regresiva a la apertura', (
    tester,
  ) async {
    repo.estado_ = estadoCerrado();
    await abrirMercado(tester, overridesDeMercado(repo, fuente));

    expect(find.text('Mercado cerrado'), findsOneWidget);
    expect(find.textContaining('Abre en'), findsOneWidget);
    expect(find.textContaining('1 d 03:00:00'), findsOneWidget);
  });

  testWidgets('CA-3: la cuenta avanza con el tic de cada segundo', (
    tester,
  ) async {
    final tic = StreamController<int>.broadcast();
    addTearDown(tic.close);
    var ahora = ahoraDePrueba;
    // El reloj corre: cada tic es un segundo más.
    await abrirMercado(
      tester,
      overridesDeMercado(
        repo,
        fuente,
        tic: tic.stream,
        ahoraLocal: () => ahora,
      ),
    );
    expect(find.textContaining('02:14:33'), findsOneWidget);

    ahora = ahora.add(const Duration(seconds: 3));
    tic.add(1);
    await asentar(tester);

    expect(find.textContaining('02:14:30'), findsOneWidget);
  });

  testWidgets('CA-4: filtra por bolsillo y muestra su lista blanca', (
    tester,
  ) async {
    await abrirMercado(tester, overridesDeMercado(repo, fuente));
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('ProShares Ultra QQQ'), findsOneWidget);

    // La lista desplegable abre con el valor actual y elige otra opción.
    Future<void> elegir(String actual, String nueva) async {
      await tester.tap(find.text(actual));
      await tester.pumpAndSettle();
      await tester.tap(find.text(nueva).last);
      await tester.pumpAndSettle();
    }

    await elegir('Todos', 'Arriesgadas');
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('NVIDIA'), findsOneWidget);
    expect(find.text('ProShares Ultra QQQ'), findsNothing);

    await elegir('Arriesgadas', 'Usuarios');
    expect(find.text('Apple'), findsNothing);
    expect(find.text('ProShares Ultra QQQ'), findsOneWidget);

    await elegir('Usuarios', 'Todos');
    expect(find.text('Apple'), findsOneWidget);
  });

  testWidgets('el selector de bolsillo es una lista desplegable', (
    tester,
  ) async {
    await abrirMercado(tester, overridesDeMercado(repo, fuente));
    expect(find.byType(ListaDesplegable<BolsilloDeLista?>), findsOneWidget);
    // Cerrada, solo se ve la opción elegida.
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Usuarios'), findsNothing);
    expect(find.text('Arriesgadas'), findsNothing);
  });

  group('solo 10 acciones y "Ver las demás"', () {
    // 25 acciones AAA01..AAA25 (en orden alfabético, ya sin ETF).
    MercadoRepositorioFalso muchas() {
      final simbolos = [
        for (var i = 1; i <= 25; i++) 'AAA${i.toString().padLeft(2, '0')}',
      ];
      return MercadoRepositorioFalso(
        lista: [
          for (final s in simbolos) simbolo('arriesgadas', s, 'Empresa $s'),
        ],
        cotizaciones: [for (final s in simbolos) cotizacion(s, 100)],
      );
    }

    testWidgets('muestra las primeras 10 y el resto queda oculto', (
      tester,
    ) async {
      await abrirMercado(tester, overridesDeMercado(muchas(), fuente));

      expect(find.text('Empresa AAA10'), findsOneWidget);
      expect(find.text('Empresa AAA11'), findsNothing);
      expect(find.text('Ver las demás (15)'), findsOneWidget);
    });

    testWidgets('al tocar "Ver las demás" se despliega el resto', (
      tester,
    ) async {
      await abrirMercado(tester, overridesDeMercado(muchas(), fuente));

      await tester.tap(find.text('Ver las demás (15)'));
      await tester.pumpAndSettle();
      expect(find.text('Empresa AAA11'), findsOneWidget);
      expect(find.text('Empresa AAA25'), findsOneWidget);
      expect(find.text('Ocultar las demás (15)'), findsOneWidget);

      await tester.tap(find.text('Ocultar las demás (15)'));
      await tester.pumpAndSettle();
      expect(find.text('Empresa AAA11'), findsNothing);
    });

    testWidgets('con 10 o menos no hay sección de las demás', (tester) async {
      await abrirMercado(tester, overridesDeMercado(repo, fuente));
      expect(find.textContaining('Ver las demás'), findsNothing);
    });

    testWidgets(
      'tocar una acción (de las 10 o de las demás) la pone en la gráfica y sube la página',
      (tester) async {
        final muchasAcciones = muchas();
        // Una pantalla baja para que haya desplazamiento.
        await abrirMercado(
          tester,
          overridesDeMercado(muchasAcciones, fuente),
          alto: 700,
        );
        final desplazable = find.byType(Scrollable).first;
        ScrollPosition posicion() =>
            tester.state<ScrollableState>(desplazable).position;

        // De las 10 primeras.
        await tester.drag(desplazable, const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(posicion().pixels, greaterThan(0));
        await tester.tap(find.text('Empresa AAA05'));
        await tester.pumpAndSettle();
        expect(posicion().pixels, 0);
        expect(find.textContaining('AAA05 · Empresa AAA05'), findsOneWidget);

        // De las demás.
        await tester.drag(desplazable, const Offset(0, -900));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver las demás (15)'));
        await tester.pumpAndSettle();
        await tester.drag(desplazable, const Offset(0, -900));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Empresa AAA20'));
        await tester.pumpAndSettle();
        expect(posicion().pixels, 0);
        expect(find.textContaining('AAA20 · Empresa AAA20'), findsOneWidget);
      },
    );
  });

  testWidgets('el selector de rango pide la serie del rango y la dibuja', (
    tester,
  ) async {
    repo.seriesPorRango[RangoDeGrafica.mes] = [
      for (var i = 0; i < 22; i++)
        PuntoDeSerie(DateTime.utc(2026, 10, 9 + i), 470 + i.toDouble()),
    ];
    await abrirMercado(tester, overridesDeMercado(repo, fuente));
    expect(repo.series.last, (simbolo: 'QQQ', rango: RangoDeGrafica.dia));

    for (final r in RangoDeGrafica.values) {
      expect(find.byKey(claveDeRango(r)), findsOneWidget);
    }
    await tester.tap(find.byKey(claveDeRango(RangoDeGrafica.mes)));
    await asentar(tester);

    expect(repo.series.last, (simbolo: 'QQQ', rango: RangoDeGrafica.mes));
    expect(find.byType(GraficaDeMercado), findsOneWidget);
  });

  testWidgets('tocar una fila cambia el símbolo de la gráfica', (tester) async {
    await abrirMercado(tester, overridesDeMercado(repo, fuente));

    await tester.tap(find.text('NVIDIA'));
    await asentar(tester);

    expect(repo.series.last.simbolo, 'NVDA');
    expect(find.textContaining('NVDA · NVIDIA'), findsOneWidget);
  });

  testWidgets('sin datos del día para un símbolo sin barras de minuto', (
    tester,
  ) async {
    await abrirMercado(tester, overridesDeMercado(repo, fuente));
    await tester.tap(find.text('NVIDIA'));
    await asentar(tester);

    expect(find.text('Sin datos del día para NVDA'), findsOneWidget);
  });

  testWidgets('un error al leer se avisa y se puede reintentar', (
    tester,
  ) async {
    repo.error = Exception('sin red');
    await abrirMercado(tester, overridesDeMercado(repo, fuente));
    expect(find.text('Reintentar'), findsWidgets);

    repo.error = null;
    await tester.tap(find.text('Reintentar').last);
    await asentar(tester);
    expect(find.text('NVIDIA'), findsOneWidget);
  });

  testWidgets('sin desbordar con el texto al doble a 360 dp', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await abrirMercado(tester, overridesDeMercado(repo, fuente));
    expect(tester.takeException(), isNull);
  });

  group('mercado cerrado: sin cotización en vivo', () {
    CierreDiario cierre(String simbolo, double cierre, double anterior) =>
        CierreDiario(
          simbolo: simbolo,
          fecha: DateTime.utc(2026, 11, 6),
          cierre: cierre,
          cierreAnterior: anterior,
        );

    testWidgets('la fila muestra el último cierre, su variación y la fecha', (
      tester,
    ) async {
      repo = MercadoRepositorioFalso(cotizaciones: const [])
        ..cierres = [cierre('AAPL', 190.1, 200), cierre('NVDA', 920.4, 900)];
      await abrirMercado(tester, overridesDeMercado(repo, fuente));

      expect(find.text('USD 190,10'), findsOneWidget);
      expect(find.text('USD 920,40'), findsOneWidget);
      expect(find.text('Cierre 6 nov'), findsWidgets);
      expect(find.text('-4,95 %'), findsOneWidget);
      expect(find.text('+2,27 %'), findsOneWidget);
      // QQQ y QLD no traen cierre en esta prueba.
      expect(find.text('Sin precio'), findsNWidgets(2));
    });

    testWidgets('cuando llega la cotización en vivo se usa esa', (
      tester,
    ) async {
      repo = MercadoRepositorioFalso(cotizaciones: const [])
        ..cierres = [cierre('NVDA', 920.4, 900)];
      await abrirMercado(tester, overridesDeMercado(repo, fuente));
      expect(find.text('Cierre 6 nov'), findsOneWidget);

      fuente.crudo('mercado', 'cotizaciones', {
        'momento': '2026-11-09T15:30:15Z',
        'datos': [
          {'s': 'NVDA', 'p': 930.0, 'vd': 3.3},
        ],
      });
      await asentar(tester);

      expect(find.text('USD 930,00'), findsOneWidget);
      expect(find.text('USD 920,40'), findsNothing);
      expect(find.text('Cierre 6 nov'), findsNothing);
    });

    testWidgets('si falla leer los cierres, la lista sigue (Sin precio)', (
      tester,
    ) async {
      final falla = _RepoSinCierres();
      await abrirMercado(tester, overridesDeMercado(falla, fuente));
      expect(find.text('Sin precio'), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  });
}

class _RepoSinCierres extends MercadoRepositorioFalso {
  _RepoSinCierres() : super(cotizaciones: const []);

  @override
  Future<List<CierreDiario>> ultimosCierres() async =>
      throw Exception('sin red');
}

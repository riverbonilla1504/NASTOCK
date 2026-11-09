import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/features/mercado/domain/mercado.dart';
import 'package:inversiones/features/mercado/presentation/encabezado_del_mercado.dart';
import 'package:inversiones/features/mercado/presentation/grafica_de_mercado.dart';
import 'package:inversiones/features/mercado/presentation/mercado_provider.dart';
import 'package:inversiones/features/mercado/presentation/pagina_mercado.dart';

import 'ayudas.dart';

void main() {
  group('formatearCuentaRegresiva', () {
    test('horas, minutos y segundos', () {
      expect(
        formatearCuentaRegresiva(
          const Duration(hours: 2, minutes: 5, seconds: 9),
        ),
        '02:05:09',
      );
    });
    test('con días', () {
      expect(
        formatearCuentaRegresiva(const Duration(days: 2, hours: 3)),
        '2 d 03:00:00',
      );
    });
    test('nunca es negativa', () {
      expect(formatearCuentaRegresiva(const Duration(seconds: -5)), '00:00:00');
    });
  });

  group('etiquetas de la gráfica', () {
    test('el precio lleva coma decimal', () {
      expect(etiquetaDePrecio(478.6), '478,60');
    });
    test('1D usa la hora de Bogotá', () {
      expect(
        etiquetaDeEje(DateTime.utc(2026, 11, 9, 14, 30), RangoDeGrafica.dia),
        '09:30',
      );
    });
    test('1M usa día y mes', () {
      expect(
        etiquetaDeEje(DateTime.utc(2026, 10, 9), RangoDeGrafica.mes),
        '9 oct',
      );
    });
    test('1Y y All usan mes y año', () {
      expect(
        etiquetaDeEje(DateTime.utc(2026, 10, 9), RangoDeGrafica.anio),
        "oct '26",
      );
    });
  });

  group('serie en vivo', () {
    final serie = [
      PuntoDeSerie(DateTime.utc(2026, 11, 9, 14, 30), 100),
      PuntoDeSerie(DateTime.utc(2026, 11, 9, 14, 31), 101),
    ];
    test('agrega el precio nuevo al final', () {
      final r = serieConPrecioEnVivo(serie, cotizacion('QQQ', 102));
      expect(r.length, 3);
      expect(r.last.valor, 102);
    });
    test('no agrega uno más viejo que el último punto', () {
      final c = Cotizacion(
        simbolo: 'QQQ',
        precio: 99,
        momento: DateTime.utc(2026, 11, 9, 14, 30),
        recibidoEn: ahoraDePrueba,
      );
      expect(serieConPrecioEnVivo(serie, c), serie);
    });
    test('con la serie vacía no inventa un punto', () {
      expect(serieConPrecioEnVivo(const [], cotizacion('QQQ', 1)), isEmpty);
    });
    test('el cambio del rango va del primero al último', () {
      expect(variacionDeLaSerie(serie), closeTo(1, 1e-9));
      expect(variacionDeLaSerie(const []), isNull);
    });
  });

  group('filasDeMercado', () {
    final lista = [
      simbolo('arriesgadas', 'TQQQ', 'ProShares UltraPro QQQ'),
      simbolo('arriesgadas', 'AAPL', 'Apple'),
      simbolo('usuarios', 'QQQ', 'Invesco QQQ'),
      simbolo('usuarios', 'QLD', 'Ultra QQQ'),
      simbolo('arriesgadas', 'QQQ', 'Invesco QQQ'),
    ];
    final cotizaciones = {'QQQ': cotizacion('QQQ', 1)};

    test('los ETF van primero, sin repetir un símbolo en dos bolsillos', () {
      final filas = filasDeMercado(lista: lista, cotizaciones: cotizaciones);
      expect(
        [for (final f in filas) f.simbolo],
        ['QQQ', 'QLD', 'TQQQ', 'AAPL'],
      );
      expect(filas.first.cotizacion?.precio, 1);
      expect(filas.last.cotizacion, isNull);
    });
    test('el bolsillo deja solo su lista blanca', () {
      final filas = filasDeMercado(
        lista: lista,
        cotizaciones: cotizaciones,
        bolsillo: BolsilloDeLista.usuarios,
      );
      expect([for (final f in filas) f.simbolo], ['QQQ', 'QLD']);
    });
    test('QQQ aparece aunque no esté en la lista si hay precio', () {
      final filas = filasDeMercado(
        lista: [simbolo('arriesgadas', 'AAPL', 'Apple')],
        cotizaciones: cotizaciones,
      );
      expect(filas.first.simbolo, 'QQQ');
    });
  });

  test(
    'el objetivo es el cierre con el mercado abierto y la apertura cerrado',
    () {
      expect(estadoAbierto().objetivo, estadoAbierto().proximoCierre);
      expect(estadoCerrado().objetivo, estadoCerrado().proximaApertura);
    },
  );

  test('Cotizacion.conEvento conserva el cierre anterior', () {
    final c = cotizacion('QQQ', 100, cierreAnterior: 98, variacion: 1);
    final n = c.conEvento(
      precio: 101,
      momento: ahoraDePrueba,
      recibidoEn: ahoraDePrueba,
    );
    expect(n.cierreAnterior, 98);
    expect(n.variacionDiaPct, 1);
    expect(n.precio, 101);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/core/realtime/canales.dart';
import 'package:inversiones/core/realtime/fuente_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/gestor_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/reloj.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';
import 'package:inversiones/features/mercado/data/mercado_repositorio.dart';
import 'package:inversiones/features/mercado/domain/mercado.dart';
import 'package:inversiones/features/mercado/presentation/mercado_provider.dart';
import 'package:inversiones/features/mercado/presentation/pagina_mercado.dart';

import '../../core/realtime/falsos.dart';

/// La hora fija de las pruebas: el mercado lleva una hora abierto.
final DateTime ahoraDePrueba = DateTime.utc(2026, 11, 9, 15, 30);

Cotizacion cotizacion(
  String simbolo,
  double precio, {
  double? variacion,
  double? cierreAnterior,
  DateTime? recibidoEn,
}) => Cotizacion(
  simbolo: simbolo,
  precio: precio,
  variacionDiaPct: variacion,
  cierreAnterior: cierreAnterior,
  momento: ahoraDePrueba,
  recibidoEn: recibidoEn ?? ahoraDePrueba,
);

SimboloDeLista simbolo(String bolsillo, String simbolo, String nombre) =>
    SimboloDeLista(
      bolsillo: bolsillo,
      simbolo: simbolo,
      nombre: nombre,
      enNasdaq100: false,
    );

EstadoDelMercado estadoAbierto() => EstadoDelMercado(
  estado: 'abierto',
  abierto: true,
  ahora: ahoraDePrueba,
  proximoCierre: ahoraDePrueba.add(
    const Duration(hours: 2, minutes: 14, seconds: 33),
  ),
);

EstadoDelMercado estadoCerrado() => EstadoDelMercado(
  estado: 'cerrado',
  abierto: false,
  ahora: ahoraDePrueba,
  proximaApertura: ahoraDePrueba.add(const Duration(days: 1, hours: 3)),
);

/// Repositorio falso: los datos se cambian a mano y se anota cada llamada.
class MercadoRepositorioFalso implements MercadoRepositorio {
  MercadoRepositorioFalso({
    List<Cotizacion>? cotizaciones,
    List<SimboloDeLista>? lista,
    EstadoDelMercado? estado,
  }) : cotizacionesDeFoto =
           cotizaciones ??
           [
             cotizacion('QQQ', 478.62, variacion: 0.91),
             cotizacion('QLD', 110.25, variacion: 1.83),
             cotizacion('AAPL', 190.1, variacion: -0.5),
             cotizacion('NVDA', 920.4, variacion: 2.25),
           ],
       listaBlanca_ =
           lista ??
           [
             simbolo('usuarios', 'QQQ', 'Invesco QQQ'),
             simbolo('usuarios', 'QLD', 'ProShares Ultra QQQ'),
             simbolo('arriesgadas', 'AAPL', 'Apple'),
             simbolo('arriesgadas', 'NVDA', 'NVIDIA'),
           ],
       estado_ = estado ?? estadoAbierto();

  List<Cotizacion> cotizacionesDeFoto;
  List<SimboloDeLista> listaBlanca_;
  EstadoDelMercado estado_;
  Object? error;
  int fotos = 0;
  final List<({String simbolo, RangoDeGrafica rango})> series = [];

  /// La serie que devuelve `serie`, por rango.
  Map<RangoDeGrafica, List<PuntoDeSerie>> seriesPorRango = {
    RangoDeGrafica.dia: [
      for (var i = 0; i < 20; i++)
        PuntoDeSerie(DateTime.utc(2026, 11, 9, 14, 30 + i), 476 + i * 0.1),
    ],
  };

  @override
  Future<List<Cotizacion>> cotizaciones() async {
    fotos++;
    if (error != null) throw error!;
    return cotizacionesDeFoto;
  }

  @override
  Future<List<SimboloDeLista>> listaBlanca() async {
    if (error != null) throw error!;
    return listaBlanca_;
  }

  @override
  Future<EstadoDelMercado> estadoDelMercado() async {
    if (error != null) throw error!;
    return estado_;
  }

  /// Los últimos cierres diarios que devuelve `ultimosCierres`.
  List<CierreDiario> cierres = [];

  @override
  Future<List<CierreDiario>> ultimosCierres() async => cierres;

  @override
  Future<List<PuntoDeSerie>> serie(String simbolo, RangoDeGrafica rango) async {
    series.add((simbolo: simbolo, rango: rango));
    // Solo QQQ tiene barras en la prueba (los demás símbolos no guardan
    // barras de minuto).
    if (simbolo != 'QQQ') return const [];
    return seriesPorRango[rango] ?? const [];
  }
}

/// Lo que la pantalla necesita: el repositorio, el tiempo real en memoria con
/// la sesión de un Usuario, la hora fija y un tic de segundo que la prueba
/// controla.
List<Override> overridesDeMercado(
  MercadoRepositorioFalso repo,
  FuenteFalsa fuente, {
  Stream<int>? tic,
  DateTime Function()? ahoraLocal,
}) => [
  mercadoRepositorioProvider.overrideWithValue(repo),
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
  ahoraLocalProvider.overrideWithValue(ahoraLocal ?? () => ahoraDePrueba),
  segundoProvider.overrideWith((ref) => tic ?? const Stream<int>.empty()),
];

/// Monta [PaginaMercado] a [ancho] dp con los [overrides].
Future<ProviderContainer> abrirMercado(
  WidgetTester tester,
  List<Override> overrides, {
  double ancho = 360,
  double alto = 2400,
}) async {
  tester.view.physicalSize = Size(ancho, alto);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: crearTema(),
        home: const Scaffold(body: PaginaMercado()),
      ),
    ),
  );
  await asentar(tester);
  return ProviderScope.containerOf(tester.element(find.byType(PaginaMercado)));
}

/// Deja que terminen las lecturas del repositorio falso y se redibuje.
Future<void> asentar(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

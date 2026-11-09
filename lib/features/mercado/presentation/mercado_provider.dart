/// Estado de la pantalla de mercado (HU-030): cotizaciones en vivo, estado del
/// mercado, lista blanca y serie de la gráfica.
///
/// Las cotizaciones siguen el patrón "foto + eventos" de docs/08 §9.2, con la
/// excepción de docs/09 §4: el evento `cotizaciones` del canal `mercado` trae
/// los precios (son públicos dentro de la empresa) y se mezclan sin volver a
/// pedirlos. Al reconectar se pide la foto completa otra vez.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/evento_de_tiempo_real.dart';
import '../../../core/realtime/reloj.dart';
import '../../../core/realtime/tiempo_real_provider.dart';
import '../data/mercado_repositorio.dart';
import '../domain/mercado.dart';

/// Sin reintentos automáticos: la pantalla ofrece "Reintentar" y la
/// reconexión vuelve a pedir la foto.
Duration? _sinReintentos(int intento, Object error) => null;

/// El símbolo de referencia del índice, que abre la gráfica.
const String simboloDeReferencia = 'QQQ';

/// Los ETF que van primero en la lista.
const List<String> simbolosDestacados = [simboloDeReferencia, 'QLD', 'TQQQ'];

/// Un tic por segundo, para la cuenta regresiva.
final segundoProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream<int>.periodic(const Duration(seconds: 1), (n) => n),
);

/// Las cotizaciones por símbolo.
final cotizacionesProvider =
    AsyncNotifierProvider<CotizacionesNotifier, Map<String, Cotizacion>>(
      CotizacionesNotifier.new,
      retry: _sinReintentos,
    );

class CotizacionesNotifier extends AsyncNotifier<Map<String, Cotizacion>> {
  @override
  Future<Map<String, Cotizacion>> build() {
    final gestor = ref.watch(gestorDeTiempoRealProvider);
    if (gestor != null) {
      final eventos = gestor.eventos
          .where((e) => e.canal == 'mercado' && e.evento == 'cotizaciones')
          .listen(_mezclar);
      final reconexiones = gestor.reconexiones.listen(
        (_) => ref.invalidateSelf(),
      );
      ref.onDispose(() {
        unawaited(eventos.cancel());
        unawaited(reconexiones.cancel());
      });
    }
    return ref
        .watch(mercadoRepositorioProvider)
        .cotizaciones()
        .then((lista) => {for (final c in lista) c.simbolo: c});
  }

  /// Mezcla el lote del evento (`{momento, datos: [{s, p, b, a, vd}]}`) sobre
  /// lo que ya se ve. Un evento que llega antes de la foto se descarta: la
  /// foto ya trae lo último.
  void _mezclar(EventoDeTiempoReal evento) {
    final actuales = state.value;
    if (actuales == null) return;
    final datos = evento.carga['datos'];
    if (datos is! List) return;
    final momento =
        DateTime.tryParse(evento.carga['momento']?.toString() ?? '')?.toUtc() ??
        ref.read(relojProvider).ahora();
    final recibido = ref.read(relojProvider).ahora();
    final nuevas = Map<String, Cotizacion>.of(actuales);
    for (final dato in datos) {
      if (dato is! Map) continue;
      final simbolo = dato['s'] as String?;
      final precio = dato['p'];
      if (simbolo == null || precio is! num) continue;
      final vd = dato['vd'];
      final previa = nuevas[simbolo];
      nuevas[simbolo] = previa != null
          ? previa.conEvento(
              precio: precio.toDouble(),
              variacionDiaPct: vd is num ? vd.toDouble() : null,
              momento: momento,
              recibidoEn: recibido,
            )
          : Cotizacion(
              simbolo: simbolo,
              precio: precio.toDouble(),
              variacionDiaPct: vd is num ? vd.toDouble() : null,
              momento: momento,
              recibidoEn: recibido,
            );
    }
    state = AsyncData(nuevas);
  }
}

/// El estado del mercado según el servidor. La pantalla cuenta hacia el
/// objetivo con el reloj corregido; cuando llega, vuelve a pedirlo.
final estadoMercadoProvider =
    AsyncNotifierProvider<EstadoMercadoNotifier, EstadoDelMercado>(
      EstadoMercadoNotifier.new,
      retry: _sinReintentos,
    );

class EstadoMercadoNotifier extends AsyncNotifier<EstadoDelMercado> {
  @override
  Future<EstadoDelMercado> build() {
    final gestor = ref.watch(gestorDeTiempoRealProvider);
    if (gestor != null) {
      final eventos = gestor.eventos
          .where((e) => e.canal == 'mercado' && e.evento == 'estado_mercado')
          .listen((_) => ref.invalidateSelf());
      final reconexiones = gestor.reconexiones.listen(
        (_) => ref.invalidateSelf(),
      );
      ref.onDispose(() {
        unawaited(eventos.cancel());
        unawaited(reconexiones.cancel());
      });
    }
    return ref.watch(mercadoRepositorioProvider).estadoDelMercado();
  }
}

/// La lista blanca activa.
final listaBlancaProvider = FutureProvider<List<SimboloDeLista>>(
  (ref) => ref.watch(mercadoRepositorioProvider).listaBlanca(),
  retry: _sinReintentos,
);

/// El último cierre diario por símbolo: el precio de respaldo de la lista
/// cuando no hay cotización en vivo. Si falla, la lista sigue sin él.
final ultimosCierresProvider = FutureProvider<Map<String, CierreDiario>>((
  ref,
) async {
  final cierres = await ref.watch(mercadoRepositorioProvider).ultimosCierres();
  return {for (final c in cierres) c.simbolo: c};
}, retry: _sinReintentos);

/// El bolsillo por el que se filtra la lista; `null` es todo el universo.
class BolsilloElegidoNotifier extends Notifier<BolsilloDeLista?> {
  @override
  BolsilloDeLista? build() => null;

  void elegir(BolsilloDeLista? bolsillo) => state = bolsillo;
}

final bolsilloElegidoProvider =
    NotifierProvider<BolsilloElegidoNotifier, BolsilloDeLista?>(
      BolsilloElegidoNotifier.new,
    );

/// El símbolo que dibuja la gráfica; abre en QQQ, la referencia del índice.
class SimboloGraficadoNotifier extends Notifier<String> {
  @override
  String build() => simboloDeReferencia;

  void elegir(String simbolo) => state = simbolo;
}

final simboloGraficadoProvider =
    NotifierProvider<SimboloGraficadoNotifier, String>(
      SimboloGraficadoNotifier.new,
    );

/// El rango de la gráfica.
class RangoElegidoNotifier extends Notifier<RangoDeGrafica> {
  @override
  RangoDeGrafica build() => RangoDeGrafica.dia;

  void elegir(RangoDeGrafica rango) => state = rango;
}

final rangoElegidoProvider =
    NotifierProvider<RangoElegidoNotifier, RangoDeGrafica>(
      RangoElegidoNotifier.new,
    );

/// La serie histórica del símbolo y rango elegidos.
final serieProvider = FutureProvider.autoDispose
    .family<List<PuntoDeSerie>, ({String simbolo, RangoDeGrafica rango})>(
      (ref, clave) => ref
          .watch(mercadoRepositorioProvider)
          .serie(clave.simbolo, clave.rango),
      retry: _sinReintentos,
    );

/// Una fila de la lista de la pantalla.
class FilaDeMercado {
  const FilaDeMercado({
    required this.simbolo,
    required this.nombre,
    this.cotizacion,
    this.cierre,
  });

  final String simbolo;
  final String nombre;

  /// El precio en vivo, si lo hay.
  final Cotizacion? cotizacion;

  /// El último cierre diario: lo que se muestra mientras no hay [cotizacion].
  final CierreDiario? cierre;
}

/// Las filas que se ven: el universo (o el bolsillo elegido) con su cotización
/// en vivo. Los ETF van primero, el resto por símbolo.
List<FilaDeMercado> filasDeMercado({
  required List<SimboloDeLista> lista,
  required Map<String, Cotizacion> cotizaciones,
  Map<String, CierreDiario> cierres = const {},
  BolsilloDeLista? bolsillo,
}) {
  final nombres = <String, String>{};
  for (final s in lista) {
    if (bolsillo != null && s.bolsillo != bolsillo.clave) continue;
    nombres.putIfAbsent(s.simbolo, () => s.nombre);
  }
  // QQQ se ingiere siempre aunque no esté activo en ningún bolsillo: con
  // todo el universo a la vista se muestra de todos modos.
  if (bolsillo == null && cotizaciones.containsKey(simboloDeReferencia)) {
    nombres.putIfAbsent(simboloDeReferencia, () => simboloDeReferencia);
  }
  final simbolos = nombres.keys.toList()
    ..sort((a, b) {
      final ia = simbolosDestacados.indexOf(a);
      final ib = simbolosDestacados.indexOf(b);
      if (ia != -1 || ib != -1) {
        return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
      }
      return a.compareTo(b);
    });
  return [
    for (final s in simbolos)
      FilaDeMercado(
        simbolo: s,
        nombre: nombres[s]!,
        cotizacion: cotizaciones[s],
        cierre: cierres[s],
      ),
  ];
}

/// Repositorio del mercado: el único lugar de la app que lee `cotizaciones`,
/// `lista_blanca`, las barras y `estado_mercado()` (HU-030). Solo lecturas: la
/// RLS deja leer a toda persona activa (docs/03 §4.3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/cliente_supabase.dart';
import '../domain/mercado.dart';

abstract interface class MercadoRepositorio {
  /// La última cotización de cada símbolo.
  Future<List<Cotizacion>> cotizaciones();

  /// La lista blanca activa de todos los bolsillos.
  Future<List<SimboloDeLista>> listaBlanca();

  /// El estado del mercado según el servidor.
  Future<EstadoDelMercado> estadoDelMercado();

  /// La serie de [simbolo] en [rango], en orden de tiempo. `1D` sale de las
  /// barras de minuto (solo los ETF y QQQ las guardan); los demás rangos, de
  /// las barras diarias.
  Future<List<PuntoDeSerie>> serie(String simbolo, RangoDeGrafica rango);
}

class MercadoRepositorioSupabase implements MercadoRepositorio {
  const MercadoRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<List<Cotizacion>> cotizaciones() async {
    final filas = await _cliente
        .from('cotizaciones')
        .select(Cotizacion.columnas)
        .limit(1000);
    return [for (final fila in filas) Cotizacion.desdeJson(fila)];
  }

  @override
  Future<List<SimboloDeLista>> listaBlanca() async {
    final filas = await _cliente
        .from('lista_blanca')
        .select(SimboloDeLista.columnas)
        .eq('activo', true)
        .order('simbolo')
        .limit(1000);
    return [for (final fila in filas) SimboloDeLista.desdeJson(fila)];
  }

  @override
  Future<EstadoDelMercado> estadoDelMercado() async {
    final filas = await _cliente.rpc('estado_mercado') as List<dynamic>;
    return EstadoDelMercado.desdeJson(filas.first as Map<String, dynamic>);
  }

  @override
  Future<List<PuntoDeSerie>> serie(String simbolo, RangoDeGrafica rango) async {
    if (rango == RangoDeGrafica.dia) {
      // Las últimas barras de minuto: una jornada regular tiene 390.
      final filas = await _cliente
          .from('barras_minuto')
          .select('momento, cierre')
          .eq('simbolo', simbolo)
          .order('momento', ascending: false)
          .limit(390);
      return [
        for (final fila in filas.reversed)
          PuntoDeSerie(
            DateTime.parse(fila['momento'] as String).toUtc(),
            (fila['cierre'] as num).toDouble(),
          ),
      ];
    }
    final dias = switch (rango) {
      RangoDeGrafica.mes => 22,
      RangoDeGrafica.anio => 252,
      _ => 1000,
    };
    final filas = await _cliente
        .from('barras_diarias')
        .select('fecha, cierre')
        .eq('simbolo', simbolo)
        .order('fecha', ascending: false)
        .limit(dias);
    return [
      for (final fila in filas.reversed)
        PuntoDeSerie(
          DateTime.parse(fila['fecha'] as String).toUtc(),
          (fila['cierre'] as num).toDouble(),
        ),
    ];
  }
}

final mercadoRepositorioProvider = Provider<MercadoRepositorio>(
  (ref) => MercadoRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

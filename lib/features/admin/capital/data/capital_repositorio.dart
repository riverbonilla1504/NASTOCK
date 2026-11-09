/// Repositorio de capital: el único lugar de la app que habla con
/// `movimientos_capital` y con las RPC `registrar_aporte` y `anular_aporte`
/// (docs/05 §9.1). Las escrituras van solo por RPC (docs/03 §4.4).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/cliente_supabase.dart';
import '../domain/movimiento_de_capital.dart';

abstract interface class CapitalRepositorio {
  /// Los aportes, los más recientes primero. El MVP corto no muestra retiros.
  Future<List<MovimientoDeCapital>> listarAportes();

  /// Registra un aporte. Lanza la excepción de la RPC con el código del error
  /// (`NO_AUTORIZADO`…); la pantalla la traduce con `traducirError`.
  Future<MovimientoDeCapital> registrar({
    required double monto,
    String? referencia,
    String? nota,
  });

  /// Anula un aporte registrado, con su motivo.
  Future<MovimientoDeCapital> anular({
    required String id,
    required String motivo,
  });
}

class CapitalRepositorioSupabase implements CapitalRepositorio {
  const CapitalRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<List<MovimientoDeCapital>> listarAportes() async {
    final filas = await _cliente
        .from('movimientos_capital')
        .select(MovimientoDeCapital.columnas)
        .eq('tipo', 'aporte')
        .order('registrado_en', ascending: false);
    return [for (final fila in filas) MovimientoDeCapital.desdeJson(fila)];
  }

  @override
  Future<MovimientoDeCapital> registrar({
    required double monto,
    String? referencia,
    String? nota,
  }) async {
    final fila = await _cliente.rpc<Map<String, dynamic>>(
      'registrar_aporte',
      params: {'p_monto': monto, 'p_referencia': referencia, 'p_nota': nota},
    );
    return MovimientoDeCapital.desdeJson(fila);
  }

  @override
  Future<MovimientoDeCapital> anular({
    required String id,
    required String motivo,
  }) async {
    final fila = await _cliente.rpc<Map<String, dynamic>>(
      'anular_aporte',
      params: {'p_id': id, 'p_motivo': motivo},
    );
    return MovimientoDeCapital.desdeJson(fila);
  }
}

final capitalRepositorioProvider = Provider<CapitalRepositorio>(
  (ref) => CapitalRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

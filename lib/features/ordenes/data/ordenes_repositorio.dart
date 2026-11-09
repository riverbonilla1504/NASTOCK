/// Repositorio de órdenes: el único lugar de la app que llama a la RPC
/// `crear_orden_manual` (docs/06 §8.1, HU-075). Toda escritura va por RPC.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/cliente_supabase.dart';
import '../domain/orden_manual.dart';

abstract interface class OrdenesRepositorio {
  /// El stop y el objetivo que se precargan en una compra.
  Future<ProteccionPorDefecto> proteccionPorDefecto();

  /// Crea la orden. [id] es la clave de idempotencia: repetirlo devuelve la
  /// misma orden. Falla con el código de error de docs/06 §9.
  Future<void> crearOrdenManual({
    required String id,
    required String simbolo,
    required LadoDeOrden lado,
    required int cantidad,
    double? stopPct,
    double? objetivoPct,
  });
}

class OrdenesRepositorioSupabase implements OrdenesRepositorio {
  const OrdenesRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<ProteccionPorDefecto> proteccionPorDefecto() async {
    final filas = await _cliente
        .from('parametros')
        .select('clave, valor')
        .inFilter('clave', [
          'riesgo.cupo.stop_defecto_pct',
          'riesgo.cupo.objetivo_defecto_pct',
        ]);
    double? valor(String clave) {
      for (final f in filas) {
        if (f['clave'] == clave) return (f['valor'] as num?)?.toDouble();
      }
      return null;
    }

    const base = ProteccionPorDefecto.predeterminada;
    return ProteccionPorDefecto(
      stopPct: valor('riesgo.cupo.stop_defecto_pct') ?? base.stopPct,
      objetivoPct:
          valor('riesgo.cupo.objetivo_defecto_pct') ?? base.objetivoPct,
    );
  }

  @override
  Future<void> crearOrdenManual({
    required String id,
    required String simbolo,
    required LadoDeOrden lado,
    required int cantidad,
    double? stopPct,
    double? objetivoPct,
  }) async {
    await _cliente.rpc<dynamic>(
      'crear_orden_manual',
      params: {
        'p_id': id,
        'p_simbolo': simbolo,
        'p_lado': lado.valor,
        'p_cantidad': cantidad,
        'p_stop_pct': stopPct,
        'p_objetivo_pct': objetivoPct,
      },
    );
  }
}

final ordenesRepositorioProvider = Provider<OrdenesRepositorio>(
  (ref) => OrdenesRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

/// El stop y el objetivo por defecto; si no se pueden leer, los de docs/02 §13.
final proteccionPorDefectoProvider =
    FutureProvider.autoDispose<ProteccionPorDefecto>((ref) async {
      try {
        return await ref
            .watch(ordenesRepositorioProvider)
            .proteccionPorDefecto();
      } on Object {
        return ProteccionPorDefecto.predeterminada;
      }
    });

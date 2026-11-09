/// Repositorio de Mi cupo: el único lugar de la app que habla con la RPC
/// `mi_cupo()` (docs/06 §6, HU-019). Solo lee; el servidor entrega únicamente
/// el cupo de quien llama (RN-20).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/cliente_supabase.dart';
import '../domain/mi_cupo.dart';

abstract interface class CupoRepositorio {
  /// Mi cupo abierto, o `null` si todavía no tengo uno.
  Future<MiCupo?> miCupo();
}

class CupoRepositorioSupabase implements CupoRepositorio {
  const CupoRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<MiCupo?> miCupo() async {
    final filas = await _cliente.rpc<List<dynamic>>('mi_cupo');
    if (filas.isEmpty) return null;
    return MiCupo.desdeJson(Map<String, dynamic>.from(filas.first as Map));
  }
}

final cupoRepositorioProvider = Provider<CupoRepositorio>(
  (ref) => CupoRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

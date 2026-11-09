/// Repositorio de cupos del Administrador: lee `subcuentas` (su RLS le da todas)
/// y escribe solo por las RPC `asignar_cupo` y `reducir_cupo` (HU-018, PM-42).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/cliente_supabase.dart';
import '../domain/subcuenta_de_cupo.dart';

abstract interface class CuposRepositorio {
  /// La bolsa común y los cupos abiertos.
  Future<List<SubcuentaDeCupo>> listar();

  /// Una subcuenta por su id, o `null` si ya no existe o no es visible.
  Future<SubcuentaDeCupo?> una(String id);

  /// Mueve [monto] de la bolsa común al cupo de [usuarioId]. Lanza el error de
  /// la RPC (`FONDOS_INSUFICIENTES`, `CUPO_SUPERA_MAXIMO`…).
  Future<void> asignar(String usuarioId, double monto);

  /// Mueve [monto] del cupo de [usuarioId] a la bolsa común.
  Future<void> reducir(String usuarioId, double monto);
}

class CuposRepositorioSupabase implements CuposRepositorio {
  const CuposRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<List<SubcuentaDeCupo>> listar() async {
    final filas = await _cliente
        .from('subcuentas')
        .select(SubcuentaDeCupo.columnas)
        .inFilter('tipo', ['usuarios_comun', 'cupo'])
        .eq('estado', 'abierta');
    return [for (final fila in filas) SubcuentaDeCupo.desdeJson(fila)];
  }

  @override
  Future<SubcuentaDeCupo?> una(String id) async {
    final fila = await _cliente
        .from('subcuentas')
        .select(SubcuentaDeCupo.columnas)
        .eq('id', id)
        .inFilter('tipo', ['usuarios_comun', 'cupo'])
        .eq('estado', 'abierta')
        .maybeSingle();
    return fila == null ? null : SubcuentaDeCupo.desdeJson(fila);
  }

  @override
  Future<void> asignar(String usuarioId, double monto) async {
    await _cliente.rpc<dynamic>(
      'asignar_cupo',
      params: {'p_usuario_id': usuarioId, 'p_monto': monto},
    );
  }

  @override
  Future<void> reducir(String usuarioId, double monto) async {
    await _cliente.rpc<dynamic>(
      'reducir_cupo',
      params: {'p_usuario_id': usuarioId, 'p_monto': monto},
    );
  }
}

final cuposRepositorioProvider = Provider<CuposRepositorio>(
  (ref) => CuposRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

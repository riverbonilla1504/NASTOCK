/// Repositorio de Mi cupo: el único lugar de la app que habla con la RPC
/// `mi_cupo()` (docs/06 §6, HU-019). Solo lee; el servidor entrega únicamente
/// el cupo de quien llama (RN-20).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/cliente_supabase.dart';
import '../domain/mi_cupo.dart';
import '../domain/posicion.dart';

abstract interface class CupoRepositorio {
  /// Mi cupo abierto, o `null` si todavía no tengo uno.
  Future<MiCupo?> miCupo();

  /// Las posiciones abiertas de la subcuenta [idCupo], cada una con su
  /// protección vigente (HU-091). Se leen por la API: la RLS entrega solo las de
  /// mi cupo (CA-4).
  Future<List<PosicionDeCupo>> posiciones(String idCupo);
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

  @override
  Future<List<PosicionDeCupo>> posiciones(String idCupo) async {
    final filas = await _cliente
        .from('posiciones')
        .select(PosicionDeCupo.columnas)
        .eq('subcuenta_id', idCupo)
        .neq('estado', 'cerrada')
        .order('simbolo');
    if (filas.isEmpty) return const [];

    final ids = [for (final f in filas) f['id'] as String];
    final protecciones = await _cliente
        .from('protecciones')
        .select(ProteccionDePosicion.columnas)
        .inFilter('posicion_id', ids)
        .inFilter('estado', ['pendiente', 'activa'])
        .order('creado_en', ascending: false);
    // La más reciente de cada posición (la lista ya viene de la más nueva).
    final porPosicion = <String, ProteccionDePosicion>{};
    for (final f in protecciones) {
      porPosicion.putIfAbsent(
        f['posicion_id'] as String,
        () => ProteccionDePosicion.desdeJson(Map<String, dynamic>.from(f)),
      );
    }
    return [
      for (final f in filas)
        PosicionDeCupo.desdeJson(
          Map<String, dynamic>.from(f),
          proteccion: porPosicion[f['id']],
        ),
    ];
  }
}

final cupoRepositorioProvider = Provider<CupoRepositorio>(
  (ref) => CupoRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

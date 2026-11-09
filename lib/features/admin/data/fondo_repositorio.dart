/// Repositorio del estado del fondo para Administración: ¿ya tiene capital?
/// Lee `movimientos_capital`, que solo ven el Analista y el Administrador por
/// RLS (docs/03 §4.3). No escribe nada.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/cliente_supabase.dart';

abstract interface class FondoRepositorio {
  /// `true` si hay al menos un aporte confirmado: el fondo ya tiene capital
  /// (RN-11). Antes del primer aporte confirmado el fondo no opera.
  Future<bool> tieneCapital();
}

class FondoRepositorioSupabase implements FondoRepositorio {
  const FondoRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<bool> tieneCapital() async {
    final filas = await _cliente
        .from('movimientos_capital')
        .select('id')
        .eq('tipo', 'aporte')
        .eq('estado', 'confirmado')
        .limit(1);
    return filas.isNotEmpty;
  }
}

final fondoRepositorioProvider = Provider<FondoRepositorio>(
  (ref) => FondoRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

/// Si el fondo ya tiene capital. Se vuelve a leer cada vez que se abre
/// Administración, así la guía desaparece tras el primer aporte confirmado.
final fondoConCapitalProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(fondoRepositorioProvider).tieneCapital(),
);

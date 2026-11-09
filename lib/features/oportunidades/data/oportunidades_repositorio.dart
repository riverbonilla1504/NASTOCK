/// Repositorio de Oportunidades: el único lugar de la app que habla con la RPC
/// `oportunidades(bolsillo)` (docs/05 §9.1, HU-048). Solo lee: la IA no ejecuta
/// nada y las tablas del agente no son legibles para el Usuario (docs/03 §4.3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/cliente_supabase.dart';
import '../domain/oportunidad.dart';

abstract interface class OportunidadesRepositorio {
  /// Las evaluaciones del último ciclo completado. Con [bolsillo] nulo, las de
  /// todos los bolsillos que el rol puede ver; el Usuario solo recibe las de
  /// Usuarios.
  Future<List<Oportunidad>> listar({BolsilloIa? bolsillo});
}

class OportunidadesRepositorioSupabase implements OportunidadesRepositorio {
  const OportunidadesRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<List<Oportunidad>> listar({BolsilloIa? bolsillo}) async {
    final filas = await _cliente.rpc<List<dynamic>>(
      'oportunidades',
      params: {'p_bolsillo': bolsillo?.name},
    );
    return [
      for (final fila in filas)
        Oportunidad.desdeJson(Map<String, dynamic>.from(fila as Map)),
    ];
  }
}

final oportunidadesRepositorioProvider = Provider<OportunidadesRepositorio>(
  (ref) => OportunidadesRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

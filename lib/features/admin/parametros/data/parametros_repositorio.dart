/// Repositorio de parámetros e interruptores del Administrador. Lee
/// `parametros`, `parametros_historial` y `fondos` (RLS) y escribe solo por las
/// RPC `actualizar_parametro`, `reanudar` y `activar_freno` (PM-54, PM-56 y
/// PM-57).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/cliente_supabase.dart';
import '../domain/parametro.dart';

abstract interface class ParametrosRepositorio {
  /// El catálogo de parámetros, ordenado por clave.
  Future<List<Parametro>> listar();

  /// Los cambios de un parámetro, el más reciente primero.
  Future<List<CambioDeParametro>> historial(String clave);

  /// Cambia el valor de [clave] con un [motivo]. Para `reparto`, [valor] es
  /// el objeto con los tres porcentajes. Lanza el error de la RPC
  /// (`PARAMETRO_FUERA_DE_RANGO`…).
  Future<void> actualizar(String clave, Object? valor, String motivo);

  /// El estado de los dos interruptores del fondo.
  Future<Interruptores> interruptores();

  /// Enciende un interruptor. Lanza `FONDO_SIN_CAPITAL` sin un aporte
  /// confirmado.
  Future<void> reanudar(Interruptor interruptor);

  /// Apaga un interruptor con un motivo.
  Future<void> frenar(Interruptor interruptor, String motivo);
}

class ParametrosRepositorioSupabase implements ParametrosRepositorio {
  const ParametrosRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<List<Parametro>> listar() async {
    final filas = await _cliente
        .from('parametros')
        .select(Parametro.columnas)
        .order('clave');
    return [for (final fila in filas) Parametro.desdeJson(fila)];
  }

  @override
  Future<List<CambioDeParametro>> historial(String clave) async {
    final filas = await _cliente
        .from('parametros_historial')
        .select(CambioDeParametro.columnas)
        .eq('clave', clave)
        .order('cambiado_en', ascending: false)
        .limit(20);
    return [for (final fila in filas) CambioDeParametro.desdeJson(fila)];
  }

  @override
  Future<void> actualizar(String clave, Object? valor, String motivo) async {
    await _cliente.rpc<dynamic>(
      'actualizar_parametro',
      params: {'p_clave': clave, 'p_valor': valor, 'p_motivo': motivo},
    );
  }

  @override
  Future<Interruptores> interruptores() async {
    final fila = await _cliente
        .from('fondos')
        .select(Interruptores.columnas)
        .limit(1)
        .single();
    return Interruptores.desdeJson(fila);
  }

  @override
  Future<void> reanudar(Interruptor interruptor) async {
    await _cliente.rpc<dynamic>(
      'reanudar',
      params: {'p_interruptor': interruptor.clave},
    );
  }

  @override
  Future<void> frenar(Interruptor interruptor, String motivo) async {
    await _cliente.rpc<dynamic>(
      'activar_freno',
      params: {'p_interruptor': interruptor.clave, 'p_motivo': motivo},
    );
  }
}

final parametrosRepositorioProvider = Provider<ParametrosRepositorio>(
  (ref) => ParametrosRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

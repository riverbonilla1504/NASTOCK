import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/cliente_supabase.dart';
import '../domain/mi_orden.dart';

abstract interface class MisOrdenesRepositorio {
  Future<List<MiOrden>> listar();
  Future<MiOrden?> obtener(String id);
  Future<void> cancelar(String id);
}

class MisOrdenesRepositorioSupabase implements MisOrdenesRepositorio {
  const MisOrdenesRepositorioSupabase(this.cliente);
  final SupabaseClient cliente;
  static const columnas =
      'id,simbolo,lado,estado,cantidad,cantidad_llenada,retencion,creado_en,cancelacion_solicitada_en,version';
  @override
  Future<List<MiOrden>> listar() async {
    // La RLS limita al cupo propio. La ruta solo es accesible para Usuario.
    final filas = await cliente
        .from('ordenes')
        .select(columnas)
        .order('creado_en', ascending: false);
    return filas.map(MiOrden.desdeJson).toList();
  }

  @override
  Future<MiOrden?> obtener(String id) async {
    final fila = await cliente
        .from('ordenes')
        .select(columnas)
        .eq('id', id)
        .maybeSingle();
    return fila == null ? null : MiOrden.desdeJson(fila);
  }

  @override
  Future<void> cancelar(String id) async {
    await cliente.rpc<dynamic>('cancelar_orden', params: {'p_id': id});
  }
}

final misOrdenesRepositorioProvider = Provider<MisOrdenesRepositorio>(
  (ref) => MisOrdenesRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

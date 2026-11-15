import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/cliente_supabase.dart';
import '../domain/alerta.dart';

abstract interface class AlertasRepositorio {
  Future<List<Alerta>> listar();
  Future<Alerta?> obtener(String id);
}

class AlertasRepositorioSupabase implements AlertasRepositorio {
  const AlertasRepositorioSupabase(this.cliente);
  final SupabaseClient cliente;
  static const _columnas = 'id,titulo,cuerpo,severidad,creado_en,version';

  @override
  Future<List<Alerta>> listar() async {
    final filas = await cliente
        .from('alertas')
        .select(_columnas)
        .eq('activa', true)
        .order('creado_en', ascending: false);
    return filas.map(Alerta.desdeJson).toList();
  }

  @override
  Future<Alerta?> obtener(String id) async {
    final fila = await cliente
        .from('alertas')
        .select(_columnas)
        .eq('id', id)
        .eq('activa', true)
        .maybeSingle();
    return fila == null ? null : Alerta.desdeJson(fila);
  }
}

final alertasRepositorioProvider = Provider<AlertasRepositorio>(
  (ref) => AlertasRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

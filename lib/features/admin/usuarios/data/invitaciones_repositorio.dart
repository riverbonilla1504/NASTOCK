/// Repositorio de invitaciones: el único lugar de la app que habla con
/// `invitaciones` y con las RPC `invitar_usuario` y `revocar_invitacion`
/// (docs/05 §9.1). Las escrituras van solo por RPC (docs/03 §4.4).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/perfil/perfil.dart';
import '../../../../core/supabase/cliente_supabase.dart';
import '../domain/invitacion.dart';

abstract interface class InvitacionesRepositorio {
  /// Las invitaciones, las más recientes primero. Solo el Administrador las
  /// recibe: para cualquier otro rol la RLS devuelve una lista vacía.
  Future<List<Invitacion>> listar();

  /// Invita a [email] con el [rol] y el [cupoInicial] dados. Lanza la
  /// excepción de la RPC con el código del error (`INVITACION_DUPLICADA`,
  /// `CORREO_YA_REGISTRADO`, `NO_AUTORIZADO`…); la pantalla la traduce con
  /// `traducirError`.
  Future<Invitacion> invitar({
    required String email,
    required RolApp rol,
    required double cupoInicial,
  });

  /// Revoca una invitación pendiente.
  Future<Invitacion> revocar(String id);
}

class InvitacionesRepositorioSupabase implements InvitacionesRepositorio {
  const InvitacionesRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<List<Invitacion>> listar() async {
    final filas = await _cliente
        .from('invitaciones')
        .select(Invitacion.columnas)
        .order('creado_en', ascending: false);
    return [for (final fila in filas) Invitacion.desdeJson(fila)];
  }

  @override
  Future<Invitacion> invitar({
    required String email,
    required RolApp rol,
    required double cupoInicial,
  }) async {
    final fila = await _cliente.rpc<Map<String, dynamic>>(
      'invitar_usuario',
      params: {
        'p_email': email,
        'p_rol': rol.name,
        'p_cupo_inicial': cupoInicial,
      },
    );
    return Invitacion.desdeJson(fila);
  }

  @override
  Future<Invitacion> revocar(String id) async {
    final fila = await _cliente.rpc<Map<String, dynamic>>(
      'revocar_invitacion',
      params: {'p_id': id},
    );
    return Invitacion.desdeJson(fila);
  }
}

final invitacionesRepositorioProvider = Provider<InvitacionesRepositorio>(
  (ref) => InvitacionesRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

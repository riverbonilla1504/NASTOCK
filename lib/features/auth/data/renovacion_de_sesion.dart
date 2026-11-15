/// Renovación de Auth por un cambio de perfil (HU-011, docs/04 §8).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/cliente_supabase.dart';

/// El id evita renovar una sesión distinta si se cerró o cambió la cuenta.
final renovarSesionDePerfilProvider = Provider<Future<void> Function(String)>((
  ref,
) {
  final auth = ref.watch(clienteSupabaseProvider).auth;
  return (idUsuario) async {
    if (auth.currentUser?.id == idUsuario) await auth.refreshSession();
  };
});

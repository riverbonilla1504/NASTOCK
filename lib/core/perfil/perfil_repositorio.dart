/// Repositorio del perfil: único lugar de la app que lee `perfiles` y el token
/// de la sesión (docs/05 §9.1).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/cliente_supabase.dart';
import 'perfil.dart';

abstract interface class PerfilRepositorio {
  /// Los claims `app_rol` y `app_estado` del token actual (vacíos sin sesión).
  ClaimsDeSesion leerClaims();

  /// La fila de `perfiles` de quien tiene la sesión, o `null` si no hay sesión
  /// o la base de datos no la entrega (cuenta no activa o sin perfil).
  Future<Perfil?> leerPerfilPropio();

  /// Avisa cada vez que la sesión cambia: ingreso, cierre, renovación del
  /// token. No avisa de la sesión con que se arrancó.
  Stream<void> get cambiosDeSesion;
}

class PerfilRepositorioSupabase implements PerfilRepositorio {
  const PerfilRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  ClaimsDeSesion leerClaims() =>
      ClaimsDeSesion.desdeToken(_cliente.auth.currentSession?.accessToken);

  @override
  Future<Perfil?> leerPerfilPropio() async {
    final usuario = _cliente.auth.currentUser;
    if (usuario == null) return null;
    // Un supervisor lee todas las filas (docs/03 §4.3): se pide la propia por id.
    final fila = await _cliente
        .from('perfiles')
        .select(Perfil.columnas)
        .eq('id', usuario.id)
        .maybeSingle();
    return fila == null ? null : Perfil.desdeJson(fila);
  }

  @override
  Stream<void> get cambiosDeSesion => _cliente.auth.onAuthStateChange
      // Al suscribirse llega la sesión inicial: no es un cambio.
      .where((cambio) => cambio.event != AuthChangeEvent.initialSession)
      .map((_) {});
}

final perfilRepositorioProvider = Provider<PerfilRepositorio>(
  (ref) => PerfilRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

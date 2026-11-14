/// Repositorio del perfil: único lugar de la app que lee `perfiles` y el token
/// de la sesión (docs/05 §9.1).
library;

import 'dart:async';

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
  PerfilRepositorioSupabase(this._cliente);

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

  late final CambiosDeSesion _cambios = CambiosDeSesion(
    _cliente.auth.onAuthStateChange,
  );

  @override
  Stream<void> get cambiosDeSesion => _cambios.stream;

  /// Suelta la suscripción a Supabase.
  Future<void> cerrar() => _cambios.cerrar();
}

/// Reparte los cambios de sesión sin repetir la historia (EC-039).
///
/// `onAuthStateChange` de Supabase es un `ReplaySubject`: cada suscriptor
/// nuevo recibe otra vez todos los eventos anteriores. Quien se vuelve a
/// suscribir en cada reconstrucción (como `perfilProvider`) recibiría el
/// último `signedIn`, se invalidaría y volvería a suscribirse sin fin. Aquí
/// [origen] se escucha una sola vez y [stream] solo entrega lo que llega
/// después de cada suscripción.
class CambiosDeSesion {
  CambiosDeSesion(Stream<AuthState> origen) : _origen = origen;

  final Stream<AuthState> _origen;
  final StreamController<void> _salida = StreamController<void>.broadcast();
  StreamSubscription<AuthState>? _suscripcion;

  Stream<void> get stream {
    _suscripcion ??= _origen
        // Al arrancar llega la sesión inicial: no es un cambio.
        .where((cambio) => cambio.event != AuthChangeEvent.initialSession)
        .listen((_) => _salida.add(null));
    return _salida.stream;
  }

  Future<void> cerrar() async {
    await _suscripcion?.cancel();
    await _salida.close();
  }
}

final perfilRepositorioProvider = Provider<PerfilRepositorio>((ref) {
  final repositorio = PerfilRepositorioSupabase(
    ref.watch(clienteSupabaseProvider),
  );
  ref.onDispose(repositorio.cerrar);
  return repositorio;
});

/// Repositorio del ingreso: único lugar de `features/auth/` que habla con
/// Supabase Auth y con `google_sign_in` (docs/05 §9.1, docs/04 §4).
///
/// - Android: ingreso nativo, el `id_token` se canjea en Supabase.
/// - Web: redirección OAuth con PKCE y selector de cuenta, **sin `hd`**
///   (decisión del 2026-11-08: Gmail personal, no hay Workspace).
/// - Correo y contraseña: solo con `MODO_PRUEBAS` (CI y local); la pantalla no
///   lo ofrece de otro modo y en la nube el hook lo rechaza.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/configuracion/entorno.dart';
import '../../../core/errores/fallo_de_ingreso.dart';
import '../../../core/supabase/cliente_supabase.dart';
import '../domain/resultado_de_ingreso.dart';
import 'clasificador_de_fallos.dart';
import 'google_nativo.dart';

abstract interface class IngresoRepositorio {
  /// Ingresa con Google: nativo en Android, redirección en web. Lanza
  /// [FalloDeIngreso].
  Future<ResultadoDeIngreso> ingresarConGoogle();

  /// Ingresa con correo y contraseña. Solo con `MODO_PRUEBAS`. Lanza
  /// [FalloDeIngreso].
  Future<ResultadoDeIngreso> ingresarConCorreo(
    String correo,
    String contrasena,
  );

  /// Errores del flujo OAuth web al volver a la app (p. ej. el rechazo del
  /// hook), ya clasificados.
  Stream<FalloDeIngreso> get fallosDeRegreso;

  /// La sesión actual.
  Session? get sesionActual;

  /// Cada cambio de sesión (ingreso, cierre, renovación). Sin errores.
  Stream<Session?> get cambiosDeSesion;

  /// Cierra la sesión de `google_sign_in` (la llama HU-007); no toca la de
  /// Supabase.
  Future<void> cerrarSesionDeGoogle();
}

/// Lo que el repositorio usa de `GoTrueClient`, para probarlo con falsos.
abstract interface class ClienteDeAuth {
  Future<void> ingresarConIdToken({
    required String idToken,
    String? accessToken,
  });

  Future<void> ingresarConCorreo(String correo, String contrasena);

  /// Abre el flujo OAuth de Google. Devuelve `false` si no pudo abrirlo.
  Future<bool> ingresarConOAuthGoogle({
    required Map<String, String> parametros,
  });

  Stream<AuthState> get cambios;

  Session? get sesionActual;
}

class ClienteDeAuthSupabase implements ClienteDeAuth {
  const ClienteDeAuthSupabase(this._auth);

  final GoTrueClient _auth;

  @override
  Future<void> ingresarConIdToken({
    required String idToken,
    String? accessToken,
  }) async {
    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> ingresarConCorreo(String correo, String contrasena) async {
    await _auth.signInWithPassword(email: correo, password: contrasena);
  }

  @override
  Future<bool> ingresarConOAuthGoogle({
    required Map<String, String> parametros,
  }) {
    // Sin `redirectTo`: en web vuelve a la URL de la app, que debe estar en las
    // URLs de redirección permitidas de Supabase. PKCE es el flujo por omisión.
    return _auth.signInWithOAuth(OAuthProvider.google, queryParams: parametros);
  }

  @override
  Stream<AuthState> get cambios => _auth.onAuthStateChange;

  @override
  Session? get sesionActual => _auth.currentSession;
}

class IngresoRepositorioSupabase implements IngresoRepositorio {
  /// [google] es `null` en web (no usa `google_sign_in`). [esWeb] solo se
  /// reemplaza en las pruebas.
  IngresoRepositorioSupabase(this._auth, {this._google, bool? esWeb})
    : _esWeb = esWeb ?? kIsWeb;

  final ClienteDeAuth _auth;
  final ProveedorDeGoogleNativo? _google;
  final bool _esWeb;

  /// Obliga a elegir cuenta aunque haya una sesión de Google abierta.
  static const Map<String, String> parametrosDeWeb = {
    'prompt': 'select_account',
  };

  @override
  Future<ResultadoDeIngreso> ingresarConGoogle() async {
    try {
      if (_esWeb) {
        final abierto = await _auth.ingresarConOAuthGoogle(
          parametros: parametrosDeWeb,
        );
        if (!abierto) throw StateError('No se pudo abrir el ingreso de Google');
        return ResultadoDeIngreso.redirigido;
      }
      final google = _google;
      if (google == null) {
        throw StateError('Falta el ingreso nativo de Google');
      }
      final credencial = await google.autenticar();
      await _auth.ingresarConIdToken(
        idToken: credencial.idToken,
        accessToken: credencial.accessToken,
      );
      return ResultadoDeIngreso.exito;
    } on GoogleCanceladoException {
      return ResultadoDeIngreso.cancelado;
    } catch (error, pila) {
      throw clasificarFalloDeIngreso(error, pila);
    }
  }

  @override
  Future<ResultadoDeIngreso> ingresarConCorreo(
    String correo,
    String contrasena,
  ) async {
    try {
      await _auth.ingresarConCorreo(correo.trim(), contrasena);
      return ResultadoDeIngreso.exito;
    } catch (error, pila) {
      throw clasificarFalloDeIngreso(error, pila);
    }
  }

  @override
  Stream<FalloDeIngreso> get fallosDeRegreso => _auth.cambios.transform(
    StreamTransformer<AuthState, FalloDeIngreso>.fromHandlers(
      handleData: (_, _) {},
      handleError: (error, pila, sink) =>
          sink.add(clasificarFalloDeIngreso(error, pila)),
    ),
  );

  @override
  Session? get sesionActual => _auth.sesionActual;

  @override
  Stream<Session?> get cambiosDeSesion => _auth.cambios.transform(
    StreamTransformer<AuthState, Session?>.fromHandlers(
      handleData: (estado, sink) => sink.add(estado.session),
      // Un error del flujo OAuth no es un cambio de sesión: lo recoge
      // [fallosDeRegreso].
      handleError: (_, _, _) {},
    ),
  );

  @override
  Future<void> cerrarSesionDeGoogle() async => _google?.cerrarSesion();
}

/// El repositorio de ingreso de este arranque. Solo se lee con Supabase
/// configurado: la pantalla de ingreso deshabilita sus acciones sin ella.
final ingresoRepositorioProvider = Provider<IngresoRepositorio>((ref) {
  final entorno = ref.watch(entornoProvider);
  final cliente = ref.watch(clienteSupabaseProvider);
  return IngresoRepositorioSupabase(
    ClienteDeAuthSupabase(cliente.auth),
    google: kIsWeb
        ? null
        : ProveedorDeGoogleNativoReal(entorno.googleWebClientId),
  );
});

/// Ingreso nativo de Google en Android con `google_sign_in` 7 (docs/04 §4.4).
///
/// La API de la versión 7 es otra (EC-018): `GoogleSignIn.instance`,
/// `initialize` una sola vez, `authenticate`, y la autorización de los alcances
/// por separado. Se sigue la guía vigente de Supabase para Flutter: el
/// `id_token` y el `accessToken` de `email` y `profile` van a
/// `signInWithIdToken`.
library;

import 'package:google_sign_in/google_sign_in.dart';

/// Lo que Google entrega y Supabase canjea por una sesión.
class CredencialDeGoogle {
  const CredencialDeGoogle({required this.idToken, this.accessToken});

  final String idToken;
  final String? accessToken;
}

/// La persona cerró la ventana de Google. No es un fallo (docs/04 §11).
class GoogleCanceladoException implements Exception {
  const GoogleCanceladoException();

  @override
  String toString() => 'GoogleCanceladoException()';
}

/// Envoltura de `GoogleSignIn.instance`, para probar el repositorio con falsos.
abstract interface class ProveedorDeGoogleNativo {
  /// Abre el selector de cuentas de Google y devuelve su credencial. Lanza
  /// [GoogleCanceladoException] si la persona lo cierra.
  Future<CredencialDeGoogle> autenticar();

  /// Cierra la sesión de `google_sign_in` para que el siguiente ingreso
  /// permita elegir cuenta (docs/04 §4.5). No cierra la sesión de Supabase.
  Future<void> cerrarSesion();
}

const List<String> _alcances = ['email', 'profile'];

class ProveedorDeGoogleNativoReal implements ProveedorDeGoogleNativo {
  const ProveedorDeGoogleNativoReal(this._serverClientId);

  /// El ID del cliente OAuth **Web** (`GOOGLE_WEB_CLIENT_ID`).
  final String _serverClientId;

  /// `initialize` se llama exactamente una vez (google_sign_in 7.1.1).
  static Future<void>? _iniciado;

  Future<void> _iniciar() {
    return _iniciado ??= GoogleSignIn.instance
        .initialize(serverClientId: _serverClientId)
        .onError((error, pila) {
          _iniciado = null; // permite reintentar tras un fallo de arranque
          Error.throwWithStackTrace(error!, pila);
        });
  }

  @override
  Future<CredencialDeGoogle> autenticar() async {
    await _iniciar();
    try {
      final cuenta = await GoogleSignIn.instance.authenticate();
      final idToken = cuenta.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google no entregó el id_token');
      }
      final autorizacion =
          await cuenta.authorizationClient.authorizationForScopes(_alcances) ??
          await cuenta.authorizationClient.authorizeScopes(_alcances);
      return CredencialDeGoogle(
        idToken: idToken,
        accessToken: autorizacion.accessToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleCanceladoException();
      }
      rethrow;
    }
  }

  @override
  Future<void> cerrarSesion() async {
    await _iniciar();
    await GoogleSignIn.instance.signOut();
  }
}

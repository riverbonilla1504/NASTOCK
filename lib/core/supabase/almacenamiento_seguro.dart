/// Sesión de `supabase_flutter` en el almacenamiento seguro del sistema
/// (docs/04 §8, FR-026).
///
/// En móvil la sesión (con su refresh token) se guarda en el Keystore de
/// Android, no en preferencias planas. En web se queda el almacenamiento del
/// navegador por omisión: es inevitable y se mitiga con el JWT de 15 minutos.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show LocalStorage;

/// Clave bajo la que se guarda la sesión serializada.
const String claveDeSesionSegura = 'supabase.auth.token';

/// [LocalStorage] de `supabase_flutter` sobre `flutter_secure_storage`.
class AlmacenamientoSeguroDeSesion extends LocalStorage {
  /// [almacen] solo se reemplaza en las pruebas.
  AlmacenamientoSeguroDeSesion([FlutterSecureStorage? almacen])
    : _almacen = almacen ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacen;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() =>
      _almacen.containsKey(key: claveDeSesionSegura);

  @override
  Future<String?> accessToken() => _almacen.read(key: claveDeSesionSegura);

  @override
  Future<void> removePersistedSession() =>
      _almacen.delete(key: claveDeSesionSegura);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _almacen.write(key: claveDeSesionSegura, value: persistSessionString);
}

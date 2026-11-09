/// Los canales de tiempo real y quién abre cuáles (docs/09 §3).
///
/// Todos son privados y solo la base de datos publica en ellos. La política
/// `canales_permitidos` de `realtime.messages` (HU-083) es la que autoriza de
/// verdad; esta lista solo decide qué pide la app, según el rol, para no
/// suscribirse a canales que la base de datos le negaría.
library;

import '../perfil/perfil.dart';

/// Nombres de los canales de docs/09 §3.
abstract final class Canales {
  static const String mercado = 'mercado';
  static const String fondo = 'fondo';
  static const String supervision = 'supervision';
  static const String admin = 'admin';

  /// El canal personal de [idUsuario].
  static String usuario(String idUsuario) => 'usuario:$idUsuario';
}

/// Los canales que abre [rol] al iniciar sesión (docs/09 §3):
///
/// ```
/// todos:     mercado, fondo, usuario:{mi id}
/// analista:  + supervision
/// admin:     + supervision, admin
/// ```
List<String> canalesDeRol(RolApp rol, String idUsuario) => [
  Canales.mercado,
  Canales.fondo,
  Canales.usuario(idUsuario),
  if (rol == RolApp.analista || rol == RolApp.administrador)
    Canales.supervision,
  if (rol == RolApp.administrador) Canales.admin,
];

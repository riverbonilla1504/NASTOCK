/// Lo que la app sabe para decidir adónde puede ir quien tiene la sesión: si
/// hay sesión y el rol y el estado que trae el token (docs/03 §4.1, docs/04 §7).
///
/// Es para la interfaz: la seguridad real la imponen RLS y RPC, que consultan
/// `perfiles` en cada operación. Los claims pueden tardar hasta 15 minutos en
/// reflejar un cambio de rol o de estado (docs/04 §8).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/acceso_por_rol.dart';
import '../../../core/perfil/perfil.dart';
import 'sesion_provider.dart';

class AccesoDeSesion {
  const AccesoDeSesion({
    required this.haySesion,
    this.claims = ClaimsDeSesion.vacios,
  });

  /// Nadie ha ingresado.
  static const AccesoDeSesion sinSesion = AccesoDeSesion(haySesion: false);

  final bool haySesion;

  /// `app_rol` y `app_estado` del token. Sin sesión, o con un token sin esos
  /// claims, vienen vacíos.
  final ClaimsDeSesion claims;

  RolApp? get rol => claims.rol;
  EstadoCuenta? get estado => claims.estado;

  /// Con sesión, `app_estado` activo.
  bool get activo => haySesion && estado == EstadoCuenta.activo;

  // Igualdad por valor: el token se renueva cada pocos minutos con otro objeto
  // `Session`, y eso no debe reconstruir el menú ni reevaluar las guardas si el
  // rol y el estado no cambiaron.
  @override
  bool operator ==(Object other) =>
      other is AccesoDeSesion &&
      other.haySesion == haySesion &&
      other.rol == rol &&
      other.estado == estado;

  @override
  int get hashCode => Object.hash(haySesion, rol, estado);
}

/// El acceso de la sesión actual. Cambia al ingresar, al cerrar sesión y cuando
/// un token renovado trae otro rol u otro estado.
final accesoDeSesionProvider = Provider<AccesoDeSesion>((ref) {
  final sesion = ref.watch(sesionProvider);
  if (sesion == null) return AccesoDeSesion.sinSesion;
  return AccesoDeSesion(
    haySesion: true,
    claims: ClaimsDeSesion.desdeToken(sesion.accessToken),
  );
});

/// Qué puede hacer la persona de la sesión en [ruta]: lo consulta una pantalla
/// para deshabilitar sus acciones cuando el acceso es `soloLectura` (el
/// Administrador en la Bandeja de riesgo, CA-4).
final accesoDeRutaProvider = Provider.family<AccesoDeRuta, String>(
  (ref, ruta) => accesoDeRuta(ref.watch(accesoDeSesionProvider).rol, ruta),
);

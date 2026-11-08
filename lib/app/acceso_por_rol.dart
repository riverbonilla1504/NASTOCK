/// Política de acceso por rol y guarda del enrutador (docs/03 §3, docs/05 §9.3,
/// FR-021).
///
/// Es **experiencia de uso**, no seguridad: la app oculta lo que un rol no
/// puede usar y lleva a la persona a donde sí puede estar, pero quien impone
/// los permisos es la base de datos (RLS y RPC, docs/03 §4). Por eso decide con
/// los claims del token, que pueden tardar hasta 15 minutos en reflejar un
/// cambio de rol o de estado (docs/04 §8).
///
/// Son funciones puras: se prueban sin pantallas.
library;

import '../core/perfil/perfil.dart';
import 'catalogo/pagina_catalogo.dart';
import 'destinos.dart';
import 'rutas.dart';

/// Qué puede hacer un rol en una ruta.
enum AccesoDeRuta {
  /// Entra normalmente.
  permitido,

  /// Entra y la pantalla deshabilita sus acciones (el Administrador en la
  /// Bandeja de riesgo, docs/03 §3).
  soloLectura,

  /// El enrutador lo lleva a `/inicio`.
  denegado,
}

/// El acceso de [rol] a [ruta].
///
/// - `/inicio` es de todos, también de un rol desconocido: así la guarda nunca
///   entra en un ciclo.
/// - `/riesgo` y `/riesgo/*`: el Analista opera; el Administrador solo mira.
/// - Las rutas de un destino del menú, para los roles de ese destino.
/// - Cualquier otra, denegada.
AccesoDeRuta accesoDeRuta(RolApp? rol, String ruta) {
  if (Rutas.esRutaDe(ruta, Rutas.inicio)) return AccesoDeRuta.permitido;

  if (Rutas.esRutaDe(ruta, Rutas.riesgo)) {
    return switch (rol) {
      RolApp.analista => AccesoDeRuta.permitido,
      RolApp.administrador => AccesoDeRuta.soloLectura,
      RolApp.usuario || null => AccesoDeRuta.denegado,
    };
  }

  final destino = destinoDeRuta(ruta);
  if (destino != null && rol != null && destino.roles.contains(rol)) {
    return AccesoDeRuta.permitido;
  }
  return AccesoDeRuta.denegado;
}

/// A dónde hay que ir desde [ruta] según la sesión, o `null` si se queda
/// (docs/05 §9.3).
///
/// ```
/// catálogo de componentes                         → se queda
/// sin sesión                                      → /ingreso
/// con sesión y app_estado distinto de activo      → /cuenta-suspendida
///   (también un token sin ese claim: es lo seguro)
/// con sesión activa en /ingreso o en /cuenta-suspendida → /inicio
/// con sesión activa y sin acceso a la ruta        → /inicio
/// ```
String? redirigirSegunAcceso({
  required String ruta,
  required bool haySesion,
  required ClaimsDeSesion claims,
}) {
  // El catálogo de componentes es una herramienta, no una pantalla de la app.
  if (Rutas.esRutaDe(ruta, RutasCatalogo.inicio)) return null;

  if (!haySesion) return ruta == Rutas.ingreso ? null : Rutas.ingreso;

  if (claims.estado != EstadoCuenta.activo) {
    return ruta == Rutas.cuentaSuspendida ? null : Rutas.cuentaSuspendida;
  }

  if (ruta == Rutas.ingreso || ruta == Rutas.cuentaSuspendida) {
    return Rutas.inicio;
  }
  if (accesoDeRuta(claims.rol, ruta) == AccesoDeRuta.denegado) {
    return Rutas.inicio;
  }
  return null;
}

/// Rutas de la app (docs/05 §9.3). Cada historia agrega las suyas aquí.
///
/// Solo `/inicio`, `/ingreso`, `/cuenta-suspendida`, `/admin/*` y `/riesgo/*`
/// están en `docs/05` §9.3; las demás son decisión de implementación y se
/// anotan en `docs/17`.
library;

abstract final class Rutas {
  static const String ingreso = '/ingreso';
  static const String cuentaSuspendida = '/cuenta-suspendida';

  /// Mercado, la pantalla de inicio de los tres roles (HU-030).
  static const String inicio = '/inicio';
  static const String oportunidades = '/oportunidades';
  static const String cupo = '/cupo';
  static const String alertas = '/alertas';

  /// Administración y sus subrutas (`/admin/usuarios`, HU-003).
  static const String admin = '/admin';

  /// Invitaciones del Administrador (HU-003); la pantalla "Usuarios e
  /// invitaciones" de HU-098 vive en la misma ruta.
  static const String adminUsuarios = '/admin/usuarios';

  /// Cupos del Administrador (HU-100): asignar y reducir.
  static const String adminCupos = '/admin/cupos';

  /// Bandeja de riesgo: no existe en el MVP corto, pero su regla de acceso sí
  /// (Analista permitido, Administrador en solo lectura).
  static const String riesgo = '/riesgo';

  /// Si [ruta] es [base] o una subruta suya (`/admin` y `/admin/usuarios`, no
  /// `/administracion`).
  static bool esRutaDe(String ruta, String base) =>
      ruta == base || ruta.startsWith('$base/');
}

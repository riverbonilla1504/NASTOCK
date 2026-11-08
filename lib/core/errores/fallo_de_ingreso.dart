/// Fallos del ingreso y su mensaje en español (docs/04 §11, FR-022).
///
/// El ingreso no usa el catálogo de códigos de 06 §9: sus fallos vienen de
/// Supabase Auth y del hook "antes de crear usuario", así que tienen su propio
/// tipo. Nunca se muestra el texto crudo de una excepción: lo que llega del
/// servidor solo se muestra cuando es un rechazo del hook ya reconocido
/// (ver `clasificarFalloDeIngreso`).
library;

/// Situaciones de fallo de `docs/04` §11 que ve la persona.
///
/// Cerrar la ventana de Google no es un fallo: se vuelve a la pantalla de
/// ingreso sin mensaje. Una cuenta fuera de la lista de usuarios de prueba de
/// Google la rechaza Google y no llega a la app.
enum TipoDeFalloDeIngreso {
  /// Sin invitación, invitación vencida o revocada.
  sinInvitacion,

  /// Dominio fuera de `auth.dominios_permitidos`.
  dominioNoPermitido,

  /// Proveedor fuera de `auth.proveedores_permitidos`.
  proveedorNoPermitido,

  /// Cuenta suspendida o de baja (Auth la bloquea).
  cuentaSuspendida,

  /// Sin conexión.
  sinConexion,

  /// Cualquier otro error: el detalle va al registro técnico, no a la pantalla.
  inesperado,
}

/// Texto propio de cada tipo (docs/04 §11 con los ajustes del 2026-11-08: sin
/// "corporativa" ni "de RiTech").
const Map<TipoDeFalloDeIngreso, String> mensajesDeIngreso = {
  TipoDeFalloDeIngreso.sinInvitacion:
      'Tu correo no tiene una invitación vigente. Pídele una al administrador.',
  TipoDeFalloDeIngreso.dominioNoPermitido:
      'Solo se admiten cuentas de Google invitadas.',
  TipoDeFalloDeIngreso.proveedorNoPermitido:
      'Solo puedes ingresar con tu cuenta de Google.',
  TipoDeFalloDeIngreso.cuentaSuspendida:
      'Tu cuenta está suspendida. Comunícate con el administrador.',
  TipoDeFalloDeIngreso.sinConexion:
      'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
  TipoDeFalloDeIngreso.inesperado:
      'No pudimos iniciar tu sesión. Inténtalo de nuevo.',
};

/// Un ingreso que falló, ya clasificado.
class FalloDeIngreso implements Exception {
  const FalloDeIngreso(this.tipo, {this.textoDelServidor});

  final TipoDeFalloDeIngreso tipo;

  /// Mensaje que mandó el servidor. Solo cuenta si [tipo] es un rechazo del
  /// hook; en cualquier otro caso se ignora y nunca se muestra.
  final String? textoDelServidor;

  /// Si el servidor rechazó el alta por una de las reglas del hook.
  bool get esRechazoDelHook =>
      tipo == TipoDeFalloDeIngreso.sinInvitacion ||
      tipo == TipoDeFalloDeIngreso.dominioNoPermitido ||
      tipo == TipoDeFalloDeIngreso.proveedorNoPermitido;

  /// Lo que ve la persona: el texto del servidor en un rechazo del hook (así un
  /// cambio de redacción no obliga a tocar la app) y, si no lo trae, el propio.
  String get mensaje {
    final servidor = textoDelServidor?.trim();
    if (esRechazoDelHook && servidor != null && servidor.isNotEmpty) {
      return servidor;
    }
    return mensajesDeIngreso[tipo]!;
  }

  @override
  String toString() => 'FalloDeIngreso($tipo)';
}

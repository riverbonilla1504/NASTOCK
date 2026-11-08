/// Invitación a una persona (docs/06 §5.1, docs/08 §5).
///
/// Modelo inmutable de una fila de `invitaciones`. La app la lee con la RLS del
/// Administrador y la escribe solo por las RPC `invitar_usuario` y
/// `revocar_invitacion` (docs/03 §4.4).
library;

import '../../../../core/perfil/perfil.dart';

/// Estado guardado de una invitación (docs/06 §3).
enum EstadoInvitacion {
  pendiente,
  aceptada,
  revocada,
  vencida;

  /// El estado que nombra [texto] o `null` si es nulo o desconocido.
  static EstadoInvitacion? desdeTexto(Object? texto) {
    for (final estado in values) {
      if (estado.name == texto) return estado;
    }
    return null;
  }
}

class Invitacion {
  const Invitacion({
    required this.id,
    required this.email,
    required this.rol,
    required this.cupoInicial,
    required this.estado,
    required this.expiraEn,
    required this.creadoEn,
    this.aceptadaEn,
    this.revocadaEn,
  });

  /// Columnas de `invitaciones` que lee la app.
  static const String columnas =
      'id, email, rol, cupo_inicial, estado, expira_en, creado_en, '
      'aceptada_en, revocada_en';

  /// Arma la invitación con una fila de `invitaciones` (las [columnas] de
  /// arriba) o con lo que devuelve una de las RPC, que es la misma fila.
  ///
  /// Lanza [FormatException] si la fila trae un rol o un estado desconocidos:
  /// mejor fallar que mostrar algo inventado.
  factory Invitacion.desdeJson(Map<String, dynamic> json) {
    final rol = RolApp.desdeTexto(json['rol']);
    final estado = EstadoInvitacion.desdeTexto(json['estado']);
    if (rol == null || estado == null) {
      throw const FormatException(
        'La fila de invitaciones trae un rol o un estado desconocido.',
      );
    }
    return Invitacion(
      id: json['id'] as String,
      email: json['email'] as String,
      rol: rol,
      cupoInicial: (json['cupo_inicial'] as num).toDouble(),
      estado: estado,
      expiraEn: DateTime.parse(json['expira_en'] as String),
      creadoEn: DateTime.parse(json['creado_en'] as String),
      aceptadaEn: _fechaOpcional(json['aceptada_en']),
      revocadaEn: _fechaOpcional(json['revocada_en']),
    );
  }

  final String id;
  final String email;
  final RolApp rol;

  /// Solo una intención hasta que la persona entra (docs/02 §11, RN-18).
  final double cupoInicial;
  final EstadoInvitacion estado;

  /// Siete días después de crearse (docs/08 §5).
  final DateTime expiraEn;
  final DateTime creadoEn;
  final DateTime? aceptadaEn;
  final DateTime? revocadaEn;

  /// El estado que ve la persona: una pendiente que ya pasó su fecha está
  /// vencida aunque la base todavía la guarde como pendiente (docs/08 §5).
  EstadoInvitacion estadoVisible(DateTime ahora) =>
      estado == EstadoInvitacion.pendiente && !expiraEn.isAfter(ahora)
      ? EstadoInvitacion.vencida
      : estado;

  /// Vigente: pendiente y sin haber pasado su fecha. Solo una vigente se
  /// ofrece para revocar.
  bool estaVigente(DateTime ahora) =>
      estadoVisible(ahora) == EstadoInvitacion.pendiente;
}

DateTime? _fechaOpcional(Object? valor) =>
    valor == null ? null : DateTime.parse(valor as String);

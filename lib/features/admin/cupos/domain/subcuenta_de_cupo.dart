/// Una subcuenta de la bolsa de Usuarios: la bolsa común o el cupo de una
/// persona (docs/06 §4, HU-100). El Administrador las lee con su RLS.
library;

enum TipoDeSubcuentaDeUsuarios { usuariosComun, cupo }

class SubcuentaDeCupo {
  const SubcuentaDeCupo({
    required this.id,
    required this.tipo,
    required this.efectivo,
    required this.retenido,
    required this.invertido,
    required this.version,
    this.usuarioId,
    this.titular,
    this.correo,
  });

  /// Columnas que pide la lectura, con el titular de un cupo embebido.
  static const String columnas =
      'id, tipo, usuario_id, efectivo, retenido, invertido, version, '
      'perfiles(nombre, email)';

  factory SubcuentaDeCupo.desdeJson(Map<String, dynamic> json) {
    final perfil = json['perfiles'];
    return SubcuentaDeCupo(
      id: json['id'] as String,
      tipo: json['tipo'] == 'cupo'
          ? TipoDeSubcuentaDeUsuarios.cupo
          : TipoDeSubcuentaDeUsuarios.usuariosComun,
      usuarioId: json['usuario_id'] as String?,
      titular: perfil is Map ? perfil['nombre'] as String? : null,
      correo: perfil is Map ? perfil['email'] as String? : null,
      efectivo: _numero(json['efectivo']),
      retenido: _numero(json['retenido']),
      invertido: _numero(json['invertido']),
      version: (json['version'] as num?)?.toInt(),
    );
  }

  final String id;
  final TipoDeSubcuentaDeUsuarios tipo;

  /// Dueño del cupo; nulo en la bolsa común.
  final String? usuarioId;
  final String? titular;
  final String? correo;
  final double efectivo;
  final double retenido;
  final double invertido;
  final int? version;

  bool get esCupo => tipo == TipoDeSubcuentaDeUsuarios.cupo;

  /// `efectivo − retenido` (docs/02 §2).
  double get disponible => efectivo - retenido;

  /// Efectivo más lo invertido a costo, hasta que existan las posiciones
  /// valoradas (misma regla que `mi_cupo()`, HU-019).
  double get patrimonio => efectivo + invertido;

  static double _numero(Object? valor) => switch (valor) {
    num() => valor.toDouble(),
    String() => double.parse(valor),
    _ => 0,
  };
}

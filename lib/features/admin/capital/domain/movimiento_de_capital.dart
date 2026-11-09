/// Movimiento de capital (docs/06 §4.3): un aporte o un retiro.
///
/// Modelo inmutable de una fila de `movimientos_capital`. La app la lee con la
/// RLS de Analista y Administrador y la escribe solo por las RPC
/// `registrar_aporte` y `anular_aporte` (docs/03 §4.4).
library;

/// Estado guardado de un movimiento de capital (docs/06 §3).
enum EstadoMovCapital {
  registrado,
  confirmado,
  anulado;

  /// El estado que nombra [texto] o `null` si es nulo o desconocido.
  static EstadoMovCapital? desdeTexto(Object? texto) {
    for (final estado in values) {
      if (estado.name == texto) return estado;
    }
    return null;
  }
}

class MovimientoDeCapital {
  const MovimientoDeCapital({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.estado,
    required this.registradoEn,
    this.referencia,
    this.nota,
    this.registradoPor,
    this.confirmadoEn,
    this.anuladoEn,
    this.motivoAnulacion,
  });

  /// Columnas que lee la app, con el nombre de quien registró.
  static const String columnas =
      'id, tipo, monto, estado, referencia_externa, nota, registrado_en, '
      'confirmado_en, anulado_en, motivo_anulacion, '
      'registrador:perfiles!registrado_por(nombre)';

  /// Arma el movimiento con una fila de [columnas] o con lo que devuelve una
  /// RPC (la fila sin el nombre de quien registró).
  ///
  /// Lanza [FormatException] si trae un estado desconocido: mejor fallar que
  /// mostrar algo inventado.
  factory MovimientoDeCapital.desdeJson(Map<String, dynamic> json) {
    final estado = EstadoMovCapital.desdeTexto(json['estado']);
    if (estado == null) {
      throw const FormatException(
        'La fila de movimientos_capital trae un estado desconocido.',
      );
    }
    final registrador = json['registrador'];
    return MovimientoDeCapital(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      monto: (json['monto'] as num).toDouble(),
      estado: estado,
      referencia: json['referencia_externa'] as String?,
      nota: json['nota'] as String?,
      registradoPor: registrador is Map
          ? registrador['nombre'] as String?
          : null,
      registradoEn: DateTime.parse(json['registrado_en'] as String),
      confirmadoEn: _fecha(json['confirmado_en']),
      anuladoEn: _fecha(json['anulado_en']),
      motivoAnulacion: json['motivo_anulacion'] as String?,
    );
  }

  final String id;

  /// `aporte` o `retiro`. El MVP corto solo trabaja con aportes (D-58).
  final String tipo;
  final double monto;
  final EstadoMovCapital estado;

  /// Id de la transferencia o `paper-inicial`.
  final String? referencia;
  final String? nota;

  /// Nombre de quien lo registró.
  final String? registradoPor;
  final DateTime registradoEn;
  final DateTime? confirmadoEn;
  final DateTime? anuladoEn;
  final String? motivoAnulacion;

  /// Solo un aporte registrado se puede anular (RN-10).
  bool get sePuedeAnular =>
      tipo == 'aporte' && estado == EstadoMovCapital.registrado;
}

DateTime? _fecha(Object? valor) =>
    valor == null ? null : DateTime.parse(valor as String);

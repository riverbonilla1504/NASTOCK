/// Posiciones de mi cupo y su protección (HU-091, docs/06 §5.4, docs/02 §6).
///
/// Las filas vienen de `posiciones` y `protecciones` por la API: la RLS entrega
/// solo las de mi cupo (CA-4). El valor y la ganancia no realizada **no son
/// contables** (RN-06): se calculan al vuelo con el último precio.
library;

/// Protección de una posición: stop-loss y, si existe, take-profit.
class ProteccionDePosicion {
  const ProteccionDePosicion({
    required this.id,
    required this.tipo,
    required this.estado,
    required this.stopPrecio,
    this.objetivoPrecio,
  });

  factory ProteccionDePosicion.desdeJson(Map<String, dynamic> json) =>
      ProteccionDePosicion(
        id: json['id'] as String,
        tipo: json['tipo'] as String,
        estado: json['estado'] as String,
        stopPrecio: _numero(json['stop_precio']),
        objetivoPrecio: json['objetivo_precio'] == null
            ? null
            : _numero(json['objetivo_precio']),
      );

  static const String columnas =
      'id, posicion_id, tipo, estado, stop_precio, objetivo_precio, creado_en';

  final String id;

  /// `nativa` o `virtual` (en el MVP corto solo nativas, D-63).
  final String tipo;

  /// `pendiente`, `activa`, `disparada`, `cancelada` o `reemplazada`.
  final String estado;
  final double stopPrecio;
  final double? objetivoPrecio;

  String get etiquetaDelTipo => tipo == 'virtual' ? 'Virtual' : 'Nativa';

  String get etiquetaDelEstado => switch (estado) {
    'activa' => 'Activa',
    'pendiente' => 'Pendiente',
    'disparada' => 'Disparada',
    'cancelada' => 'Cancelada',
    'reemplazada' => 'Reemplazada',
    _ => estado,
  };
}

/// Una posición abierta de mi cupo.
class PosicionDeCupo {
  const PosicionDeCupo({
    required this.id,
    required this.simbolo,
    required this.cantidad,
    required this.costoPromedio,
    required this.costoTotal,
    required this.resultadoRealizado,
    required this.version,
    this.proteccion,
  });

  factory PosicionDeCupo.desdeJson(
    Map<String, dynamic> json, {
    ProteccionDePosicion? proteccion,
  }) => PosicionDeCupo(
    id: json['id'] as String,
    simbolo: json['simbolo'] as String,
    cantidad: _numero(json['cantidad']),
    costoPromedio: _numero(json['costo_promedio']),
    costoTotal: _numero(json['costo_total']),
    resultadoRealizado: _numero(json['resultado_realizado']),
    version: (json['version'] as num?)?.toInt(),
    proteccion: proteccion,
  );

  static const String columnas =
      'id, subcuenta_id, simbolo, cantidad, costo_promedio, costo_total, '
      'resultado_realizado, estado, version';

  final String id;
  final String simbolo;
  final double cantidad;
  final double costoPromedio;

  /// Lo que costó lo que queda (docs/06 §5.4).
  final double costoTotal;
  final double resultadoRealizado;
  final int? version;

  /// La protección vigente (pendiente o activa), o `null` si no tiene.
  final ProteccionDePosicion? proteccion;

  PosicionDeCupo conProteccion(ProteccionDePosicion? nueva) => PosicionDeCupo(
    id: id,
    simbolo: simbolo,
    cantidad: cantidad,
    costoPromedio: costoPromedio,
    costoTotal: costoTotal,
    resultadoRealizado: resultadoRealizado,
    version: version,
    proteccion: nueva,
  );
}

/// Una posición valorada con el último precio (RN-06).
class PosicionValorada {
  const PosicionValorada({
    required this.posicion,
    this.precio,
    this.momentoDelPrecio,
  });

  final PosicionDeCupo posicion;

  /// Último precio conocido, o `null` si todavía no hay cotización.
  final double? precio;

  /// Hora del precio según el proveedor.
  final DateTime? momentoDelPrecio;

  /// `cantidad × precio`, o `null` sin precio.
  double? get valor =>
      precio == null ? null : _aCentavos(posicion.cantidad * precio!);

  /// `valor − costo`: la ganancia o pérdida no realizada, o `null` sin precio.
  double? get noRealizado =>
      valor == null ? null : _aCentavos(valor! - posicion.costoTotal);

  /// La misma ganancia en porcentaje del costo, o `null` sin precio o sin costo.
  double? get noRealizadoPct => noRealizado == null || posicion.costoTotal == 0
      ? null
      : noRealizado! / posicion.costoTotal * 100;
}

double _aCentavos(double valor) => (valor * 100).round() / 100;

double _numero(Object? valor) => switch (valor) {
  num() => valor.toDouble(),
  String() => double.parse(valor),
  _ => 0,
};

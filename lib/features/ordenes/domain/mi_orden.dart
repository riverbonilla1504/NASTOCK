class MiOrden {
  const MiOrden({
    required this.id,
    required this.simbolo,
    required this.lado,
    required this.estado,
    required this.cantidad,
    required this.llenada,
    required this.retencion,
    required this.creadaEn,
    this.cancelacionSolicitada = false,
    this.version = 1,
  });
  factory MiOrden.desdeJson(Map<String, dynamic> json) => MiOrden(
    id: json['id'] as String,
    simbolo: json['simbolo'] as String,
    lado: json['lado'] as String,
    estado: json['estado'] as String,
    cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
    llenada: (json['cantidad_llenada'] as num).toDouble(),
    retencion: (json['retencion'] as num).toDouble(),
    creadaEn: DateTime.parse(json['creado_en'] as String),
    cancelacionSolicitada: json['cancelacion_solicitada_en'] != null,
    version: json['version'] as int,
  );
  final String id, simbolo, lado, estado;
  final double cantidad, llenada, retencion;
  final DateTime creadaEn;
  final bool cancelacionSolicitada;
  final int version;
  bool get puedeCancelar =>
      !cancelacionSolicitada &&
      const [
        'creada',
        'enviada',
        'aceptada',
        'parcialmente_llenada',
        'desconocida',
      ].contains(estado);
  String get etiqueta => switch (estado) {
    'parcialmente_llenada' => 'Parcialmente llenada',
    'error_envio' => 'Error de envío',
    _ => '${estado[0].toUpperCase()}${estado.substring(1)}',
  };
}

/// El cupo de la persona, tal como lo entrega la RPC `mi_cupo()` (docs/06 §6,
/// HU-019). Todas las cifras las calcula el servidor; la app solo las muestra.
library;

class MiCupo {
  const MiCupo({
    required this.id,
    required this.efectivo,
    required this.retenido,
    required this.disponible,
    required this.invertido,
    required this.patrimonio,
    required this.resultadoRealizado,
    required this.resultadoNoRealizado,
    required this.rendimiento,
    required this.fondoConCapital,
    required this.version,
  });

  factory MiCupo.desdeJson(Map<String, dynamic> json) => MiCupo(
    id: json['subcuenta_id'] as String,
    efectivo: _numero(json['efectivo']),
    retenido: _numero(json['retenido']),
    disponible: _numero(json['disponible']),
    invertido: _numero(json['invertido']),
    patrimonio: _numero(json['patrimonio']),
    resultadoRealizado: _numero(json['resultado_realizado']),
    resultadoNoRealizado: _numero(json['resultado_no_realizado']),
    rendimiento: json['rendimiento'] == null
        ? null
        : _numero(json['rendimiento']),
    fondoConCapital: json['fondo_con_capital'] as bool? ?? false,
    version: (json['version'] as num?)?.toInt(),
  );

  /// Identificador de la subcuenta de cupo (el `id` de los eventos `cupo`).
  final String id;
  final double efectivo;
  final double retenido;

  /// `efectivo − retenido`: lo que se puede invertir (docs/02 §2).
  final double disponible;
  final double invertido;
  final double patrimonio;
  final double resultadoRealizado;
  final double resultadoNoRealizado;

  /// Rendimiento TWR del cupo como fracción (0,05 = 5 %); `null` mientras no
  /// haya fotos diarias (HU-021).
  final double? rendimiento;

  /// Falso antes del primer aporte: la app muestra "Fondo sin capital" (CB-80).
  final bool fondoConCapital;
  final int? version;

  static double _numero(Object? valor) => switch (valor) {
    num() => valor.toDouble(),
    String() => double.parse(valor),
    _ => 0,
  };
}

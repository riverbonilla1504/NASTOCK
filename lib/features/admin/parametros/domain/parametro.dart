/// Modelos de la pantalla de Parámetros e Interruptores (HU-101, docs/02 §10,
/// docs/06 §4 y §5.6). La app solo muestra y envía: los valida la base de datos.
library;

/// Un parámetro del catálogo de docs/02 §10.
class Parametro {
  const Parametro({
    required this.clave,
    required this.valor,
    required this.tipo,
    required this.descripcion,
    this.minimo,
    this.maximo,
    this.version,
  });

  static const String columnas =
      'clave, valor, tipo, minimo, maximo, descripcion, version';

  factory Parametro.desdeJson(Map<String, dynamic> json) => Parametro(
    clave: json['clave'] as String,
    valor: json['valor'],
    tipo: json['tipo'] as String,
    minimo: (json['minimo'] as num?)?.toDouble(),
    maximo: (json['maximo'] as num?)?.toDouble(),
    descripcion: json['descripcion'] as String? ?? '',
    version: (json['version'] as num?)?.toInt(),
  );

  final String clave;

  /// El valor JSON: número, texto, booleano, lista o nulo.
  final Object? valor;

  /// `numero`, `texto`, `lista` o `booleano`.
  final String tipo;
  final String descripcion;
  final double? minimo;
  final double? maximo;
  final int? version;

  /// El tema es la primera parte de la clave (`riesgo.cupo.stop_min_pct` →
  /// `riesgo`).
  String get tema => clave.split('.').first;

  bool get esReparto => clave.startsWith('reparto.pct_');

  /// El rango en texto, o `null` si no tiene.
  String? get rango {
    if (tipo != 'numero' || (minimo == null && maximo == null)) return null;
    String n(double v) => v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toString().replaceAll('.', ',');
    if (minimo != null && maximo != null) {
      return '${n(minimo!)} a ${n(maximo!)}';
    }
    return minimo != null ? 'desde ${n(minimo!)}' : 'hasta ${n(maximo!)}';
  }

  /// El valor tal como se lee en pantalla.
  String get valorEnTexto => textoDeValor(valor);
}

/// Un valor JSON en texto legible: `20` → `20`, `0.65` → `0,65`, `null` →
/// `Sin límite`, una lista → sus elementos separados por coma.
String textoDeValor(Object? valor) => switch (valor) {
  null => 'Sin límite',
  bool() => valor ? 'Sí' : 'No',
  num() =>
    valor == valor.roundToDouble()
        ? valor.toInt().toString()
        : valor.toString().replaceAll('.', ','),
  List() => valor.isEmpty ? '(vacía)' : valor.join(', '),
  _ => valor.toString(),
};

/// Un cambio guardado en el historial de un parámetro.
class CambioDeParametro {
  const CambioDeParametro({
    required this.valorAnterior,
    required this.valorNuevo,
    required this.cambiadoEn,
    required this.motivo,
  });

  static const String columnas =
      'valor_anterior, valor_nuevo, cambiado_en, motivo';

  factory CambioDeParametro.desdeJson(Map<String, dynamic> json) =>
      CambioDeParametro(
        valorAnterior: json['valor_anterior'],
        valorNuevo: json['valor_nuevo'],
        cambiadoEn: DateTime.parse(json['cambiado_en'] as String),
        motivo: json['motivo'] as String? ?? '',
      );

  final Object? valorAnterior;
  final Object? valorNuevo;
  final DateTime cambiadoEn;
  final String motivo;
}

/// Los dos interruptores del fondo y la última pausa (docs/06 §4).
class Interruptores {
  const Interruptores({
    required this.iaActiva,
    required this.tradingActivo,
    this.motivoPausa,
    this.pausadoPor,
    this.pausadoEn,
  });

  static const String columnas =
      'ia_activa, trading_activo, motivo_pausa, pausado_en, perfiles(nombre)';

  factory Interruptores.desdeJson(Map<String, dynamic> json) {
    final perfil = json['perfiles'];
    final en = json['pausado_en'] as String?;
    return Interruptores(
      iaActiva: json['ia_activa'] as bool? ?? false,
      tradingActivo: json['trading_activo'] as bool? ?? false,
      motivoPausa: json['motivo_pausa'] as String?,
      pausadoPor: perfil is Map ? perfil['nombre'] as String? : null,
      pausadoEn: en == null ? null : DateTime.parse(en),
    );
  }

  final bool iaActiva;
  final bool tradingActivo;
  final String? motivoPausa;
  final String? pausadoPor;
  final DateTime? pausadoEn;

  bool estaEncendido(Interruptor interruptor) => switch (interruptor) {
    Interruptor.iaActiva => iaActiva,
    Interruptor.tradingActivo => tradingActivo,
  };
}

enum Interruptor {
  iaActiva('ia_activa', 'IA', 'La IA analiza el mercado y crea sugerencias.'),
  tradingActivo(
    'trading_activo',
    'Trading',
    'Se pueden aprobar y enviar órdenes nuevas al broker.',
  );

  const Interruptor(this.clave, this.titulo, this.descripcion);

  /// El nombre que reciben `reanudar` y `activar_freno`.
  final String clave;
  final String titulo;
  final String descripcion;
}

/// Modelos de la pantalla de mercado (HU-030, docs/06 §5.2 y §6, docs/09 §4).
library;

/// Los bolsillos con lista blanca (`lista_blanca.bolsillo`, nunca `reserva`).
enum BolsilloDeLista {
  usuarios('usuarios', 'Usuarios'),
  arriesgadas('arriesgadas', 'Arriesgadas');

  const BolsilloDeLista(this.clave, this.etiqueta);

  final String clave;
  final String etiqueta;
}

/// El último precio conocido de un símbolo (`cotizaciones`).
class Cotizacion {
  const Cotizacion({
    required this.simbolo,
    required this.precio,
    required this.momento,
    required this.recibidoEn,
    this.cierreAnterior,
    this.variacionDiaPct,
  });

  factory Cotizacion.desdeJson(Map<String, dynamic> fila) => Cotizacion(
    simbolo: fila['simbolo'] as String,
    precio: (fila['precio'] as num).toDouble(),
    cierreAnterior: (fila['cierre_anterior'] as num?)?.toDouble(),
    variacionDiaPct: (fila['variacion_dia_pct'] as num?)?.toDouble(),
    momento: DateTime.parse(fila['momento'] as String).toUtc(),
    recibidoEn: DateTime.parse(fila['recibido_en'] as String).toUtc(),
  );

  /// Columnas que pide la app.
  static const String columnas =
      'simbolo, precio, cierre_anterior, variacion_dia_pct, momento, recibido_en';

  final String simbolo;
  final double precio;
  final double? cierreAnterior;

  /// Variación del día en porcentaje; nula si el proveedor no la entregó.
  final double? variacionDiaPct;

  /// Hora del dato según el proveedor.
  final DateTime momento;

  /// Hora en que la ingesta lo recibió.
  final DateTime recibidoEn;

  /// Mezcla un elemento del evento `cotizaciones` (`{s, p, b, a, vd}`, docs/09
  /// §4) sobre la cotización que ya se tiene. El evento no trae el cierre
  /// anterior: se conserva el que había.
  Cotizacion conEvento({
    required double precio,
    required DateTime momento,
    required DateTime recibidoEn,
    double? variacionDiaPct,
  }) => Cotizacion(
    simbolo: simbolo,
    precio: precio,
    cierreAnterior: cierreAnterior,
    variacionDiaPct: variacionDiaPct ?? this.variacionDiaPct,
    momento: momento,
    recibidoEn: recibidoEn,
  );
}

/// Un símbolo de la lista blanca (`lista_blanca`).
class SimboloDeLista {
  const SimboloDeLista({
    required this.bolsillo,
    required this.simbolo,
    required this.nombre,
    required this.enNasdaq100,
  });

  factory SimboloDeLista.desdeJson(Map<String, dynamic> fila) => SimboloDeLista(
    bolsillo: fila['bolsillo'] as String,
    simbolo: fila['simbolo'] as String,
    nombre: fila['nombre'] as String,
    enNasdaq100: fila['en_nasdaq100'] as bool? ?? false,
  );

  static const String columnas = 'bolsillo, simbolo, nombre, en_nasdaq100';

  final String bolsillo;
  final String simbolo;
  final String nombre;
  final bool enNasdaq100;
}

/// Lo que devuelve `estado_mercado()` y la pantalla necesita (docs/06 §6).
class EstadoDelMercado {
  const EstadoDelMercado({
    required this.estado,
    required this.abierto,
    required this.ahora,
    this.proximaApertura,
    this.proximoCierre,
    this.datosActualizadosEn,
  });

  factory EstadoDelMercado.desdeJson(Map<String, dynamic> fila) {
    DateTime? fecha(String clave) => fila[clave] == null
        ? null
        : DateTime.parse(fila[clave] as String).toUtc();
    return EstadoDelMercado(
      estado: fila['estado'] as String,
      abierto: fila['abierto'] as bool,
      ahora: DateTime.parse(fila['ahora'] as String).toUtc(),
      proximaApertura: fecha('proxima_apertura'),
      proximoCierre: fecha('proximo_cierre'),
      datosActualizadosEn: fecha('datos_actualizados_en'),
    );
  }

  /// `cerrado`, `pre_apertura`, `abierto_sin_compras`, `abierto` o
  /// `cierre_proximo`.
  final String estado;
  final bool abierto;
  final DateTime ahora;
  final DateTime? proximaApertura;
  final DateTime? proximoCierre;
  final DateTime? datosActualizadosEn;

  /// El instante hacia el que cuenta la cuenta regresiva: el cierre con el
  /// mercado abierto, la apertura con el mercado cerrado (CA-3).
  DateTime? get objetivo => abierto ? proximoCierre : proximaApertura;
}

/// El rango de la gráfica: 1D · 1M · 1Y · All.
enum RangoDeGrafica {
  dia('1D'),
  mes('1M'),
  anio('1Y'),
  todo('All');

  const RangoDeGrafica(this.etiqueta);

  final String etiqueta;
}

/// Un punto de la serie de la gráfica.
class PuntoDeSerie {
  const PuntoDeSerie(this.momento, this.valor);

  final DateTime momento;
  final double valor;
}

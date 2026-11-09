/// Una candidata evaluada por la IA en el último ciclo (HU-048, docs/07 §14).
///
/// Es lo que devuelve la RPC `oportunidades(bolsillo)`. La explicación la arma
/// el código del agente (D-42): la app solo la muestra.
library;

enum BolsilloIa {
  arriesgadas('Arriesgadas'),
  usuarios('Usuarios');

  const BolsilloIa(this.etiqueta);

  final String etiqueta;

  static BolsilloIa? desdeTexto(Object? texto) {
    for (final b in values) {
      if (b.name == texto) return b;
    }
    return null;
  }
}

/// Qué concluyó el ciclo sobre una candidata.
enum ResultadoIa {
  /// La mejor opción de su bolsillo: se muestra como recomendación.
  elegida,

  /// Cumple las condiciones pero hay otra mejor.
  elegibleNoElegida,

  /// Evaluada y sin recomendar: JEV prefiere esperar, poca confianza, etc.
  noElegible,

  /// Sus datos no pasaron la verificación de calidad.
  excluida;

  static ResultadoIa desdeTexto(String texto) {
    if (texto == 'elegida') return elegida;
    if (texto == 'elegible_no_elegida') return elegibleNoElegida;
    if (texto.startsWith('excluida')) return excluida;
    return noElegible;
  }
}

/// El aporte de una dimensión al puntaje (peso × valor).
class AporteDeDimension {
  const AporteDeDimension({
    required this.clave,
    required this.nombre,
    required this.valor,
    required this.aporte,
    required this.neutral,
  });

  final String clave;
  final String nombre;

  /// De 0 a 1, donde 1 es lo mejor (en los riesgos ya es 1 − riesgo).
  final double valor;
  final double aporte;

  /// Sin dato (por ejemplo, sin contexto): vale 0,5 y no explica nada.
  final bool neutral;
}

class Explicacion {
  const Explicacion({
    required this.que,
    required this.porQue,
    required this.frena,
    required this.advertencias,
    required this.resumen,
  });

  static const Explicacion vacia = Explicacion(
    que: '',
    porQue: [],
    frena: [],
    advertencias: [],
    resumen: '',
  );

  factory Explicacion.desdeJson(Object? json) {
    if (json is! Map<String, dynamic>) return vacia;
    List<String> lista(Object? v) => [
      if (v is List)
        for (final e in v) e.toString(),
    ];
    return Explicacion(
      que: (json['que'] ?? '').toString(),
      porQue: lista(json['por_que']),
      frena: lista(json['frena']),
      advertencias: lista(json['advertencias']),
      resumen: (json['resumen'] ?? '').toString(),
    );
  }

  final String que;
  final List<String> porQue;
  final List<String> frena;
  final List<String> advertencias;
  final String resumen;
}

class Oportunidad {
  const Oportunidad({
    required this.cicloId,
    required this.bolsillo,
    required this.simbolo,
    required this.resultado,
    required this.motivo,
    required this.explicacion,
    required this.aportes,
    this.terminadoEn,
    this.puntaje,
    this.confianza,
    this.puntajeCuantitativo,
    this.modeloJev,
    this.rendimiento20d,
    this.volatilidad20d,
    this.rsi,
  });

  /// Nombres en lenguaje llano de las dimensiones del puntaje (docs/07 §6.2).
  static const Map<String, String> nombresDeDimension = {
    'Q': 'Rendimiento frente al riesgo',
    'C': 'Contexto',
    'S': 'Sentimiento de noticias',
    'T': 'Sector',
    'V': 'Calma (baja volatilidad)',
    'E': 'Sin eventos de riesgo',
    'R': 'Sin riesgo de reversión',
  };

  factory Oportunidad.desdeJson(Map<String, dynamic> json) {
    double? numero(Object? v) => v == null ? null : double.tryParse('$v');
    final resultadoTexto = (json['resultado'] ?? '').toString();
    final metricas = json['metricas'];
    final aportes = <AporteDeDimension>[];
    final crudos = json['aportes'];
    if (crudos is Map<String, dynamic>) {
      for (final entrada in nombresDeDimension.entries) {
        final a = crudos[entrada.key];
        if (a is Map<String, dynamic>) {
          aportes.add(
            AporteDeDimension(
              clave: entrada.key,
              nombre: entrada.value,
              valor: numero(a['valor']) ?? 0,
              aporte: numero(a['aporte']) ?? 0,
              neutral: a['neutral'] == true,
            ),
          );
        }
      }
    }
    return Oportunidad(
      cicloId: (json['ciclo_id'] ?? '').toString(),
      terminadoEn: DateTime.tryParse('${json['ciclo_terminado_en']}'),
      bolsillo:
          BolsilloIa.desdeTexto(json['bolsillo']) ?? BolsilloIa.arriesgadas,
      simbolo: (json['simbolo'] ?? '').toString(),
      resultado: ResultadoIa.desdeTexto(resultadoTexto),
      motivo: resultadoTexto.contains(':')
          ? resultadoTexto.split(':').last
          : null,
      puntaje: numero(json['puntaje_compuesto']),
      puntajeCuantitativo: numero(json['puntaje_cuantitativo']),
      confianza: numero(json['confianza']),
      modeloJev: json['modelo_jev'] as String?,
      explicacion: Explicacion.desdeJson(json['explicacion']),
      aportes: aportes,
      rendimiento20d: metricas is Map
          ? numero(metricas['rendimiento_20d'])
          : null,
      volatilidad20d: metricas is Map
          ? numero(metricas['volatilidad_20d'])
          : null,
      rsi: metricas is Map ? numero(metricas['rsi_14']) : null,
    );
  }

  final String cicloId;
  final DateTime? terminadoEn;
  final BolsilloIa bolsillo;
  final String simbolo;
  final ResultadoIa resultado;

  /// Lo que viene tras `no_elegible:` o `excluida:` (`espera`, `confianza`…).
  final String? motivo;

  /// Puntaje compuesto de 0 a 1.
  final double? puntaje;
  final double? puntajeCuantitativo;

  /// Confianza de JEV en la decisión de entrada, de 0 a 1.
  final double? confianza;
  final String? modeloJev;
  final Explicacion explicacion;
  final List<AporteDeDimension> aportes;

  /// Rendimiento a 20 días como fracción (0,05 = 5 %).
  final double? rendimiento20d;

  /// Volatilidad anualizada como fracción.
  final double? volatilidad20d;
  final double? rsi;
}

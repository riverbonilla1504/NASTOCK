/// Convierte lo que la persona escribe en el valor JSON de un parámetro y
/// valida lo que la pantalla puede validar antes de llamar a la base de datos
/// (que decide siempre: rango, tipo y suma del reparto, `PARAMETRO_FUERA_DE_RANGO`).
library;

import 'parametro.dart';

/// Resultado de leer el texto de un campo: el valor o el error para mostrar.
class LecturaDeValor {
  const LecturaDeValor.valor(this.valor) : error = null;
  const LecturaDeValor.error(String this.error) : valor = null;

  final Object? valor;
  final String? error;

  bool get esValido => error == null;
}

final RegExp _formaDeNumero = RegExp(r'^-?\d+([.,]\d+)?$');

/// Lee [texto] como el valor de [parametro]. `cupos.maximo_usd` vacío es «sin
/// límite» (JSON nulo, RN-19).
LecturaDeValor leerValor(Parametro parametro, String texto) {
  final t = texto.trim();
  switch (parametro.tipo) {
    case 'numero':
      if (t.isEmpty && parametro.clave == 'cupos.maximo_usd') {
        return const LecturaDeValor.valor(null);
      }
      if (!_formaDeNumero.hasMatch(t)) {
        return const LecturaDeValor.error('Escribe un número, como 20 o 0,65.');
      }
      return LecturaDeValor.valor(_numero(t));
    case 'booleano':
      return LecturaDeValor.valor(t == 'true');
    case 'lista':
      final elementos = [for (final e in t.split(',')) e.trim()]
          .where((e) => e.isNotEmpty)
          .toList();
      return LecturaDeValor.valor(elementos);
    default:
      if (t.isEmpty) return const LecturaDeValor.error('Escribe un valor.');
      return LecturaDeValor.valor(t);
  }
}

/// `20` → 20 (entero), `0,65` → 0.65.
num _numero(String texto) {
  final n = double.parse(texto.replaceAll(',', '.'));
  return n == n.roundToDouble() ? n.toInt() : n;
}

/// Lee los tres porcentajes del reparto (`pct_reserva`, `pct_arriesgadas`,
/// `pct_usuarios`) y exige que sumen 100 (RN-02, CB-78). Devuelve el objeto
/// que recibe `actualizar_parametro('reparto', …)`.
LecturaDeValor leerReparto({
  required String reserva,
  required String arriesgadas,
  required String usuarios,
}) {
  final partes = [reserva, arriesgadas, usuarios].map((t) => t.trim()).toList();
  if (partes.any((t) => !_formaDeNumero.hasMatch(t))) {
    return const LecturaDeValor.error(
      'Escribe los tres porcentajes como números, como 50, 25 y 25.',
    );
  }
  final valores = [for (final t in partes) _numero(t)];
  if (valores.any((v) => v < 0 || v > 100)) {
    return const LecturaDeValor.error(
      'Cada porcentaje debe estar entre 0 y 100.',
    );
  }
  final suma = valores.fold<double>(0, (a, v) => a + v);
  if ((suma - 100).abs() > 1e-9) {
    return LecturaDeValor.error(
      'Los tres porcentajes deben sumar 100; ahora suman ${textoDeValor(suma)}.',
    );
  }
  return LecturaDeValor.valor({
    'pct_reserva': valores[0],
    'pct_arriesgadas': valores[1],
    'pct_usuarios': valores[2],
  });
}

/// Nombre del tema de un grupo de parámetros.
String tituloDeTema(String tema) => switch (tema) {
  'reparto' => 'Reparto de aportes',
  'riesgo' => 'Riesgo',
  'mercado' => 'Mercado',
  'sugerencias' => 'Sugerencias',
  'aprobacion' => 'Aprobación',
  'ejecucion' => 'Ejecución',
  'ia' => 'Inteligencia artificial',
  'jev' => 'Decisión de JEV',
  'rebalanceo' => 'Rebalanceo',
  'conciliacion' => 'Conciliación',
  'cupos' => 'Cupos',
  'auth' => 'Ingreso',
  'app' => 'Aplicación',
  _ => tema,
};

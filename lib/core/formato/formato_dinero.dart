/// Formato de dinero (docs/README "Idioma y nombres", 06 §1, FR-003).
///
/// Todo monto se muestra en USD con dos decimales, con la escritura de la
/// documentación: `USD 10.000,00` (punto para miles, coma para decimales).
library;

/// Muestra un monto en USD con dos decimales: `1234.5` → `USD 1.234,50`.
///
/// Un monto negativo lleva el signo delante: `-USD 5,00`. Un monto que
/// redondea a cero nunca lleva signo (`USD 0,00`).
String formatearUsd(num monto) {
  if (monto.isNaN || monto.isInfinite) {
    throw ArgumentError.value(monto, 'monto', 'debe ser un número finito');
  }
  final dosDecimales = monto.abs().toStringAsFixed(2);
  final partes = dosDecimales.split('.');
  final entero = _conSeparadorDeMiles(partes[0]);
  final negativo = monto < 0 && dosDecimales != '0.00';
  return '${negativo ? '-' : ''}USD $entero,${partes[1]}';
}

/// Cifra corta para los ejes de una gráfica y los espacios muy angostos:
/// `10000` → `10,0K`, `2500000` → `2,5M`, `96.02` → `96,02`. Sin la moneda: el
/// valor completo de la pantalla ya dice USD. Los miles y millones llevan un
/// decimal; por debajo de mil, dos.
String formatearCifraCorta(num valor) {
  if (valor.isNaN || valor.isInfinite) {
    throw ArgumentError.value(valor, 'valor', 'debe ser un número finito');
  }
  final abs = valor.abs();
  final (escalado, sufijo) = abs >= 1e6
      ? (abs / 1e6, 'M')
      : (abs >= 1e3 ? (abs / 1e3, 'K') : (abs.toDouble(), ''));
  final texto = escalado.toStringAsFixed(sufijo.isEmpty ? 2 : 1);
  final cero = double.parse(texto) == 0;
  return '${valor < 0 && !cero ? '-' : ''}${texto.replaceFirst('.', ',')}$sufijo';
}

String _conSeparadorDeMiles(String digitos) {
  final salida = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) salida.write('.');
    salida.write(digitos[i]);
  }
  return salida.toString();
}

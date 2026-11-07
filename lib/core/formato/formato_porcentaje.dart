/// Formato de porcentajes y de antigüedades cortas (HU-116).
///
/// Misma escritura que el dinero (`formato_dinero.dart`): coma decimal, punto
/// para miles y el signo `-` delante.
library;

/// Variación con signo y dos decimales: `1.24` → `+1,24 %`, `-0.82` →
/// `-0,82 %`. Una variación que redondea a cero no lleva signo: `0,00 %`.
String formatearPorcentaje(num porcentaje) {
  if (porcentaje.isNaN || porcentaje.isInfinite) {
    throw ArgumentError.value(
      porcentaje,
      'porcentaje',
      'debe ser un número finito',
    );
  }
  final dosDecimales = porcentaje.abs().toStringAsFixed(2);
  final partes = dosDecimales.split('.');
  final cuerpo = '${_conSeparadorDeMiles(partes[0])},${partes[1]}';
  if (dosDecimales == '0.00') return '$cuerpo %';
  return '${porcentaje < 0 ? '-' : '+'}$cuerpo %';
}

/// Antigüedad corta de un dato: `8 s`, `2 min`, `3 h`, `2 d`.
///
/// Se trunca hacia abajo: 119 segundos son `1 min`. Una duración negativa
/// (reloj del teléfono adelantado) cuenta como `0 s`.
String formatearAntiguedad(Duration antiguedad) {
  final segundos = antiguedad.isNegative ? 0 : antiguedad.inSeconds;
  if (segundos < 60) return '$segundos s';
  if (segundos < 3600) return '${segundos ~/ 60} min';
  if (segundos < 86400) return '${segundos ~/ 3600} h';
  return '${segundos ~/ 86400} d';
}

String _conSeparadorDeMiles(String digitos) {
  final salida = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) salida.write('.');
    salida.write(digitos[i]);
  }
  return salida.toString();
}

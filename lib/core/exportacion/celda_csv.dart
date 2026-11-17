/// Escritura de una celda de CSV (RFC 4180), común a todas las exportaciones
/// de la app: la bitácora (HU-108) y los reportes (HU-117).
library;

final _formula = RegExp(r'^\s*[=+\-@]|^[\t\r\n]');

/// Celda entre comillas, con las comillas internas duplicadas.
///
/// Neutraliza lo que una hoja de cálculo podría interpretar como fórmula
/// (`=`, `+`, `-` o `@` al inicio, o un tabulador o retorno): le antepone un
/// apóstrofo. Un dato nulo es una celda vacía.
String celdaCsv(String? dato) {
  final valor = dato ?? '';
  final protegido = _formula.hasMatch(valor) ? "'$valor" : valor;
  return '"${protegido.replaceAll('"', '""')}"';
}

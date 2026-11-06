/// Formato de horas y fechas (docs/README "Idioma y nombres", RN-42, FR-003).
///
/// Las horas se guardan en UTC y la app siempre las muestra en hora de Bogotá.
/// Bogotá es UTC−5 todo el año (sin horario de verano, RN-42), así que basta
/// un desfase fijo y no hace falta una base de zonas horarias.
library;

/// Desfase de la hora de Bogotá respecto de UTC.
const Duration desfaseBogota = Duration(hours: -5);

/// Hora de Bogotá como `HH:MM` de 24 horas, p. ej. `08:30`.
String formatearHora(DateTime instante) {
  final b = _aBogota(instante);
  return '${_dos(b.hour)}:${_dos(b.minute)}';
}

/// Fecha de Bogotá como `DD/MM/AAAA`, p. ej. `05/11/2026`.
String formatearFecha(DateTime instante) {
  final b = _aBogota(instante);
  return '${_dos(b.day)}/${_dos(b.month)}/${b.year.toString().padLeft(4, '0')}';
}

/// Fecha y hora de Bogotá como `DD/MM/AAAA HH:MM`.
String formatearFechaHora(DateTime instante) =>
    '${formatearFecha(instante)} ${formatearHora(instante)}';

/// Convierte un instante a la hora de pared de Bogotá. El resultado queda
/// marcado como UTC solo para que `hour`, `day`, etc. no dependan de la zona
/// del dispositivo; no es un instante, es la hora que se ve en Bogotá.
DateTime _aBogota(DateTime instante) => instante.toUtc().add(desfaseBogota);

String _dos(int n) => n.toString().padLeft(2, '0');

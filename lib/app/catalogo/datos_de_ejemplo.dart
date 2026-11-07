/// Datos de ejemplo del catálogo. No son precios reales.
library;

/// Una fila de cotización de ejemplo.
typedef FilaDeEjemplo = ({
  String simbolo,
  String nombre,
  double precio,
  double variacion,
  Duration antiguedad,
  bool desactualizado,
});

abstract final class Ejemplo {
  /// Viernes 6 de noviembre de 2026: 09:30 a 16:00 en Bogotá (UTC−5).
  static final DateTime apertura = DateTime.utc(2026, 11, 6, 14, 30);
  static final DateTime cierre = DateTime.utc(2026, 11, 6, 21);
  static final DateTime ahora = DateTime.utc(2026, 11, 6, 16, 46);

  /// Posición de "ahora" en la jornada (136 de 390 minutos).
  static const double fraccionAhora = 136 / 390;

  static const List<double> curvaQld = [
    95.78,
    95.92,
    96.01,
    96.44,
    96.62,
    96.55,
    96.98,
    97.21,
    97.12,
    97.56,
    97.81,
    97.95,
    98.14,
  ];

  static const List<double> curvaQqq = [
    506.08,
    506.45,
    506.69,
    507.82,
    508.3,
    508.11,
    509.25,
    509.86,
    509.62,
    510.78,
    511.44,
    511.81,
    512.36,
  ];

  static const List<FilaDeEjemplo> filas = [
    (
      simbolo: 'QQQ',
      nombre: 'Invesco QQQ Trust · ×1',
      precio: 512.36,
      variacion: 1.24,
      antiguedad: Duration(seconds: 8),
      desactualizado: false,
    ),
    (
      simbolo: 'TQQQ',
      nombre: 'ProShares UltraPro QQQ · ×3',
      precio: 71.02,
      variacion: 3.69,
      antiguedad: Duration(seconds: 8),
      desactualizado: false,
    ),
    (
      simbolo: 'AAPL',
      nombre: 'Apple',
      precio: 231.08,
      variacion: -0.82,
      antiguedad: Duration(minutes: 2),
      desactualizado: true,
    ),
    (
      simbolo: 'MSFT',
      nombre: 'Microsoft',
      precio: 452.10,
      variacion: 0.31,
      antiguedad: Duration(seconds: 9),
      desactualizado: false,
    ),
    (
      simbolo: 'NVDA',
      nombre: 'NVIDIA',
      precio: 141.77,
      variacion: -1.15,
      antiguedad: Duration(seconds: 9),
      desactualizado: false,
    ),
  ];
}

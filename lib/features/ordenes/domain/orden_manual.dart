/// Datos y reglas del lado del cliente de la orden manual (HU-075).
///
/// Las reglas de verdad las aplica la RPC `crear_orden_manual` (docs/06 §8.1);
/// aquí solo se evita mandar lo que ya se sabe inválido y se calcula la
/// estimación que ve la persona antes de confirmar.
library;

import 'dart:math';

/// Los dos lados de una orden manual.
enum LadoDeOrden {
  compra('compra', 'Comprar'),
  venta('venta', 'Vender');

  const LadoDeOrden(this.valor, this.verbo);

  /// El texto que espera la RPC.
  final String valor;

  /// El verbo del botón.
  final String verbo;
}

/// Stop y objetivo que se precargan en una compra
/// (`riesgo.cupo.stop_defecto_pct` y `riesgo.cupo.objetivo_defecto_pct`).
class ProteccionPorDefecto {
  const ProteccionPorDefecto({
    required this.stopPct,
    required this.objetivoPct,
  });

  /// Los valores de docs/02 §13, por si los parámetros no se pueden leer.
  static const ProteccionPorDefecto predeterminada = ProteccionPorDefecto(
    stopPct: 8,
    objetivoPct: 15,
  );

  final double stopPct;
  final double objetivoPct;
}

/// Un identificador v4 generado en la app: es la clave de idempotencia de la
/// orden (docs/08 §7.5). Se genera una vez por formulario, para que reintentar
/// no duplique la orden.
String nuevoIdDeOrden([Random? azar]) {
  final r = azar ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int desde, int hasta) => b
      .sublist(desde, hasta)
      .map((x) => x.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${h(0, 4)}-${h(4, 6)}-${h(6, 8)}-${h(8, 10)}-${h(10, 16)}';
}

/// La cantidad escrita como acciones enteras (D-63), o `null` si no lo es.
int? cantidadEntera(String texto) {
  final n = int.tryParse(texto.trim());
  return (n == null || n < 1) ? null : n;
}

/// Un porcentaje escrito con coma o punto, o `null` si no es un número.
double? porcentaje(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));

/// Monto aproximado de la orden con el precio de referencia (la RPC fija el
/// precio límite con su banda y devuelve el monto exacto).
double montoEstimado(int cantidad, double precio) => cantidad * precio;

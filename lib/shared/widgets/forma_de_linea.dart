/// La forma de una línea dice el estado, no su color (DESIGN.md).
///
/// Avisos y chips se distinguen por la forma del borde y del trazo: sólida en
/// vivo, discontinua pendiente, punteada desactualizado, doble para el error.
library;

import 'package:flutter/material.dart';

/// Formas de línea del sistema.
enum FormaDeLinea {
  /// Regla fina y suave (información).
  fina,

  /// Sólida en tinta (en vivo, hecho).
  solida,

  /// Discontinua (pendiente, advertencia).
  discontinua,

  /// Doble grosor (error).
  doble,

  /// Punteada (dato desactualizado).
  punteada,
}

/// Grosor del trazo de cada forma.
double grosorDe(FormaDeLinea forma) => switch (forma) {
  FormaDeLinea.fina => 1,
  FormaDeLinea.solida => 1,
  FormaDeLinea.discontinua => 1,
  FormaDeLinea.doble => 2,
  FormaDeLinea.punteada => 1.4,
};

/// Dibuja [camino] con la forma pedida.
void dibujarConForma(
  Canvas canvas,
  Path camino,
  FormaDeLinea forma,
  Color color, {
  double? grosor,
}) {
  final pincel = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = grosor ?? grosorDe(forma)
    ..strokeCap = forma == FormaDeLinea.punteada
        ? StrokeCap.round
        : StrokeCap.butt;
  final (trazo, hueco) = switch (forma) {
    FormaDeLinea.discontinua => (5.0, 3.5),
    FormaDeLinea.punteada => (0.1, 3.4),
    _ => (0.0, 0.0),
  };
  if (trazo == 0) {
    canvas.drawPath(camino, pincel);
    return;
  }
  for (final medida in camino.computeMetrics()) {
    var d = 0.0;
    while (d < medida.length) {
      canvas.drawPath(medida.extractPath(d, d + trazo), pincel);
      d += trazo + hueco;
    }
  }
}

/// Borde con forma alrededor de [child].
class BordeConForma extends StatelessWidget {
  const BordeConForma({
    required this.forma,
    required this.color,
    required this.child,
    this.radio = 4,
    super.key,
  });

  final FormaDeLinea forma;
  final Color color;
  final double radio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _PintorDeBorde(forma, color, radio),
      child: child,
    );
  }
}

class _PintorDeBorde extends CustomPainter {
  _PintorDeBorde(this.forma, this.color, this.radio);

  final FormaDeLinea forma;
  final Color color;
  final double radio;

  @override
  void paint(Canvas canvas, Size size) {
    final medio = grosorDe(forma) / 2;
    final rect = Rect.fromLTWH(
      medio,
      medio,
      size.width - medio * 2,
      size.height - medio * 2,
    );
    final camino = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radio)));
    dibujarConForma(canvas, camino, forma, color);
  }

  @override
  bool shouldRepaint(_PintorDeBorde viejo) =>
      viejo.forma != forma || viejo.color != color || viejo.radio != radio;
}

/// Trazo corto horizontal que repite la forma de un estado junto a su texto.
class TrazoDeLinea extends StatelessWidget {
  const TrazoDeLinea({
    required this.forma,
    required this.color,
    this.ancho = 16,
    super.key,
  });

  final FormaDeLinea forma;
  final Color color;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(ancho, 4),
        painter: _PintorDeTrazo(forma, color),
      ),
    );
  }
}

class _PintorDeTrazo extends CustomPainter {
  _PintorDeTrazo(this.forma, this.color);

  final FormaDeLinea forma;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final camino = Path()
      ..moveTo(0, y)
      ..lineTo(size.width, y);
    dibujarConForma(canvas, camino, forma, color, grosor: 2.5);
  }

  @override
  bool shouldRepaint(_PintorDeTrazo viejo) =>
      viejo.forma != forma || viejo.color != color;
}

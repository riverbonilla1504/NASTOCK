/// Gráfica de línea del sistema: la serie que importa en morado, con su área
/// en degradado del morado a transparente; una referencia opcional en gris
/// discontinuo; rejilla gris y la aguja de "ahora".
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'forma_de_linea.dart';

class GraficaDeLinea extends StatelessWidget {
  const GraficaDeLinea({
    required this.serie,
    required this.descripcion,
    this.referencia,
    this.ahora,
    this.alto = 96,
    this.rejilla = 3,
    super.key,
  });

  /// Valores de la serie principal, en orden de tiempo.
  final List<double> serie;

  /// Serie de referencia (p. ej. QQQ frente a QLD), en gris discontinuo.
  final List<double>? referencia;

  /// Posición de "ahora" en el eje horizontal, de 0 a 1. Los valores se
  /// reparten hasta ahí; sin [ahora], ocupan todo el ancho.
  final double? ahora;

  final double alto;

  /// Líneas horizontales de la rejilla.
  final int rejilla;

  /// Lo que lee un lector de pantalla, p. ej. "QLD hoy: sube de 96,02 a 98,14".
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: descripcion,
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        height: alto,
        width: double.infinity,
        child: CustomPaint(
          painter: _PintorDeGrafica(
            serie: serie,
            referencia: referencia,
            ahora: ahora,
            rejilla: rejilla,
            colores: context.colores,
          ),
        ),
      ),
    );
  }
}

class _PintorDeGrafica extends CustomPainter {
  _PintorDeGrafica({
    required this.serie,
    required this.referencia,
    required this.ahora,
    required this.rejilla,
    required this.colores,
  });

  final List<double> serie;
  final List<double>? referencia;
  final double? ahora;
  final int rejilla;
  final ColoresAlmanaque colores;

  @override
  void paint(Canvas canvas, Size size) {
    const margenArriba = 6.0;
    const margenAbajo = 2.0;
    final alto = size.height - margenArriba - margenAbajo;
    final todos = [...serie, ...?referencia];
    if (todos.isEmpty) return;
    var minimo = todos.reduce(math.min);
    var maximo = todos.reduce(math.max);
    if (maximo == minimo) {
      maximo += 1;
      minimo -= 1;
    }
    final finX = (ahora ?? 1).clamp(0.0, 1.0) * size.width;

    final pincelRejilla = Paint()
      ..color = colores.regla
      ..strokeWidth = 1;
    for (var i = 0; i < rejilla; i++) {
      final y = margenArriba + alto * i / math.max(1, rejilla - 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pincelRejilla);
    }

    Offset punto(List<double> valores, int i) {
      final x = valores.length == 1 ? 0.0 : finX * i / (valores.length - 1);
      final y =
          margenArriba + alto * (1 - (valores[i] - minimo) / (maximo - minimo));
      return Offset(x, y);
    }

    Path linea(List<double> valores) {
      final camino = Path();
      for (var i = 0; i < valores.length; i++) {
        final p = punto(valores, i);
        i == 0 ? camino.moveTo(p.dx, p.dy) : camino.lineTo(p.dx, p.dy);
      }
      return camino;
    }

    final base = size.height - margenAbajo;
    if (referencia != null && referencia!.isNotEmpty) {
      dibujarConForma(
        canvas,
        linea(referencia!),
        FormaDeLinea.discontinua,
        colores.tintaTenue,
        grosor: 2,
      );
    }

    if (serie.isNotEmpty) {
      final principal = linea(serie);
      final ultimo = punto(serie, serie.length - 1);
      final area = Path.from(principal)
        ..lineTo(ultimo.dx, base)
        ..lineTo(0, base)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colores.morado.withValues(alpha: 0.24),
              colores.morado.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, margenArriba, size.width, alto)),
      );
      canvas.drawPath(
        principal,
        Paint()
          ..color = colores.morado
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(ultimo, 4, Paint()..color = colores.morado);
    }

    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = colores.reglaFuerte
        ..strokeWidth = 1,
    );
    if (ahora != null) {
      canvas.drawLine(
        Offset(finX, 0),
        Offset(finX, base),
        Paint()
          ..color = colores.tinta
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorDeGrafica viejo) =>
      viejo.serie != serie ||
      viejo.referencia != referencia ||
      viejo.ahora != ahora ||
      viejo.rejilla != rejilla ||
      viejo.colores != colores;
}

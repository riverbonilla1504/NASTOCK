/// Gráfica de línea del sistema, con el estilo de Alpaca (D-69): una sola
/// línea delgada (2 px) en el acento con un relleno plano muy suave debajo,
/// cuadrícula horizontal punteada tenue, sin ejes dibujados ni puntos, y
/// etiquetas de ejes pequeñas en monoespaciada. Una referencia opcional va en
/// gris discontinuo y la aguja de "ahora" en tinta.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../core/formato/formato_dinero.dart';
import 'forma_de_linea.dart';

class GraficaDeLinea extends StatelessWidget {
  const GraficaDeLinea({
    required this.serie,
    required this.descripcion,
    this.referencia,
    this.ahora,
    this.alto = 96,
    this.rejilla = 3,
    this.mostrarEjeY = false,
    this.formatoY = formatearCifraCorta,
    this.etiquetasX,
    super.key,
  });

  /// Valores de la serie principal, en orden de tiempo.
  final List<double> serie;

  /// Serie de referencia (p. ej. QQQ frente a QLD), en gris discontinuo.
  final List<double>? referencia;

  /// Posición de "ahora" en el eje horizontal, de 0 a 1. Los valores se
  /// reparten hasta ahí; sin [ahora], ocupan todo el ancho.
  final double? ahora;

  /// Alto total, con las etiquetas del eje X si las hay.
  final double alto;

  /// Líneas horizontales de la rejilla.
  final int rejilla;

  /// Etiquetas del eje Y a la izquierda, una por línea de la rejilla. Son
  /// pocas a propósito: en el celular no deben amontonarse.
  final bool mostrarEjeY;

  /// Cómo se escribe un valor del eje Y. Por defecto, la cifra corta (`10,0K`).
  final String Function(double valor) formatoY;

  /// Etiquetas del eje X bajo la gráfica: la primera a la izquierda, la
  /// última a la derecha y las demás repartidas. Pocas (2 o 3 en el celular).
  final List<String>? etiquetasX;

  /// Lo que lee un lector de pantalla, p. ej. "QLD hoy: sube de 96,02 a 98,14".
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloDeCifra(
      Theme.of(context).textTheme.bodySmall!.copyWith(
        fontSize: 11,
        height: 1.2,
        color: context.colores.tintaTenue,
      ),
    );
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
            mostrarEjeY: mostrarEjeY,
            formatoY: formatoY,
            etiquetasX: etiquetasX,
            colores: context.colores,
            estilo: estilo,
            // La gráfica es dibujo: el texto de sus ejes escala hasta 1,3.
            escala: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
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
    required this.mostrarEjeY,
    required this.formatoY,
    required this.etiquetasX,
    required this.colores,
    required this.estilo,
    required this.escala,
  });

  final List<double> serie;
  final List<double>? referencia;
  final double? ahora;
  final int rejilla;
  final bool mostrarEjeY;
  final String Function(double) formatoY;
  final List<String>? etiquetasX;
  final ColoresTema colores;
  final TextStyle estilo;
  final TextScaler escala;

  TextPainter _texto(String texto) => TextPainter(
    text: TextSpan(text: texto, style: estilo),
    textDirection: TextDirection.ltr,
    textScaler: escala,
    maxLines: 1,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final todos = [...serie, ...?referencia];
    if (todos.isEmpty) return;
    var minimo = todos.reduce(math.min);
    var maximo = todos.reduce(math.max);
    if (maximo == minimo) {
      maximo += 1;
      minimo -= 1;
    }

    // Márgenes: etiquetas del eje Y a la izquierda y del eje X abajo.
    final lineas = math.max(2, rejilla);
    final valoresY = [
      for (var i = 0; i < lineas; i++)
        maximo - (maximo - minimo) * i / (lineas - 1),
    ];
    final etiquetasY = mostrarEjeY
        ? [for (final v in valoresY) _texto(formatoY(v))]
        : const <TextPainter>[];
    final margenIzq = etiquetasY.isEmpty
        ? 0.0
        : etiquetasY.map((e) => e.width).reduce(math.max) + 8;
    final altoEtiquetaX = etiquetasX == null ? 0.0 : _texto('0').height + 6;
    final margenArriba = etiquetasY.isEmpty ? 4.0 : _texto('0').height / 2;
    final margenAbajo = altoEtiquetaX + 4;
    final ancho = size.width - margenIzq;
    final alto = size.height - margenArriba - margenAbajo;
    if (ancho <= 0 || alto <= 0) return;
    final finX = margenIzq + (ahora ?? 1).clamp(0.0, 1.0) * ancho;

    // Cuadrícula horizontal punteada, gris muy claro.
    final pincelRejilla = Paint()
      ..color = colores.regla
      ..strokeWidth = 1;
    for (var i = 0; i < lineas; i++) {
      final y = margenArriba + alto * i / (lineas - 1);
      for (var x = margenIzq; x < size.width; x += 6) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 3, size.width), y),
          pincelRejilla,
        );
      }
      if (etiquetasY.isNotEmpty) {
        final e = etiquetasY[i];
        e.paint(canvas, Offset(margenIzq - 8 - e.width, y - e.height / 2));
      }
    }

    Offset punto(List<double> valores, int i) {
      final x = valores.length == 1
          ? margenIzq
          : margenIzq + (finX - margenIzq) * i / (valores.length - 1);
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

    final base = margenArriba + alto;
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
        ..lineTo(margenIzq, base)
        ..close();
      // Relleno plano y muy suave: el mismo color, sin degradado.
      canvas.drawPath(
        area,
        Paint()..color = colores.morado.withValues(alpha: 0.08),
      );
      canvas.drawPath(
        principal,
        Paint()
          ..color = colores.morado
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    if (ahora != null) {
      canvas.drawLine(
        Offset(finX, margenArriba),
        Offset(finX, base),
        Paint()
          ..color = colores.tinta
          ..strokeWidth = 1.5,
      );
    }

    final x = etiquetasX;
    if (x != null && x.isNotEmpty) {
      for (var i = 0; i < x.length; i++) {
        final tp = _texto(x[i]);
        final centro = x.length == 1
            ? margenIzq
            : margenIzq + ancho * i / (x.length - 1);
        final izq = i == 0
            ? margenIzq
            : (i == x.length - 1
                  ? size.width - tp.width
                  : centro - tp.width / 2);
        tp.paint(canvas, Offset(izq, base + 6));
      }
    }
  }

  @override
  bool shouldRepaint(_PintorDeGrafica viejo) =>
      viejo.serie != serie ||
      viejo.referencia != referencia ||
      viejo.ahora != ahora ||
      viejo.rejilla != rejilla ||
      viejo.mostrarEjeY != mostrarEjeY ||
      viejo.etiquetasX != etiquetasX ||
      viejo.colores != colores ||
      viejo.estilo != estilo ||
      viejo.escala != escala;
}

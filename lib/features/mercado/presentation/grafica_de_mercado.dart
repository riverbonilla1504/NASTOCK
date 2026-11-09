/// Gráfica de mercado con el estilo de Alpaca que pidió Javier (2026-11-08):
/// una sola línea delgada en morado, relleno plano y suave debajo, cuadrícula
/// horizontal punteada, etiquetas de los ejes en monoespaciada y sin leyenda.
/// Al deslizar el dedo marca el punto y muestra su valor y su hora.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/tema.dart';
import '../../../core/formato/formato_fechas.dart';
import '../domain/mercado.dart';

/// Un precio para las etiquetas: `478,62` (coma decimal, sin moneda).
String etiquetaDePrecio(double valor) {
  final texto = valor.toStringAsFixed(2).replaceAll('.', ',');
  return texto;
}

const List<String> _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// La marca del eje horizontal según el [rango]: la hora de Bogotá en 1D, el
/// día y mes en 1M, el mes y año en 1Y y All.
String etiquetaDeEje(DateTime momento, RangoDeGrafica rango) {
  switch (rango) {
    case RangoDeGrafica.dia:
      return formatearHora(momento);
    case RangoDeGrafica.mes:
      return '${momento.day} ${_meses[momento.month - 1]}';
    case RangoDeGrafica.anio:
    case RangoDeGrafica.todo:
      return "${_meses[momento.month - 1]} '${(momento.year % 100).toString().padLeft(2, '0')}";
  }
}

class GraficaDeMercado extends StatefulWidget {
  const GraficaDeMercado({
    required this.serie,
    required this.rango,
    required this.descripcion,
    this.alto = 220,
    super.key,
  });

  /// Los puntos, en orden de tiempo.
  final List<PuntoDeSerie> serie;
  final RangoDeGrafica rango;

  /// Lo que lee un lector de pantalla.
  final String descripcion;
  final double alto;

  @override
  State<GraficaDeMercado> createState() => _GraficaDeMercadoState();
}

class _GraficaDeMercadoState extends State<GraficaDeMercado> {
  int? _marcado;

  void _marcar(double x, double ancho) {
    final n = widget.serie.length;
    if (n == 0) return;
    final area = ancho - _PintorDeMercado.margenIzquierdo;
    final fraccion = ((x - _PintorDeMercado.margenIzquierdo) / area).clamp(
      0.0,
      1.0,
    );
    setState(() => _marcado = (fraccion * (n - 1)).round());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final serie = widget.serie;
    final marcado = _marcado != null && _marcado! < serie.length
        ? serie[_marcado!]
        : null;
    return Semantics(
      label: widget.descripcion,
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        height: widget.alto,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, caja) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) =>
                _marcar(d.localPosition.dx, caja.maxWidth),
            onHorizontalDragUpdate: (d) =>
                _marcar(d.localPosition.dx, caja.maxWidth),
            onHorizontalDragEnd: (_) => setState(() => _marcado = null),
            onHorizontalDragCancel: () => setState(() => _marcado = null),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PintorDeMercado(
                      serie: serie,
                      rango: widget.rango,
                      marcado: _marcado,
                      colores: c,
                    ),
                  ),
                ),
                if (marcado != null)
                  Positioned(
                    left: _PintorDeMercado.margenIzquierdo + 4,
                    top: 0,
                    child: Text(
                      '${etiquetaDePrecio(marcado.valor)} · '
                      '${widget.rango == RangoDeGrafica.dia ? formatearHora(marcado.momento) : '${marcado.momento.day} ${_meses[marcado.momento.month - 1]} ${marcado.momento.year}'}',
                      style: estiloDeCifra(
                        textos.bodySmall!.copyWith(
                          color: c.tinta,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorDeMercado extends CustomPainter {
  _PintorDeMercado({
    required this.serie,
    required this.rango,
    required this.marcado,
    required this.colores,
  });

  /// Espacio para las etiquetas del eje vertical (`1234,56`).
  static const double margenIzquierdo = 56;
  static const double margenAbajo = 22;
  static const double margenArriba = 14;
  static const int lineasDeRejilla = 4;
  static const int marcasDelEje = 3;

  final List<PuntoDeSerie> serie;
  final RangoDeGrafica rango;
  final int? marcado;
  final ColoresTema colores;

  TextPainter _texto(String texto, {TextAlign alineacion = TextAlign.left}) {
    return TextPainter(
      text: TextSpan(
        text: texto,
        style: estiloDeCifra(
          TextStyle(fontSize: 11, height: 1.2, color: colores.tintaTenue),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: alineacion,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width - margenIzquierdo;
    final alto = size.height - margenArriba - margenAbajo;
    if (ancho <= 0 || alto <= 0) return;

    var minimo = 0.0;
    var maximo = 1.0;
    if (serie.isNotEmpty) {
      minimo = serie.map((p) => p.valor).reduce(math.min);
      maximo = serie.map((p) => p.valor).reduce(math.max);
      if (maximo == minimo) {
        maximo += 1;
        minimo -= 1;
      } else {
        // Aire arriba y abajo para que la línea no toque la cuadrícula.
        final aire = (maximo - minimo) * 0.08;
        maximo += aire;
        minimo -= aire;
      }
    }

    double yDe(double valor) =>
        margenArriba + alto * (1 - (valor - minimo) / (maximo - minimo));

    // Cuadrícula horizontal punteada y etiquetas del eje vertical.
    final pincelRejilla = Paint()
      ..color = colores.regla
      ..strokeWidth = 1;
    for (var i = 0; i < lineasDeRejilla; i++) {
      final fraccion = i / (lineasDeRejilla - 1);
      final y = margenArriba + alto * fraccion;
      var x = margenIzquierdo;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 3, size.width), y),
          pincelRejilla,
        );
        x += 7;
      }
      if (serie.isNotEmpty) {
        final etiqueta = _texto(
          etiquetaDePrecio(maximo - (maximo - minimo) * fraccion),
        );
        etiqueta.paint(
          canvas,
          Offset(margenIzquierdo - etiqueta.width - 8, y - etiqueta.height / 2),
        );
      }
    }

    if (serie.isEmpty) return;

    double xDe(int i) => serie.length == 1
        ? margenIzquierdo + ancho
        : margenIzquierdo + ancho * i / (serie.length - 1);

    final linea = Path();
    for (var i = 0; i < serie.length; i++) {
      final p = Offset(xDe(i), yDe(serie[i].valor));
      i == 0 ? linea.moveTo(p.dx, p.dy) : linea.lineTo(p.dx, p.dy);
    }
    final base = margenArriba + alto;
    final area = Path.from(linea)
      ..lineTo(xDe(serie.length - 1), base)
      ..lineTo(xDe(0), base)
      ..close();
    // Relleno plano y muy suave, sin degradado fuerte.
    canvas.drawPath(
      area,
      Paint()..color = colores.morado.withValues(alpha: 0.08),
    );
    canvas.drawPath(
      linea,
      Paint()
        ..color = colores.morado
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Etiquetas del eje horizontal: pocas, solo las necesarias.
    for (var k = 0; k < marcasDelEje; k++) {
      final i = ((serie.length - 1) * k / (marcasDelEje - 1)).round();
      final etiqueta = _texto(etiquetaDeEje(serie[i].momento, rango));
      final centro = xDe(i);
      final izquierda = (centro - etiqueta.width / 2).clamp(
        margenIzquierdo,
        size.width - etiqueta.width,
      );
      etiqueta.paint(canvas, Offset(izquierda, base + 6));
    }

    final m = marcado;
    if (m != null && m < serie.length) {
      final x = xDe(m);
      canvas.drawLine(
        Offset(x, margenArriba),
        Offset(x, base),
        Paint()
          ..color = colores.tintaSuave
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        Offset(x, yDe(serie[m].valor)),
        4,
        Paint()..color = colores.morado,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorDeMercado viejo) =>
      viejo.serie != serie ||
      viejo.rango != rango ||
      viejo.marcado != marcado ||
      viejo.colores != colores;
}

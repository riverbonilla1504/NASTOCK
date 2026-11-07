/// La firma del Almanaque: la jornada del mercado como una franja de tiempo.
///
/// Va sobre la barra superior en grafito. Lo transcurrido se marca con un
/// trazo grueso y un difuminado gris que crece hacia "ahora"; la aguja de
/// ahora va en morado. Las horas se muestran en hora de Bogotá (RN-42).
/// Apertura y cierre vienen del calendario del broker (RN-41, HU-027).
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../core/formato/formato_fechas.dart';

class FranjaDeLaJornada extends StatelessWidget {
  const FranjaDeLaJornada({
    required this.apertura,
    required this.cierre,
    required this.ahora,
    super.key,
  });

  /// Instantes (UTC) de apertura y cierre de la jornada.
  final DateTime apertura;
  final DateTime cierre;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final dentro = !ahora.isBefore(apertura) && !ahora.isAfter(cierre);
    final lectura =
        'Jornada de ${formatearHora(apertura)} a ${formatearHora(cierre)}, '
        'hora de Bogotá${dentro ? '. Ahora ${formatearHora(ahora)}' : ''}';
    return Semantics(
      label: lectura,
      excludeSemantics: true,
      child: SizedBox(
        height: 32 + MediaQuery.textScalerOf(context).scale(18),
        width: double.infinity,
        child: CustomPaint(
          painter: _PintorDeFranja(
            apertura: apertura,
            cierre: cierre,
            ahora: ahora,
            colores: context.colores,
            estilo: Theme.of(context).textTheme.bodySmall!,
            escala: MediaQuery.textScalerOf(context),
          ),
        ),
      ),
    );
  }
}

class _PintorDeFranja extends CustomPainter {
  _PintorDeFranja({
    required this.apertura,
    required this.cierre,
    required this.ahora,
    required this.colores,
    required this.estilo,
    required this.escala,
  });

  final DateTime apertura;
  final DateTime cierre;
  final DateTime ahora;
  final ColoresAlmanaque colores;
  final TextStyle estilo;
  final TextScaler escala;

  static const double _ejeY = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final total = cierre.difference(apertura).inSeconds;
    if (total <= 0) return;
    double xDe(DateTime t) =>
        (t.difference(apertura).inSeconds / total).clamp(0.0, 1.0) * size.width;

    final suave = colores.sobreGrafitoSuave;
    final fuerte = colores.sobreGrafito;
    final xAhora = xDe(ahora);
    final transcurrido = ahora.isAfter(apertura);

    if (transcurrido && xAhora > 0) {
      final zona = Rect.fromLTWH(0, _ejeY - 8, xAhora, 16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(zona, const Radius.circular(2)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              fuerte.withValues(alpha: 0),
              fuerte.withValues(alpha: 0.16),
            ],
          ).createShader(zona),
      );
    }

    canvas.drawLine(
      Offset(0, _ejeY),
      Offset(size.width, _ejeY),
      Paint()
        ..color = suave
        ..strokeWidth = 1,
    );

    final marcas = <DateTime>[apertura];
    final inicio = apertura.toUtc();
    var hora = DateTime.utc(
      inicio.year,
      inicio.month,
      inicio.day,
      inicio.hour + 1,
    );
    while (hora.isBefore(cierre)) {
      marcas.add(hora);
      hora = hora.add(const Duration(hours: 1));
    }
    marcas.add(cierre);
    final pincelMarca = Paint()
      ..color = suave
      ..strokeWidth = 1;
    for (final m in marcas) {
      final x = xDe(m).clamp(0.5, size.width - 0.5);
      canvas.drawLine(Offset(x, _ejeY - 4), Offset(x, _ejeY + 4), pincelMarca);
    }

    if (transcurrido) {
      canvas.drawLine(
        Offset(0, _ejeY),
        Offset(xAhora, _ejeY),
        Paint()
          ..color = fuerte
          ..strokeWidth = 4,
      );
    }

    final estiloHora = estilo.copyWith(color: suave);
    void rotulo(DateTime t, {required TextAlign alineacion}) {
      final tp = TextPainter(
        text: TextSpan(text: formatearHora(t), style: estiloHora),
        textDirection: TextDirection.ltr,
        textScaler: escala,
      )..layout();
      final x = switch (alineacion) {
        TextAlign.left => 0.0,
        TextAlign.right => size.width - tp.width,
        _ => xDe(t) - tp.width / 2,
      };
      tp.paint(canvas, Offset(x, _ejeY + 8));
    }

    rotulo(apertura, alineacion: TextAlign.left);
    rotulo(cierre, alineacion: TextAlign.right);
    for (final m in marcas.skip(1).take(marcas.length - 2)) {
      final lejos =
          m.difference(apertura).inMinutes >= 60 &&
          cierre.difference(m).inMinutes >= 60;
      final local = m.toUtc().add(desfaseBogota);
      if (lejos && local.hour.isEven) rotulo(m, alineacion: TextAlign.center);
    }

    if (transcurrido && !ahora.isAfter(cierre)) {
      final morado = colores.moradoSobreGrafito;
      canvas.drawLine(
        Offset(xAhora, _ejeY - 14),
        Offset(xAhora, _ejeY + 6),
        Paint()
          ..color = morado
          ..strokeWidth = 2.5,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: formatearHora(ahora),
          style: estilo.copyWith(color: morado, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
        textScaler: escala,
      )..layout();
      final x = (xAhora + 5).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(x, _ejeY - 18));
    }
  }

  @override
  bool shouldRepaint(_PintorDeFranja viejo) =>
      viejo.apertura != apertura ||
      viejo.cierre != cierre ||
      viejo.ahora != ahora ||
      viejo.colores != colores ||
      viejo.escala != escala;
}

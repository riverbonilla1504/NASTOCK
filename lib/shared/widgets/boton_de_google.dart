/// Botón de ingreso con Google, según las pautas de marca de Google Identity:
/// fondo blanco (o casi negro en el tema oscuro), borde gris de 1 px y la "G"
/// de cuatro colores a la izquierda del texto. La "G" se dibuja con los trazos
/// del logo oficial (48 × 48) sin alterarlos, así no hace falta ni una imagen
/// ni un paquete de SVG.
///
/// Igual que los demás botones (docs/08 §9.3): mientras se envía, se
/// deshabilita y dice "Procesando…".
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'botones.dart' show textoProcesando;

class BotonDeGoogle extends StatelessWidget {
  const BotonDeGoogle({
    required this.texto,
    required this.alPresionar,
    this.enviando = false,
    super.key,
  });

  final String texto;

  /// Nulo deshabilita el botón.
  final VoidCallback? alPresionar;
  final bool enviando;

  @override
  Widget build(BuildContext context) {
    final claro = Theme.of(context).brightness == Brightness.light;
    final fondo = claro ? MarcaGoogle.fondoClaro : MarcaGoogle.fondoOscuro;
    final borde = claro ? MarcaGoogle.bordeClaro : MarcaGoogle.bordeOscuro;
    final texto_ = claro ? MarcaGoogle.textoClaro : MarcaGoogle.textoOscuro;
    final habilitado = alPresionar != null && !enviando;

    // Deshabilitado, las pautas atenúan todo el botón, la G incluida (el texto
    // lo atenúa el estilo).
    final contenido = enviando
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colores.tintaTenue,
                ),
              ),
              const SizedBox(width: Espacio.x2),
              const Text(textoProcesando),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: habilitado ? 1 : 0.38,
                child: const LogoDeGoogle(),
              ),
              const SizedBox(width: Espacio.x3),
              Flexible(child: Text(texto, overflow: TextOverflow.ellipsis)),
            ],
          );

    return OutlinedButton(
      onPressed: enviando ? null : alPresionar,
      style: OutlinedButton.styleFrom(
        backgroundColor: fondo,
        disabledBackgroundColor: fondo.withValues(alpha: 0.61),
        foregroundColor: texto_,
        disabledForegroundColor: texto_.withValues(alpha: 0.38),
        overlayColor: texto_,
        side: BorderSide(
          color: habilitado ? borde : texto_.withValues(alpha: 0.12),
        ),
      ),
      child: contenido,
    );
  }
}

/// La "G" de Google, de 18 dp como piden las pautas.
class LogoDeGoogle extends StatelessWidget {
  const LogoDeGoogle({this.tamano = 18, super.key});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(tamano),
        painter: const _PintorDeLaG(),
      ),
    );
  }
}

class _PintorDeLaG extends CustomPainter {
  const _PintorDeLaG();

  /// Los cuatro trazos del logo oficial, en su lienzo de 48 × 48.
  static const _trazos = <(Color, String)>[
    (
      MarcaGoogle.rojo,
      'M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 '
          '14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z',
    ),
    (
      MarcaGoogle.azul,
      'M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 '
          '5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z',
    ),
    (
      MarcaGoogle.amarillo,
      'M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19'
          'C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z',
    ),
    (
      MarcaGoogle.verde,
      'M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 '
          '2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z',
    ),
  ];

  static final List<(Paint, Path)> _pintados = [
    for (final (color, d) in _trazos)
      (
        Paint()
          ..color = color
          ..isAntiAlias = true,
        trazoDeSvg(d),
      ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    for (final (pintura, trazo) in _pintados) {
      canvas.drawPath(trazo, pintura);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorDeLaG oldDelegate) => false;
}

/// Convierte el atributo `d` de un trazo SVG en un [Path]. Solo entiende los
/// comandos del logo de Google: M, C, S, L, H, V y Z (absolutos y relativos),
/// con la repetición implícita de parámetros.
@visibleForTesting
Path trazoDeSvg(String d) {
  final fichas = RegExp(r'[MmCcSsLlHhVvZz]|-?(?:\d+\.?\d*|\.\d+)')
      .allMatches(d)
      .map((m) => m.group(0)!)
      .toList();
  final trazo = Path();
  var i = 0;
  var comando = '';
  var x = 0.0, y = 0.0;
  var inicioX = 0.0, inicioY = 0.0;
  // Segundo punto de control de la última curva, para S.
  double? controlX, controlY;

  bool esComando(String f) => RegExp(r'^[A-Za-z]$').hasMatch(f);
  double numero() => double.parse(fichas[i++]);

  while (i < fichas.length) {
    if (esComando(fichas[i])) comando = fichas[i++];
    final relativo = comando == comando.toLowerCase();
    final dx = relativo ? x : 0.0, dy = relativo ? y : 0.0;
    switch (comando.toUpperCase()) {
      case 'M':
        x = dx + numero();
        y = dy + numero();
        trazo.moveTo(x, y);
        inicioX = x;
        inicioY = y;
        controlX = null;
        // Los pares que siguen a M son líneas.
        comando = relativo ? 'l' : 'L';
      case 'L':
        x = dx + numero();
        y = dy + numero();
        trazo.lineTo(x, y);
        controlX = null;
      case 'H':
        x = dx + numero();
        trazo.lineTo(x, y);
        controlX = null;
      case 'V':
        y = dy + numero();
        trazo.lineTo(x, y);
        controlX = null;
      case 'C':
        final x1 = dx + numero(), y1 = dy + numero();
        final x2 = dx + numero(), y2 = dy + numero();
        x = dx + numero();
        y = dy + numero();
        trazo.cubicTo(x1, y1, x2, y2, x, y);
        controlX = x2;
        controlY = y2;
      case 'S':
        final x1 = controlX == null ? x : 2 * x - controlX;
        final y1 = controlY == null || controlX == null ? y : 2 * y - controlY;
        final x2 = dx + numero(), y2 = dy + numero();
        x = dx + numero();
        y = dy + numero();
        trazo.cubicTo(x1, y1, x2, y2, x, y);
        controlX = x2;
        controlY = y2;
      case 'Z':
        trazo.close();
        x = inicioX;
        y = inicioY;
        controlX = null;
      default:
        throw FormatException('Comando de trazo no soportado: $comando');
    }
  }
  return trazo;
}

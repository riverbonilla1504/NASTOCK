/// Avisos del sistema: en línea y temporales.
///
/// Ningún aviso es una caja tintada de rojo con su ícono rojo. El de
/// información es la franja tenue del acento con su ícono "i" (D-69); los
/// demás van en hoja con texto en tinta. Cada tipo se reconoce por la forma
/// de su marca y la forma de su borde (DESIGN.md). El texto de un error siempre
/// sale de `traducirError` (docs/06 §9).
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../core/errores/traduccion_de_errores.dart';
import 'forma_de_linea.dart';

/// Tipos de aviso.
enum TipoAviso { informacion, exito, advertencia, error, desactualizado }

/// Lo que lee un lector de pantalla antes del texto de cada tipo.
String lecturaDeTipo(TipoAviso tipo) => switch (tipo) {
  TipoAviso.informacion => 'Información',
  TipoAviso.exito => 'Hecho',
  TipoAviso.advertencia => 'Advertencia',
  TipoAviso.error => 'Error',
  TipoAviso.desactualizado => 'Dato desactualizado',
};

/// Forma del borde de cada tipo.
FormaDeLinea formaDeAviso(TipoAviso tipo) => switch (tipo) {
  TipoAviso.informacion => FormaDeLinea.fina,
  TipoAviso.exito => FormaDeLinea.solida,
  TipoAviso.advertencia => FormaDeLinea.discontinua,
  TipoAviso.error => FormaDeLinea.doble,
  TipoAviso.desactualizado => FormaDeLinea.punteada,
};

/// Aviso en línea, dentro del contenido.
class AvisoEnLinea extends StatelessWidget {
  const AvisoEnLinea({
    required this.tipo,
    required this.mensaje,
    this.titulo,
    this.accion,
    this.alAccionar,
    super.key,
  });

  /// Aviso de error para cualquier excepción: el texto pasa por
  /// [traducirError] y nunca muestra el texto crudo.
  AvisoEnLinea.deError(
    Object? error, {
    this.titulo,
    this.accion,
    this.alAccionar,
    super.key,
  }) : tipo = TipoAviso.error,
       mensaje = traducirError(error);

  final TipoAviso tipo;
  final String mensaje;
  final String? titulo;

  /// Texto del botón de acción, p. ej. "Reintentar".
  final String? accion;
  final VoidCallback? alAccionar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final forma = formaDeAviso(tipo);
    final franja = tipo == TipoAviso.informacion;
    final colorBorde = franja
        ? const Color(0x00000000)
        : (forma == FormaDeLinea.fina ? c.reglaFuerte : c.tinta);
    return Semantics(
      container: true,
      liveRegion: tipo == TipoAviso.error,
      label: lecturaDeTipo(tipo),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: franja ? c.moradoTenue : c.hoja,
          borderRadius: BorderRadius.circular(Radios.control),
        ),
        child: BordeConForma(
          forma: forma,
          color: colorBorde,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Espacio.x3 + 2,
              Espacio.x3,
              Espacio.x3,
              Espacio.x3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarcaDeAviso(tipo),
                const SizedBox(width: Espacio.x3),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (titulo != null)
                          Text(
                            titulo!,
                            style: textos.titleSmall!.copyWith(fontSize: 15),
                          ),
                        Text(
                          mensaje,
                          style: textos.bodyMedium!.copyWith(
                            color: titulo == null ? c.tinta : c.tintaSuave,
                          ),
                        ),
                        if (accion != null)
                          Padding(
                            padding: const EdgeInsets.only(top: Espacio.x1),
                            child: TextButton(
                              onPressed: alAccionar,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                              child: Text(accion!),
                            ),
                          ),
                      ],
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

/// La marca de cada tipo: su forma basta para distinguirlo.
class MarcaDeAviso extends StatelessWidget {
  const MarcaDeAviso(this.tipo, {this.tamano = 30, super.key});

  final TipoAviso tipo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final icono = tamano * 0.6;
    final Widget marca = switch (tipo) {
      TipoAviso.informacion => Icon(
        Icons.info_outline,
        size: tamano * 0.86,
        color: c.morado,
      ),
      TipoAviso.exito => DecoratedBox(
        decoration: BoxDecoration(color: c.tinta, shape: BoxShape.circle),
        child: Center(
          child: Icon(Icons.check, size: icono, color: c.hoja),
        ),
      ),
      TipoAviso.advertencia => Center(
        child: Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: tamano * 0.72,
            height: tamano * 0.72,
            decoration: BoxDecoration(
              border: Border.all(color: c.tinta, width: 1.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Transform.rotate(
              angle: -0.785398,
              child: Icon(
                Icons.priority_high,
                size: icono * 0.9,
                color: c.tinta,
              ),
            ),
          ),
        ),
      ),
      TipoAviso.error => DecoratedBox(
        decoration: BoxDecoration(
          color: c.tinta,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Center(
          child: Icon(Icons.close, size: icono, color: c.hoja),
        ),
      ),
      TipoAviso.desactualizado => CustomPaint(
        painter: _CirculoPunteado(c.tinta),
        child: Center(
          child: Icon(Icons.schedule, size: icono, color: c.tinta),
        ),
      ),
    };
    return ExcludeSemantics(
      child: SizedBox.square(dimension: tamano, child: marca),
    );
  }
}

class _CirculoPunteado extends CustomPainter {
  _CirculoPunteado(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final camino = Path()
      ..addOval(Rect.fromLTWH(1, 1, size.width - 2, size.height - 2));
    dibujarConForma(canvas, camino, FormaDeLinea.punteada, color, grosor: 1.6);
  }

  @override
  bool shouldRepaint(_CirculoPunteado viejo) => viejo.color != color;
}

/// Muestra un aviso pasajero sobre el contenido, con fondo grafito
/// traslúcido y desenfoque detrás. Lo que exige decidir va en un diálogo
/// (D-61), no aquí.
void mostrarAvisoTemporal(
  BuildContext context,
  String mensaje, {
  String? accion,
  VoidCallback? alAccionar,
  Duration duracion = const Duration(seconds: 4),
}) {
  final mensajero = ScaffoldMessenger.of(context);
  mensajero
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: const Color(0x00000000),
        elevation: 0,
        padding: EdgeInsets.zero,
        duration: duracion,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          Espacio.x4,
          0,
          Espacio.x4,
          Espacio.x4,
        ),
        content: AvisoTemporal(
          mensaje: mensaje,
          accion: accion,
          alAccionar: alAccionar == null
              ? null
              : () {
                  mensajero.hideCurrentSnackBar();
                  alAccionar();
                },
        ),
      ),
    );
}

/// El cuerpo del aviso temporal (lo usa [mostrarAvisoTemporal]).
class AvisoTemporal extends StatelessWidget {
  const AvisoTemporal({
    required this.mensaje,
    this.accion,
    this.alAccionar,
    super.key,
  });

  final String mensaje;
  final String? accion;
  final VoidCallback? alAccionar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final p = context.profundidad;
    final textos = Theme.of(context).textTheme;
    final esquina = BorderRadius.circular(Radios.control);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: esquina,
        boxShadow: p.sombraFlotante,
      ),
      child: ClipRRect(
        borderRadius: esquina,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: ProfundidadTema.desenfoque,
            sigmaY: ProfundidadTema.desenfoque,
          ),
          child: ColoredBox(
            color: p.veloGrafito,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: Espacio.objetivoTactil,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Espacio.x4,
                  right: Espacio.x1,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Espacio.x3,
                        ),
                        child: Text(
                          mensaje,
                          style: textos.bodyMedium!.copyWith(
                            color: c.sobreGrafito,
                          ),
                        ),
                      ),
                    ),
                    if (accion != null)
                      TextButton(
                        onPressed: alAccionar,
                        style: TextButton.styleFrom(
                          foregroundColor: c.sobreGrafito,
                        ),
                        child: Text(accion!),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

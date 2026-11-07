/// Estados de una pantalla o sección: vacío, cargando y error.
///
/// La carga son líneas en el lugar del dato con un brillo gris que las
/// recorre; nunca una rueda en medio del contenido. Con "quitar animaciones"
/// del sistema, las líneas quedan quietas.
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'avisos.dart';
import 'botones.dart';

/// Lo que no hay todavía, con lo que se puede hacer.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    required this.titulo,
    required this.mensaje,
    this.accion,
    super.key,
  });

  final String titulo;
  final String mensaje;

  /// Normalmente un [BotonSecundario].
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(titulo, style: textos.titleMedium),
        const SizedBox(height: Espacio.x1),
        Text(
          mensaje,
          style: textos.bodyMedium!.copyWith(color: context.colores.tintaSuave),
        ),
        if (accion != null) ...[const SizedBox(height: Espacio.x3), accion!],
      ],
    );
  }
}

/// Líneas de carga con brillo.
class EstadoCargando extends StatefulWidget {
  const EstadoCargando({this.lineas = 3, super.key});

  final int lineas;

  /// Ancho relativo de cada línea, en ciclo.
  static const List<double> anchos = [0.6, 0.85, 0.4, 0.7];

  @override
  State<EstadoCargando> createState() => _EstadoCargandoState();
}

class _EstadoCargandoState extends State<EstadoCargando>
    with SingleTickerProviderStateMixin {
  late final AnimationController _brillo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quieto = MediaQuery.disableAnimationsOf(context);
    if (quieto) {
      _brillo.stop();
    } else if (!_brillo.isAnimating) {
      _brillo.repeat();
    }
  }

  @override
  void dispose() {
    _brillo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Semantics(
      label: 'Cargando',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _brillo,
        builder: (context, _) {
          final t = _brillo.value * 2 - 0.5;
          final degradado = LinearGradient(
            colors: [c.regla, c.tinta.withValues(alpha: 0.04), c.regla],
            stops: [
              (t - 0.25).clamp(0.0, 1.0),
              t.clamp(0.0, 1.0),
              (t + 0.25).clamp(0.0, 1.0),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.lineas; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Espacio.x1),
                  child: FractionallySizedBox(
                    widthFactor:
                        EstadoCargando.anchos[i % EstadoCargando.anchos.length],
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: degradado,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Error de una pantalla o sección, con la opción de reintentar.
class EstadoDeError extends StatelessWidget {
  const EstadoDeError({required this.error, this.alReintentar, super.key});

  final Object? error;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AvisoEnLinea.deError(error),
        if (alReintentar != null) ...[
          const SizedBox(height: Espacio.x3),
          BotonSecundario(texto: 'Reintentar', alPresionar: alReintentar),
        ],
      ],
    );
  }
}

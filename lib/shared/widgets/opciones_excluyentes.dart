/// Opciones excluyentes: de dos a cuatro opciones visibles a la vez, de las que
/// se elige una (por ejemplo, el rol de una invitación).
///
/// La elegida se reconoce por la forma, no solo por el color: borde sólido de
/// 2 dp en tinta, un visto y el fondo `morado-tenue` de lo seleccionado
/// (DESIGN.md). Las demás llevan la regla fuerte de 1 px. Cada opción mide al
/// menos 48 dp y las opciones pasan a la línea siguiente si no caben.
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'campo.dart';

/// Una opción: el [valor] que devuelve y la [etiqueta] que se lee.
class OpcionExcluyente<T> {
  const OpcionExcluyente({required this.valor, required this.etiqueta});

  final T valor;
  final String etiqueta;
}

class OpcionesExcluyentes<T> extends StatelessWidget {
  const OpcionesExcluyentes({
    required this.etiqueta,
    required this.opciones,
    required this.valor,
    required this.alElegir,
    this.ayuda,
    super.key,
  });

  /// Rótulo que va encima de las opciones, como el de un [Campo].
  final String etiqueta;
  final List<OpcionExcluyente<T>> opciones;

  /// El valor elegido, o `null` si todavía no se eligió ninguno.
  final T? valor;

  /// Avisa la opción tocada. Con `null`, todas quedan deshabilitadas.
  final ValueChanged<T>? alElegir;

  /// Texto de ayuda bajo las opciones.
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: etiqueta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: EtiquetaDeCampo(etiqueta)),
          const SizedBox(height: Espacio.x2),
          Wrap(
            spacing: Espacio.x2,
            runSpacing: Espacio.x2,
            children: [
              for (final opcion in opciones)
                _Opcion(
                  etiqueta: opcion.etiqueta,
                  elegida: opcion.valor == valor,
                  alTocar: alElegir == null
                      ? null
                      : () => alElegir!(opcion.valor),
                ),
            ],
          ),
          if (ayuda != null) ...[
            const SizedBox(height: Espacio.x2),
            Text(
              ayuda!,
              style: textos.bodySmall!.copyWith(color: c.tintaSuave),
            ),
          ],
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.etiqueta,
    required this.elegida,
    required this.alTocar,
  });

  final String etiqueta;
  final bool elegida;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final habilitada = alTocar != null;
    final color = habilitada ? c.tinta : c.tintaTenue;
    final esquina = BorderRadius.circular(Radios.control);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: elegida,
      enabled: habilitada,
      button: true,
      label: etiqueta,
      excludeSemantics: true,
      onTap: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: Espacio.objetivoTactil,
          minWidth: 64,
        ),
        child: AnimatedContainer(
          duration: Duracion.estado,
          decoration: BoxDecoration(
            color: elegida ? c.moradoTenue : c.hoja,
            borderRadius: esquina,
            border: Border.all(
              color: !habilitada
                  ? c.regla
                  : elegida
                  ? c.tinta
                  : c.reglaFuerte,
              width: elegida ? 2 : 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: alTocar,
              borderRadius: esquina,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Espacio.x4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (elegida) ...[
                      Icon(Icons.check, size: 18, color: color),
                      const SizedBox(width: Espacio.x2),
                    ],
                    // Flexible: con texto grande una etiqueta larga pasa a otra
                    // línea en vez de desbordar.
                    Flexible(
                      child: Text(
                        etiqueta,
                        style: Theme.of(context).textTheme.labelLarge!
                            .copyWith(color: color),
                      ),
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

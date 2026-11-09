/// Chip de estado: píldora con borde fino. La línea dice el estado (sólida
/// en vivo, discontinua pendiente, punteada desactualizado, tachada
/// deshabilitado), no el color. El destacado lleva borde y texto en el acento
/// (como la insignia "Recommended" de Alpaca).
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'forma_de_linea.dart';

class ChipDeEstado extends StatelessWidget {
  const ChipDeEstado({
    required this.etiqueta,
    required this.forma,
    this.tachado = false,
    this.destacado = false,
    super.key,
  });

  const ChipDeEstado.enVivo({this.etiqueta = 'En vivo', super.key})
    : forma = FormaDeLinea.solida,
      tachado = false,
      destacado = false;

  const ChipDeEstado.pendiente({this.etiqueta = 'Pendiente', super.key})
    : forma = FormaDeLinea.discontinua,
      tachado = false,
      destacado = false;

  const ChipDeEstado.desactualizado({
    this.etiqueta = 'Desactualizado',
    super.key,
  }) : forma = FormaDeLinea.punteada,
       tachado = false,
       destacado = false;

  const ChipDeEstado.deshabilitado({this.etiqueta = 'Deshabilitado', super.key})
    : forma = FormaDeLinea.solida,
      tachado = true,
      destacado = false;

  final String etiqueta;
  final FormaDeLinea forma;

  /// Deshabilitado: texto tachado y tenue.
  final bool tachado;

  /// Lo vigente (p. ej. "Abierto · hoy"): fondo tenue y borde y texto morados.
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final color = tachado ? c.tintaTenue : (destacado ? c.morado : c.tinta);
    final estilo = Theme.of(context).textTheme.labelMedium!.copyWith(
      color: color,
      decoration: tachado ? TextDecoration.lineThrough : null,
      decorationColor: color,
    );
    return Semantics(
      label: tachado ? '$etiqueta, no disponible' : etiqueta,
      excludeSemantics: true,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: Espacio.x3),
        decoration: BoxDecoration(
          color: destacado ? c.moradoTenue : c.hoja,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: destacado ? c.morado : c.reglaFuerte),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TrazoDeLinea(forma: forma, color: destacado ? c.morado : color),
            const SizedBox(width: Espacio.x2),
            Text(etiqueta, style: estilo),
          ],
        ),
      ),
    );
  }
}

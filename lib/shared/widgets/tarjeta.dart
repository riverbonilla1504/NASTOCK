/// Superficie base: hoja blanca, regla de 1 px, esquinas de 4 dp y una sombra
/// suave desplazada hacia abajo.
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';

class Tarjeta extends StatelessWidget {
  const Tarjeta({
    required this.child,
    this.padding = const EdgeInsets.all(Espacio.x4),
    this.alTocar,
    this.elevada = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Si existe, la tarjeta se puede tocar.
  final VoidCallback? alTocar;

  /// Sin sombra para tarjetas dentro de otra superficie.
  final bool elevada;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final esquina = BorderRadius.circular(Radios.control);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.hoja,
        borderRadius: esquina,
        border: Border.all(color: c.regla),
        boxShadow: elevada ? context.profundidad.sombraTarjeta : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: alTocar,
          borderRadius: esquina,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

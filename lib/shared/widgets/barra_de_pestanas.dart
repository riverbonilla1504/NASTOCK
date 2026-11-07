/// Barra de pestañas inferior (Material 3) sobre un velo traslúcido con
/// desenfoque: el contenido se intuye detrás al desplazarse. La pantalla que
/// la usa pone `extendBody: true` en su `Scaffold`.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/tema.dart';

/// Un destino de la barra.
class Pestana {
  const Pestana({
    required this.etiqueta,
    required this.icono,
    this.iconoActivo,
  });

  final String etiqueta;
  final IconData icono;
  final IconData? iconoActivo;
}

class BarraDePestanas extends StatelessWidget {
  const BarraDePestanas({
    required this.pestanas,
    required this.actual,
    required this.alElegir,
    super.key,
  });

  final List<Pestana> pestanas;
  final int actual;
  final ValueChanged<int> alElegir;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final p = context.profundidad;
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: ProfundidadAlmanaque.desenfoque,
          sigmaY: ProfundidadAlmanaque.desenfoque,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.velo,
            border: Border(top: BorderSide(color: c.regla)),
          ),
          child: NavigationBar(
            backgroundColor: const Color(0x00000000),
            selectedIndex: actual,
            onDestinationSelected: alElegir,
            destinations: [
              for (final pestana in pestanas)
                NavigationDestination(
                  icon: Icon(pestana.icono),
                  selectedIcon: Icon(pestana.iconoActivo ?? pestana.icono),
                  label: pestana.etiqueta,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

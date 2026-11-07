/// Hoja inferior del sistema: hoja traslúcida con desenfoque detrás, una
/// sombra hacia arriba y su asa.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/tema.dart';

/// Muestra [constructor] en una hoja inferior.
Future<T?> mostrarHojaInferior<T>(
  BuildContext context, {
  required WidgetBuilder constructor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    elevation: 0,
    backgroundColor: const Color(0x00000000),
    builder: (contexto) => HojaConVelo(child: constructor(contexto)),
  );
}

/// La superficie de la hoja; la usa [mostrarHojaInferior].
class HojaConVelo extends StatelessWidget {
  const HojaConVelo({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final p = context.profundidad;
    const esquina = BorderRadius.vertical(top: Radius.circular(Radios.hoja));
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: esquina, boxShadow: p.sombraHoja),
      child: ClipRRect(
        borderRadius: esquina,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: ProfundidadAlmanaque.desenfoque,
            sigmaY: ProfundidadAlmanaque.desenfoque,
          ),
          child: ColoredBox(
            color: p.velo,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: Espacio.x3),
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.reglaFuerte,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

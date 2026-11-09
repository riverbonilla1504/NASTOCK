/// Guía de primeros pasos (CB-80, docs/08 §7.6): mientras el fondo no tiene
/// capital, le dice al Administrador por dónde empezar. Solo nombra pasos cuya
/// pantalla existe en el MVP corto.
library;

import 'package:flutter/material.dart';

import '../../../app/tema.dart';
import '../../../shared/widgets/tarjeta.dart';

/// Los cuatro pasos, en orden.
const List<({String titulo, String detalle})> pasosDePrimerosPasos = [
  (
    titulo: 'Registra el aporte',
    detalle:
        'En Capital, con el monto que reiniciaste en la cuenta paper de '
        'Alpaca.',
  ),
  (
    titulo: 'Espera su confirmación',
    detalle:
        'El sistema lo confirma solo cuando la cuenta paper tiene el '
        'efectivo, en unos minutos.',
  ),
  (
    titulo: 'Asigna cupos',
    detalle: 'En Cupos, reparte el dinero de Usuarios entre las personas.',
  ),
  (
    titulo: 'Enciende los interruptores',
    detalle: 'En Parámetros e interruptores, activa la IA y el trading.',
  ),
];

class GuiaDePrimerosPasos extends StatelessWidget {
  const GuiaDePrimerosPasos({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fondo sin capital', style: textos.titleMedium),
          const SizedBox(height: Espacio.x1),
          Text(
            'Hasta el primer aporte confirmado la IA no corre y nadie puede '
            'operar. Para empezar:',
            style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
          ),
          const SizedBox(height: Espacio.x3),
          for (var i = 0; i < pasosDePrimerosPasos.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Espacio.x2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: Espacio.x6,
                    child: Text('${i + 1}.', style: textos.titleSmall),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pasosDePrimerosPasos[i].titulo,
                          style: textos.titleSmall,
                        ),
                        Text(
                          pasosDePrimerosPasos[i].detalle,
                          style: textos.bodyMedium!.copyWith(
                            color: c.tintaSuave,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

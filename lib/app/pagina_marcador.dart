/// Marcador de una sección del MVP corto cuya pantalla aún no existe.
///
/// El menú de cada rol ya tiene el destino (docs/03 §3); mientras la historia de
/// la sección no construye su pantalla, el destino abre este marcador. Cuando
/// llega, reemplaza el `pantalla` de su `Destino` en `destinos.dart`.
library;

import 'package:flutter/material.dart';

import '../shared/widgets/barra_superior.dart';
import '../shared/widgets/estados.dart';
import '../shared/widgets/tarjeta.dart';
import 'tema.dart';

/// Título del estado vacío del marcador (decisión de tono de HU-006).
const String tituloDelMarcador = 'Aún no está disponible';

/// Mensaje del marcador.
const String mensajeDelMarcador =
    'Esta sección se habilita en una próxima entrega.';

class PaginaMarcador extends StatelessWidget {
  const PaginaMarcador({required this.etiqueta, super.key});

  /// El rótulo del destino en el menú ("Oportunidades").
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    // Deja libre el espacio de la isla de navegación, que flota sobre el cuerpo.
    final abajo = MediaQuery.paddingOf(context).bottom + Espacio.x4;
    return Scaffold(
      appBar: BarraSuperior(titulo: etiqueta),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(Espacio.x4, Espacio.x4, Espacio.x4, abajo),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: const Tarjeta(
              child: EstadoVacio(
                titulo: tituloDelMarcador,
                mensaje: mensajeDelMarcador,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

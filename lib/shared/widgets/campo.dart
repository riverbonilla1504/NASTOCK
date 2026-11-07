/// Campo de texto con la etiqueta encima, ayuda y error. El foco lleva borde
/// morado; el error, borde doble en tinta y su mensaje con marca.
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';

class Campo extends StatelessWidget {
  const Campo({
    required this.etiqueta,
    this.controlador,
    this.ayuda,
    this.error,
    this.teclado,
    this.icono,
    this.alCambiar,
    this.soloLectura = false,
    this.alTocar,
    this.pista,
    super.key,
  });

  final String etiqueta;
  final TextEditingController? controlador;

  /// Texto de ayuda bajo el campo.
  final String? ayuda;

  /// Mensaje de error ya traducido (docs/06 §9). Con error, la ayuda se oculta.
  final String? error;
  final TextInputType? teclado;
  final IconData? icono;
  final ValueChanged<String>? alCambiar;
  final bool soloLectura;
  final VoidCallback? alTocar;

  /// Texto de ejemplo dentro del campo vacío.
  final String? pista;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EtiquetaDeCampo(etiqueta),
        const SizedBox(height: Espacio.x1 + 2),
        TextField(
          controller: controlador,
          keyboardType: teclado,
          readOnly: soloLectura,
          onTap: alTocar,
          onChanged: alCambiar,
          style: textos.bodyLarge,
          decoration: InputDecoration(
            hintText: pista,
            prefixIcon: icono == null ? null : Icon(icono, size: 20),
            helperText: error == null ? ayuda : null,
            helperMaxLines: 3,
            error: error == null
                ? null
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, size: 16, color: c.tinta),
                      const SizedBox(width: Espacio.x1 + 2),
                      Expanded(
                        child: Text(
                          error!,
                          style: textos.bodySmall!.copyWith(color: c.tinta),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Rótulo que va encima de un campo (lo usan `Campo` y `CampoDePeriodo`).
class EtiquetaDeCampo extends StatelessWidget {
  const EtiquetaDeCampo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(fontSize: 13),
    );
  }
}

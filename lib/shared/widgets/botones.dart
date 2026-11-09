/// Botones del sistema (D-69): primario sólido en el acento morado, secundario
/// en gris claro y de texto en morado. Mientras una acción se envía, el botón se
/// deshabilita y dice "Procesando…" (docs/08 §9.3).
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';

/// Texto del botón mientras la acción se envía (docs/08 §9.3).
const String textoProcesando = 'Procesando…';

class BotonPrimario extends StatelessWidget {
  const BotonPrimario({
    required this.texto,
    required this.alPresionar,
    this.icono,
    this.enviando = false,
    super.key,
  });

  final String texto;

  /// Nulo deshabilita el botón.
  final VoidCallback? alPresionar;
  final IconData? icono;
  final bool enviando;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enviando ? null : alPresionar,
      child: _Contenido(texto: texto, icono: icono, enviando: enviando),
    );
  }
}

class BotonSecundario extends StatelessWidget {
  const BotonSecundario({
    required this.texto,
    required this.alPresionar,
    this.icono,
    this.enviando = false,
    super.key,
  });

  final String texto;
  final VoidCallback? alPresionar;
  final IconData? icono;
  final bool enviando;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enviando ? null : alPresionar,
      child: _Contenido(texto: texto, icono: icono, enviando: enviando),
    );
  }
}

class BotonTexto extends StatelessWidget {
  const BotonTexto({
    required this.texto,
    required this.alPresionar,
    this.icono,
    super.key,
  });

  final String texto;
  final VoidCallback? alPresionar;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: alPresionar,
      child: _Contenido(texto: texto, icono: icono, enviando: false),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.texto,
    required this.icono,
    required this.enviando,
  });

  final String texto;
  final IconData? icono;
  final bool enviando;

  @override
  Widget build(BuildContext context) {
    if (enviando) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colores.tintaTenue,
            ),
          ),
          const SizedBox(width: Espacio.x2),
          const Text(textoProcesando),
        ],
      );
    }
    if (icono == null) return Text(texto);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 20),
        const SizedBox(width: Espacio.x2),
        Text(texto),
      ],
    );
  }
}

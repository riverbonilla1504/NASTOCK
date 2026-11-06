/// Muestra un error ya traducido al español (docs/06 §9).
library;

import 'package:flutter/material.dart';

import '../../core/errores/traduccion_de_errores.dart';

/// Texto de error para cualquier excepción capturada: siempre pasa por
/// [traducirError], así que nunca muestra el texto crudo de la excepción.
class MensajeDeError extends StatelessWidget {
  const MensajeDeError({required this.error, super.key});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Text(
      traducirError(error),
      style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.error),
    );
  }
}

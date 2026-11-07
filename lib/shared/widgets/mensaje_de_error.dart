/// Muestra un error ya traducido al español (docs/06 §9).
///
/// Conserva la interfaz de TT-04; desde HU-116 se dibuja como el aviso de
/// error del sistema (borde doble y marca llena, sin rojo).
library;

import 'package:flutter/material.dart';

import '../../core/errores/traduccion_de_errores.dart';
import 'avisos.dart';

/// Texto de error para cualquier excepción capturada: siempre pasa por
/// [traducirError], así que nunca muestra el texto crudo de la excepción.
class MensajeDeError extends StatelessWidget {
  const MensajeDeError({required this.error, super.key});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return AvisoEnLinea(tipo: TipoAviso.error, mensaje: traducirError(error));
  }
}

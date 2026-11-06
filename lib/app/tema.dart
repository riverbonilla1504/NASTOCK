/// Tema base de la app. Es un punto de partida: HU-116 trae el tema, los
/// estilos y las fuentes de la v2 (docs/05 §11) y reemplaza esto.
library;

import 'package:flutter/material.dart';

ThemeData crearTema() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B5FA5)),
  );
}

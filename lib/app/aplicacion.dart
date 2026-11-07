/// Raíz de la app: temas claro y oscuro (HU-116) y enrutador.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'enrutador.dart';
import 'tema.dart';

class Aplicacion extends ConsumerWidget {
  const Aplicacion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'RiTech Inversiones',
      theme: crearTema(),
      darkTheme: crearTemaOscuro(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(enrutadorProvider),
    );
  }
}

/// Pone en marcha el tiempo real mientras la app está abierta (docs/09 §7).
///
/// Va sobre todas las pantallas (`MaterialApp.builder`). Al iniciar sesión
/// el gestor abre los canales del rol y se mide el reloj contra el servidor;
/// al cerrarla se cierran los canales. Cuando la app vuelve a primer plano
/// avisa a las pantallas para que pidan sus fotos otra vez.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reloj.dart';
import 'tiempo_real_provider.dart';

class ActivadorDeTiempoReal extends ConsumerStatefulWidget {
  const ActivadorDeTiempoReal({required this.hijo, super.key});

  final Widget hijo;

  @override
  ConsumerState<ActivadorDeTiempoReal> createState() =>
      _ActivadorDeTiempoRealState();
}

class _ActivadorDeTiempoRealState extends ConsumerState<ActivadorDeTiempoReal>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    // Vuelve a primer plano: pudo cerrarse el socket y perderse eventos.
    if (estado == AppLifecycleState.resumed) {
      ref.read(gestorDeTiempoRealProvider)?.alVolverAPrimerPlano();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observarlos los mantiene vivos: el gestor abre los canales y el reloj
    // se mide.
    ref.watch(gestorDeTiempoRealProvider);
    ref.watch(relojProvider);
    return widget.hijo;
  }
}

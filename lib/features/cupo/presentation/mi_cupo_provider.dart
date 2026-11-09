/// Estado de Mi cupo (HU-019): foto por la RPC y eventos `cupo` del canal
/// `usuario:{id}` (patrón foto y eventos de docs/08 §9.2).
///
/// Es una lista de cero o un cupo, para reutilizar [FotoYEventosNotifier]: el
/// evento avisa con el id y la versión; el dato se vuelve a pedir a la API.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/evento_de_tiempo_real.dart';
import '../../../core/realtime/foto_y_eventos.dart';
import '../data/cupo_repositorio.dart';
import '../domain/mi_cupo.dart';

class MiCupoNotifier extends FotoYEventosNotifier<MiCupo> {
  @override
  String get tabla => 'subcuentas';

  /// Solo los eventos `cupo` (los de mi canal personal), no `resumen_cambio`
  /// del canal `fondo`, que también viene de `subcuentas`.
  @override
  bool aceptaEvento(EventoDeTiempoReal evento) =>
      evento.evento == 'cupo' && super.aceptaEvento(evento);

  @override
  String idDe(MiCupo registro) => registro.id;

  @override
  int? versionDe(MiCupo registro) => registro.version;

  @override
  Future<List<MiCupo>> pedirFoto() async {
    final cupo = await ref.read(cupoRepositorioProvider).miCupo();
    return [?cupo];
  }

  @override
  Future<MiCupo?> pedirRegistro(String id) =>
      ref.read(cupoRepositorioProvider).miCupo();
}

final miCupoProvider = AsyncNotifierProvider<MiCupoNotifier, List<MiCupo>>(
  MiCupoNotifier.new,
);

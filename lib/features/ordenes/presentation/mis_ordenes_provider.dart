import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/foto_y_eventos.dart';
import '../data/mis_ordenes_repositorio.dart';
import '../domain/mi_orden.dart';

class MisOrdenesNotifier extends FotoYEventosNotifier<MiOrden> {
  @override
  String get tabla => 'ordenes';
  @override
  String idDe(MiOrden registro) => registro.id;
  @override
  int versionDe(MiOrden registro) => registro.version;
  @override
  Future<List<MiOrden>> pedirFoto() =>
      ref.watch(misOrdenesRepositorioProvider).listar();
  @override
  Future<MiOrden?> pedirRegistro(String id) =>
      ref.read(misOrdenesRepositorioProvider).obtener(id);
  @override
  List<MiOrden> ordenar(List<MiOrden> registros) =>
      [...registros]..sort((a, b) => b.creadaEn.compareTo(a.creadaEn));
}

final misOrdenesProvider =
    AsyncNotifierProvider<MisOrdenesNotifier, List<MiOrden>>(
      MisOrdenesNotifier.new,
    );

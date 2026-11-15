import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/foto_y_eventos.dart';
import '../data/alertas_repositorio.dart';
import '../domain/alerta.dart';

class AlertasNotifier extends FotoYEventosNotifier<Alerta> {
  @override
  String get tabla => 'alertas';
  @override
  String idDe(Alerta registro) => registro.id;
  @override
  int versionDe(Alerta registro) => registro.version;
  @override
  Future<List<Alerta>> pedirFoto() =>
      ref.watch(alertasRepositorioProvider).listar();
  @override
  Future<Alerta?> pedirRegistro(String id) =>
      ref.read(alertasRepositorioProvider).obtener(id);
  @override
  List<Alerta> ordenar(List<Alerta> registros) =>
      [...registros]..sort((a, b) => b.creadaEn.compareTo(a.creadaEn));
}

final alertasProvider = AsyncNotifierProvider<AlertasNotifier, List<Alerta>>(
  AlertasNotifier.new,
);

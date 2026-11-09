/// Estado de la pantalla de cupos (HU-100): foto por la API y eventos
/// `resumen_cambio` del canal `fondo` (patrón foto y eventos de HU-084).
///
/// Cada cambio de saldo de una subcuenta publica su id y versión, nunca montos
/// (docs/09 §4): el provider vuelve a pedir esa subcuenta a la API.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/foto_y_eventos.dart';
import '../data/cupos_repositorio.dart';
import '../domain/subcuenta_de_cupo.dart';

class CuposNotifier extends FotoYEventosNotifier<SubcuentaDeCupo> {
  @override
  String get tabla => 'subcuentas';

  @override
  String idDe(SubcuentaDeCupo registro) => registro.id;

  @override
  int? versionDe(SubcuentaDeCupo registro) => registro.version;

  @override
  Future<List<SubcuentaDeCupo>> pedirFoto() =>
      ref.read(cuposRepositorioProvider).listar();

  @override
  Future<SubcuentaDeCupo?> pedirRegistro(String id) =>
      ref.read(cuposRepositorioProvider).una(id);

  /// La bolsa común primero y luego los cupos por titular.
  @override
  List<SubcuentaDeCupo> ordenar(List<SubcuentaDeCupo> registros) =>
      [...registros]..sort((a, b) {
        if (a.esCupo != b.esCupo) return a.esCupo ? 1 : -1;
        return (a.titular ?? '').toLowerCase().compareTo(
          (b.titular ?? '').toLowerCase(),
        );
      });
}

final cuposProvider =
    AsyncNotifierProvider<CuposNotifier, List<SubcuentaDeCupo>>(
      CuposNotifier.new,
    );

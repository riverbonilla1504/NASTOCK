/// Posiciones de mi cupo (HU-091): foto por la API y eventos `posicion` del canal
/// `usuario:{id}` (patrón foto y eventos de docs/08 §9.2), valoradas con las
/// cotizaciones en vivo (CA-2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/evento_de_tiempo_real.dart';
import '../../../core/realtime/foto_y_eventos.dart';
import '../../mercado/presentation/mercado_provider.dart';
import '../data/cupo_repositorio.dart';
import '../domain/mi_cupo.dart';
import '../domain/posicion.dart';
import 'mi_cupo_provider.dart';

class PosicionesNotifier extends FotoYEventosNotifier<PosicionDeCupo> {
  @override
  String get tabla => 'posiciones';

  /// Solo los eventos `posicion` (mi canal personal y supervisión).
  @override
  bool aceptaEvento(EventoDeTiempoReal evento) =>
      evento.evento == 'posicion' && super.aceptaEvento(evento);

  @override
  String idDe(PosicionDeCupo registro) => registro.id;

  @override
  int? versionDe(PosicionDeCupo registro) => registro.version;

  @override
  List<PosicionDeCupo> ordenar(List<PosicionDeCupo> registros) =>
      [...registros]..sort((a, b) => a.simbolo.compareTo(b.simbolo));

  @override
  Future<List<PosicionDeCupo>> pedirFoto() async {
    // Mi cupo da la subcuenta; si cambia (un evento `cupo` tras un llenado), las
    // posiciones se piden otra vez. El `watch` va antes de esperar.
    final cupos = ref.watch(miCupoProvider.future);
    return _posiciones(await cupos);
  }

  @override
  Future<PosicionDeCupo?> pedirRegistro(String id) async {
    final todas = await _posiciones(await ref.read(miCupoProvider.future));
    for (final p in todas) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<List<PosicionDeCupo>> _posiciones(List<MiCupo> cupos) async {
    if (cupos.isEmpty) return const [];
    return ref.read(cupoRepositorioProvider).posiciones(cupos.first.id);
  }
}

/// Las posiciones abiertas de mi cupo, con su protección.
final posicionesDeMiCupoProvider =
    AsyncNotifierProvider<PosicionesNotifier, List<PosicionDeCupo>>(
      PosicionesNotifier.new,
    );

/// Las posiciones con valor y ganancia no realizada al último precio. El precio
/// viene de `cotizacionesProvider` (en vivo): al llegar uno nuevo, el valor y la
/// ganancia de la posición cambian en pantalla (CA-2). Sin cotización todavía,
/// la posición se ve sin valor.
final posicionesValoradasProvider =
    Provider<AsyncValue<List<PosicionValorada>>>((ref) {
      final posiciones = ref.watch(posicionesDeMiCupoProvider);
      final precios = ref.watch(cotizacionesProvider).value ?? const {};
      return posiciones.whenData(
        (lista) => [
          for (final p in lista)
            PosicionValorada(
              posicion: p,
              precio: precios[p.simbolo]?.precio,
              momentoDelPrecio: precios[p.simbolo]?.momento,
            ),
        ],
      );
    });

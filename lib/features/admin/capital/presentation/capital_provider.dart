/// Estado de la lista de aportes (docs/05 §9.2): la foto por la API y,
/// después, el evento `capital` del canal `admin` (docs/09 §3) vuelve a pedirla
/// cuando un aporte cambia de estado, por ejemplo cuando la conciliación lo
/// confirma. Los eventos avisan, no informan: el dato se lee por la API.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/canales.dart';
import '../../../../core/realtime/tiempo_real_provider.dart';
import '../data/capital_repositorio.dart';
import '../domain/movimiento_de_capital.dart';

Duration? _sinReintentos(int intento, Object error) => null;

final aportesProvider =
    AsyncNotifierProvider<AportesNotifier, List<MovimientoDeCapital>>(
      AportesNotifier.new,
      retry: _sinReintentos,
    );

class AportesNotifier extends AsyncNotifier<List<MovimientoDeCapital>> {
  @override
  Future<List<MovimientoDeCapital>> build() {
    final gestor = ref.watch(gestorDeTiempoRealProvider);
    if (gestor != null) {
      final eventos = gestor.eventos
          .where((e) => e.canal == Canales.admin && e.evento == 'capital')
          .listen((_) => unawaited(_actualizar()));
      final reconexiones = gestor.reconexiones.listen(
        (_) => unawaited(_actualizar()),
      );
      ref.onDispose(() {
        unawaited(eventos.cancel());
        unawaited(reconexiones.cancel());
      });
    }
    return ref.watch(capitalRepositorioProvider).listarAportes();
  }

  /// Vuelve a pedir la lista sin mostrar la carga: el cambio llega a la vista
  /// sin recargar la pantalla (CA-2). Un fallo no borra lo que ya se ve.
  Future<void> _actualizar() async {
    try {
      final lista = await ref.read(capitalRepositorioProvider).listarAportes();
      state = AsyncData(lista);
    } catch (error, pila) {
      if (state.value == null) state = AsyncError(error, pila);
    }
  }

  /// Recarga a pedido (botón «Actualizar»). Conserva la lista anterior
  /// mientras carga; si falla, el error queda junto a ella.
  Future<void> recargar() async {
    state = const AsyncLoading<List<MovimientoDeCapital>>();
    try {
      final lista = await ref.read(capitalRepositorioProvider).listarAportes();
      state = AsyncData(lista);
    } catch (error, pila) {
      state = AsyncError<List<MovimientoDeCapital>>(error, pila);
    }
  }

  /// Registra un aporte y vuelve a pedir la lista. Si la RPC falla, lanza su
  /// excepción (la pantalla la traduce con `traducirError`).
  Future<MovimientoDeCapital> registrar({
    required double monto,
    String? referencia,
    String? nota,
  }) async {
    final aporte = await ref
        .read(capitalRepositorioProvider)
        .registrar(monto: monto, referencia: referencia, nota: nota);
    await _actualizar();
    return aporte;
  }

  /// Anula un aporte y vuelve a pedir la lista, también si falla: un
  /// `ESTADO_INVALIDO` significa que la pantalla estaba desactualizada.
  Future<MovimientoDeCapital> anular({
    required String id,
    required String motivo,
  }) async {
    try {
      return await ref
          .read(capitalRepositorioProvider)
          .anular(id: id, motivo: motivo);
    } finally {
      await _actualizar();
    }
  }
}

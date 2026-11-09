/// Estado de Parámetros e Interruptores (HU-101): la foto por la API y, después,
/// los eventos `parametro` e `interruptor` del canal `admin` (docs/09 §3), que
/// avisan sin datos: la lista vuelve a pedirse por la API.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/canales.dart';
import '../../../../core/realtime/tiempo_real_provider.dart';
import '../data/parametros_repositorio.dart';
import '../domain/parametro.dart';

Duration? _sinReintentos(int intento, Object error) => null;

/// Vuelve a calcular [notifier] cuando llega un evento [evento] del canal
/// `admin` o cuando se reconecta el tiempo real.
void _escuchar(Ref ref, String evento, void Function() alCambiar) {
  final gestor = ref.watch(gestorDeTiempoRealProvider);
  if (gestor == null) return;
  final eventos = gestor.eventos
      .where((e) => e.canal == Canales.admin && e.evento == evento)
      .listen((_) => alCambiar());
  final reconexiones = gestor.reconexiones.listen((_) => alCambiar());
  ref.onDispose(() {
    unawaited(eventos.cancel());
    unawaited(reconexiones.cancel());
  });
}

final parametrosProvider =
    AsyncNotifierProvider<ParametrosNotifier, List<Parametro>>(
      ParametrosNotifier.new,
      retry: _sinReintentos,
    );

class ParametrosNotifier extends AsyncNotifier<List<Parametro>> {
  @override
  Future<List<Parametro>> build() {
    _escuchar(ref, 'parametro', ref.invalidateSelf);
    return ref.watch(parametrosRepositorioProvider).listar();
  }

  Future<void> actualizar(String clave, Object? valor, String motivo) async {
    await ref
        .read(parametrosRepositorioProvider)
        .actualizar(clave, valor, motivo);
    ref.invalidate(historialProvider(clave));
    ref.invalidateSelf();
  }
}

/// El historial de cambios de un parámetro; se pide al abrir su edición.
final historialProvider = FutureProvider.autoDispose
    .family<List<CambioDeParametro>, String>(
      (ref, clave) => ref.watch(parametrosRepositorioProvider).historial(clave),
    );

final interruptoresProvider =
    AsyncNotifierProvider<InterruptoresNotifier, Interruptores>(
      InterruptoresNotifier.new,
      retry: _sinReintentos,
    );

class InterruptoresNotifier extends AsyncNotifier<Interruptores> {
  @override
  Future<Interruptores> build() {
    _escuchar(ref, 'interruptor', ref.invalidateSelf);
    return ref.watch(parametrosRepositorioProvider).interruptores();
  }

  Future<void> reanudar(Interruptor interruptor) async {
    await ref.read(parametrosRepositorioProvider).reanudar(interruptor);
    ref.invalidateSelf();
  }

  Future<void> frenar(Interruptor interruptor, String motivo) async {
    await ref.read(parametrosRepositorioProvider).frenar(interruptor, motivo);
    ref.invalidateSelf();
  }
}

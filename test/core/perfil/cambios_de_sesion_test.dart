import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/perfil/perfil_repositorio.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

/// Imita `onAuthStateChange` de Supabase (un `ReplaySubject`): cada suscriptor
/// nuevo recibe toda la historia y después los eventos nuevos.
class _OrigenQueRepite {
  final _historia = <AuthState>[];
  final _vivos = StreamController<AuthState>.broadcast(sync: true);
  int suscripciones = 0;

  void emitir(AuthChangeEvent evento) {
    final estado = AuthState(evento, null);
    _historia.add(estado);
    _vivos.add(estado);
  }

  Stream<AuthState> get stream => Stream.multi((salida) {
    suscripciones++;
    _historia.forEach(salida.add);
    final s = _vivos.stream.listen(salida.add);
    salida.onCancel = s.cancel;
  });
}

void main() {
  test(
    'EC-039: suscribirse otra vez no repite la historia de la sesión',
    () async {
      final origen = _OrigenQueRepite()
        ..emitir(AuthChangeEvent.initialSession)
        ..emitir(AuthChangeEvent.signedIn);
      final cambios = CambiosDeSesion(origen.stream);
      addTearDown(cambios.cerrar);

      // Lo que hace perfilProvider: se suscribe, y en cada reconstrucción
      // cancela y vuelve a suscribirse.
      var avisos = 0;
      for (var i = 0; i < 5; i++) {
        final s = cambios.stream.listen((_) => avisos++);
        await pumpEventQueue();
        await s.cancel();
      }

      // El signedIn de la historia llega a lo sumo una vez, y a Supabase se le
      // pide la suscripción una sola vez.
      expect(avisos, lessThanOrEqualTo(1));
      expect(origen.suscripciones, 1);
    },
  );

  test('avisa de los cambios nuevos y no de la sesión inicial', () async {
    final origen = _OrigenQueRepite();
    final cambios = CambiosDeSesion(origen.stream);
    addTearDown(cambios.cerrar);

    var avisos = 0;
    cambios.stream.listen((_) => avisos++);
    await pumpEventQueue();

    origen.emitir(AuthChangeEvent.initialSession);
    await pumpEventQueue();
    expect(avisos, 0);

    origen
      ..emitir(AuthChangeEvent.signedIn)
      ..emitir(AuthChangeEvent.tokenRefreshed)
      ..emitir(AuthChangeEvent.signedOut);
    await pumpEventQueue();
    expect(avisos, 3);
  });
}

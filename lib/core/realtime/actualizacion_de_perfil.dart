/// Consume solo cambios del perfil propio; agrupa eventos mientras renueva Auth.
library;

import 'dart:async';

import 'evento_de_tiempo_real.dart';

class ActualizacionDePerfil {
  ActualizacionDePerfil({
    required Stream<EventoDeTiempoReal> eventos,
    required this.idUsuario,
    required this.renovar,
    required this.alFallar,
  }) {
    _suscripcion = eventos.listen((evento) {
      if (evento.canal == 'usuario:$idUsuario' &&
          evento.evento == 'perfil_actualizado') {
        unawaited(actualizar());
      }
    });
  }

  final String idUsuario;
  final Future<void> Function() renovar;
  final void Function(Object, StackTrace) alFallar;
  late final StreamSubscription<EventoDeTiempoReal> _suscripcion;
  bool _cerrada = false;
  bool _renovando = false;
  bool _pendiente = false;

  Future<void> actualizar() async {
    if (_cerrada) return;
    _pendiente = true;
    if (_renovando) return;
    _renovando = true;
    try {
      while (_pendiente && !_cerrada) {
        _pendiente = false;
        await renovar();
      }
    } catch (error, pila) {
      if (!_cerrada) alFallar(error, pila);
    } finally {
      _renovando = false;
    }
  }

  Future<void> cerrar() async {
    _cerrada = true;
    await _suscripcion.cancel();
  }
}

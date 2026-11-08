/// Gestor de tiempo real: abre los canales de un rol, deduce el estado de la
/// conexión y avisa cuándo hay que pedir las fotos otra vez (docs/09 §7).
library;

import 'dart:async';

import 'estado_conexion.dart';
import 'evento_de_tiempo_real.dart';
import 'fuente_de_tiempo_real.dart';

class GestorDeTiempoReal {
  /// Abre de inmediato los [canales] en [fuente]. Quien lo crea debe llamar a
  /// [cerrar] al cerrar la sesión.
  GestorDeTiempoReal(this._fuente, Iterable<String> canales)
    : canales = List.unmodifiable(canales),
      _control = ControlDeConexion(canales) {
    _suscripciones = [
      _fuente.eventos.listen(_eventos.add),
      _fuente.senales.listen(_alSenal),
    ];
    canales.forEach(_fuente.abrirCanal);
  }

  final FuenteDeTiempoReal _fuente;
  final ControlDeConexion _control;
  late final List<StreamSubscription<Object?>> _suscripciones;
  final StreamController<EventoDeTiempoReal> _eventos =
      StreamController.broadcast();
  final StreamController<EstadoConexion> _estados =
      StreamController.broadcast();
  final StreamController<void> _reconexiones = StreamController.broadcast();
  bool _cerrado = false;

  /// Los canales que abrió, en el orden de docs/09 §3.
  final List<String> canales;

  /// Los canales que el servidor ya aceptó.
  Set<String> get canalesSuscritos => _control.canalesSuscritos;

  /// Los eventos de todos los canales abiertos (cualquiera sea el canal).
  Stream<EventoDeTiempoReal> get eventos => _eventos.stream;

  EstadoConexion get estado => _control.estado;

  /// Cada cambio del estado de la conexión.
  Stream<EstadoConexion> get estados => _estados.stream;

  /// Avisa cuando las pantallas deben pedir sus fotos completas otra vez: al
  /// reconectar (pudieron perderse eventos, CB-66) y al volver la app a primer
  /// plano. No avisa de la conexión inicial: cada pantalla pide su foto al
  /// montarse.
  Stream<void> get reconexiones => _reconexiones.stream;

  void _alSenal(SenalDeConexion senal) {
    final antes = _control.estado;
    final reconectado = _control.alSenal(senal);
    if (_control.estado != antes) _estados.add(_control.estado);
    if (reconectado) _reconexiones.add(null);
  }

  /// La app volvió a primer plano: el sistema pudo cerrar el socket y los
  /// avisos se quedaron en el push, así que las fotos se piden otra vez.
  void alVolverAPrimerPlano() {
    if (!_cerrado) _reconexiones.add(null);
  }

  /// Cierra los canales y deja de avisar. Es lo que hace el cierre de sesión.
  Future<void> cerrar() async {
    if (_cerrado) return;
    _cerrado = true;
    for (final suscripcion in _suscripciones) {
      await suscripcion.cancel();
    }
    await _fuente.cerrarCanales();
    await _eventos.close();
    await _estados.close();
    await _reconexiones.close();
  }
}

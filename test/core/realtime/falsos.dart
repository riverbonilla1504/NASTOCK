import 'dart:async';

import 'package:inversiones/core/realtime/estado_conexion.dart';
import 'package:inversiones/core/realtime/evento_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/fuente_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/reloj.dart';

/// Fuente de tiempo real en memoria: la prueba decide qué llega y cuándo.
class FuenteFalsa implements FuenteDeTiempoReal {
  final StreamController<EventoDeTiempoReal> _eventos =
      StreamController.broadcast();
  final StreamController<SenalDeConexion> _senales =
      StreamController.broadcast();

  /// Los canales que se abrieron, en orden.
  final List<String> abiertos = [];
  int cierres = 0;

  @override
  Stream<EventoDeTiempoReal> get eventos => _eventos.stream;

  @override
  Stream<SenalDeConexion> get senales => _senales.stream;

  @override
  void abrirCanal(String canal) => abiertos.add(canal);

  @override
  Future<void> cerrarCanales() async => cierres++;

  /// Llega un evento de entidad por [canal].
  void evento(
    String canal,
    String nombre, {
    required String tabla,
    String? id,
    int? version,
    String? estado,
  }) => _eventos.add(
    EventoDeTiempoReal(
      canal: canal,
      evento: nombre,
      carga: {
        'tabla': tabla,
        'id': ?id,
        'version': ?version,
        'estado': ?estado,
      },
    ),
  );

  void senal(SenalDeConexion senal) => _senales.add(senal);

  /// El servidor acepta todas las suscripciones abiertas.
  void suscribirTodos() {
    for (final canal in abiertos) {
      _senales.add(CanalSuscrito(canal));
    }
  }
}

/// Reloj del servidor en memoria.
class RelojRepositorioFalso implements RelojRepositorio {
  RelojRepositorioFalso(this.servidor);

  /// La hora que responde el servidor; si es un [Future] pendiente, la
  /// medición espera.
  DateTime Function() servidor;
  Object? error;
  int consultas = 0;

  @override
  Future<DateTime> horaDelServidor() async {
    consultas++;
    final falla = error;
    if (falla != null) throw falla;
    return servidor();
  }
}

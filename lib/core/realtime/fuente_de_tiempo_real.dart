/// La fuente de tiempo real: el único lugar de la app que habla con Realtime
/// de Supabase (docs/05 §9.1).
///
/// El gestor y las pantallas dependen de [FuenteDeTiempoReal], no de
/// `supabase_flutter`, así se prueban con una fuente falsa.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/cliente_supabase.dart';
import 'estado_conexion.dart';
import 'evento_de_tiempo_real.dart';

abstract interface class FuenteDeTiempoReal {
  /// Los mensajes de todos los canales abiertos.
  Stream<EventoDeTiempoReal> get eventos;

  /// Lo que pasa con el socket y con cada canal.
  Stream<SenalDeConexion> get senales;

  /// Abre y se suscribe al canal privado [canal]. Los clientes solo escuchan:
  /// nunca publican (docs/09 §3).
  void abrirCanal(String canal);

  /// Cierra todos los canales abiertos.
  Future<void> cerrarCanales();
}

/// [FuenteDeTiempoReal] sobre Realtime de `supabase_flutter`.
///
/// Los canales son siempre privados (EC-013). La renovación del token la
/// resuelve `supabase_flutter`, que actualiza el token del socket: no hay que
/// volver a suscribirse (docs/09 §7).
class FuenteSupabaseDeTiempoReal implements FuenteDeTiempoReal {
  FuenteSupabaseDeTiempoReal(this._cliente) {
    // Estas funciones no se pueden quitar del cliente: se registran una vez y
    // dejan de avisar al cerrar la fuente.
    _cliente.realtime
      ..onOpen(() => _senal(const SocketAbierto()))
      ..onClose((_) => _senal(const SocketCerrado()))
      ..onError((_) => _senal(const SocketFallo()));
  }

  final SupabaseClient _cliente;
  final List<RealtimeChannel> _canales = [];
  final StreamController<EventoDeTiempoReal> _eventos =
      StreamController.broadcast();
  final StreamController<SenalDeConexion> _senales =
      StreamController.broadcast();
  bool _cerrada = false;

  @override
  Stream<EventoDeTiempoReal> get eventos => _eventos.stream;

  @override
  Stream<SenalDeConexion> get senales => _senales.stream;

  void _senal(SenalDeConexion senal) {
    if (!_cerrada) _senales.add(senal);
  }

  @override
  void abrirCanal(String canal) {
    final abierto = _cliente.channel(
      canal,
      opts: const RealtimeChannelConfig(private: true),
    );
    _canales.add(abierto);
    abierto
        .onBroadcast(
          event: '*',
          callback: (mensaje) {
            if (!_cerrada) {
              _eventos.add(EventoDeTiempoReal.desdeMensaje(canal, mensaje));
            }
          },
        )
        .subscribe((estado, _) {
          // Un canal ya cerrado por [cerrarCanales] no cuenta como caída.
          if (!_canales.contains(abierto)) return;
          _senal(
            estado == RealtimeSubscribeStatus.subscribed
                ? CanalSuscrito(canal)
                : CanalCaido(canal),
          );
        });
  }

  @override
  Future<void> cerrarCanales() async {
    final abiertos = List.of(_canales);
    _canales.clear();
    await Future.wait(abiertos.map(_cliente.removeChannel));
  }

  void cerrar() {
    _cerrada = true;
    unawaited(_eventos.close());
    unawaited(_senales.close());
  }
}

final fuenteDeTiempoRealProvider = Provider<FuenteDeTiempoReal>((ref) {
  final fuente = FuenteSupabaseDeTiempoReal(ref.watch(clienteSupabaseProvider));
  ref.onDispose(fuente.cerrar);
  return fuente;
});

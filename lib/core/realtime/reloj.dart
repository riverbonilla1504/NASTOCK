/// Reloj corregido con el servidor (FR-190, CB-70, docs/08 §9.1).
///
/// El reloj del teléfono puede estar desfasado. Las cuentas regresivas (la
/// apertura y el cierre del mercado, la vigencia de una sugerencia) se calculan
/// con la hora del dispositivo más el desfase medido contra el servidor. Las
/// decisiones las valida siempre el servidor: esto solo hace que la pantalla
/// cuente bien.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/cliente_supabase.dart';
import 'tiempo_real_provider.dart';

/// El desfase del reloj del dispositivo respecto del servidor, medido en una
/// consulta que salió a las [envio], llegó el [servidor] a las [recepcion] del
/// reloj del dispositivo.
///
/// Se supone que la respuesta tardó lo mismo en ir que en volver: la hora del
/// servidor corresponde a la mitad del viaje. Positivo si el servidor va
/// adelantado respecto del dispositivo.
Duration calcularDesfase({
  required DateTime envio,
  required DateTime recepcion,
  required DateTime servidor,
}) {
  final mitadDelViaje = recepcion.difference(envio) ~/ 2;
  return servidor.difference(envio.add(mitadDelViaje));
}

/// La hora del dispositivo corregida con el [desfase] medido contra el
/// servidor.
class RelojCorregido {
  const RelojCorregido({
    this.desfase = Duration.zero,
    this.medido = false,
    this.ahoraLocal = DateTime.now,
  });

  /// Servidor menos dispositivo. Sin medir (o si la medición falló) es cero.
  final Duration desfase;

  /// Si ya se midió el desfase contra el servidor.
  final bool medido;

  /// La hora de este dispositivo (se reemplaza en las pruebas).
  final DateTime Function() ahoraLocal;

  /// La hora del servidor ahora, en UTC.
  DateTime ahora() => ahoraLocal().toUtc().add(desfase);

  /// Cuánto falta para [momento] según el servidor. Negativo si ya pasó.
  Duration faltaPara(DateTime momento) => momento.difference(ahora());

  RelojCorregido conDesfase(Duration nuevo) =>
      RelojCorregido(desfase: nuevo, medido: true, ahoraLocal: ahoraLocal);

  @override
  bool operator ==(Object other) =>
      other is RelojCorregido &&
      other.desfase == desfase &&
      other.medido == medido;

  @override
  int get hashCode => Object.hash(desfase, medido);
}

abstract interface class RelojRepositorio {
  /// La hora del servidor ahora.
  Future<DateTime> horaDelServidor();
}

/// Lee la hora del servidor de `estado_mercado()`, que la devuelve en `ahora`
/// (docs/06 §6) y la puede llamar cualquier cuenta activa.
class RelojRepositorioSupabase implements RelojRepositorio {
  const RelojRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<DateTime> horaDelServidor() async {
    final filas = await _cliente.rpc('estado_mercado') as List<dynamic>;
    final fila = filas.first as Map<String, dynamic>;
    return DateTime.parse(fila['ahora'] as String).toUtc();
  }
}

final relojRepositorioProvider = Provider<RelojRepositorio>(
  (ref) => RelojRepositorioSupabase(ref.watch(clienteSupabaseProvider)),
);

/// La hora de este dispositivo. Se reemplaza en las pruebas.
final ahoraLocalProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// `relojProvider` (docs/08 §9.1): el desfase entre el reloj del teléfono y el
/// del servidor. Se mide al iniciar sesión, al reconectar y al volver a primer
/// plano; mientras no se mide, o si la medición falla, el desfase es cero.
class RelojNotifier extends Notifier<RelojCorregido> {
  @override
  RelojCorregido build() {
    final ahoraLocal = ref.watch(ahoraLocalProvider);
    final gestor = ref.watch(gestorDeTiempoRealProvider);
    if (gestor != null) {
      final suscripcion = gestor.reconexiones.listen((_) => medir());
      ref.onDispose(suscripcion.cancel);
      // La primera medición, ya con la sesión iniciada.
      Future.microtask(medir);
    }
    return RelojCorregido(ahoraLocal: ahoraLocal);
  }

  /// Mide el desfase contra el servidor. Si no puede (sin conexión), conserva
  /// el desfase que tenía.
  Future<void> medir() async {
    if (!ref.mounted) return;
    final ahoraLocal = ref.read(ahoraLocalProvider);
    final repositorio = ref.read(relojRepositorioProvider);
    final envio = ahoraLocal();
    try {
      final servidor = await repositorio.horaDelServidor();
      final recepcion = ahoraLocal();
      if (!ref.mounted) return;
      state = state.conDesfase(
        calcularDesfase(envio: envio, recepcion: recepcion, servidor: servidor),
      );
    } on Object {
      // Sin red o sin respuesta: se queda el desfase anterior y se vuelve a
      // medir en la próxima reconexión.
    }
  }
}

final relojProvider = NotifierProvider<RelojNotifier, RelojCorregido>(
  RelojNotifier.new,
);

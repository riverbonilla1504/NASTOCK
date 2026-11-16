/// HU-032: vigencia por símbolo con el reloj corregido (RR-11).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/reloj.dart';
import '../../../core/realtime/tiempo_real_provider.dart';
import '../../../core/supabase/cliente_supabase.dart';
import '../domain/mercado.dart';
import 'mercado_provider.dart';

/// Sin cotización o sin parámetro verificado no se habilitan compras.
/// Se compara la hora del proveedor, nunca la hora de recepción.
bool cotizacionVigente(
  Cotizacion? cotizacion,
  Duration? maxima,
  DateTime ahora,
) =>
    cotizacion != null &&
    maxima != null &&
    maxima > Duration.zero &&
    ahora.difference(cotizacion.momento) <= maxima;

/// Todos los roles activos pueden leer este parámetro por RLS.
/// El canal admin no llega al Usuario: se relee también cada minuto.
final antiguedadMaximaProvider = FutureProvider.autoDispose<Duration>((
  ref,
) async {
  final temporizador = Timer.periodic(
    const Duration(minutes: 1),
    (_) => ref.invalidateSelf(),
  );
  ref.onDispose(temporizador.cancel);
  final gestor = ref.watch(gestorDeTiempoRealProvider);
  final eventos = gestor?.eventos
      .where((e) => e.canal == 'admin' && e.evento == 'parametro')
      .listen((_) => ref.invalidateSelf());
  final reconexiones = gestor?.reconexiones.listen((_) => ref.invalidateSelf());
  ref.onDispose(() {
    eventos?.cancel();
    reconexiones?.cancel();
  });
  final fila = await ref
      .watch(clienteSupabaseProvider)
      .from('parametros')
      .select('valor')
      .eq('clave', 'mercado.max_antiguedad_cotizacion_seg')
      .single();
  final valor = fila['valor'];
  if (valor is! num || !valor.isFinite || valor < 15 || valor > 600) {
    throw StateError('Antigüedad máxima no disponible');
  }
  return Duration(
    microseconds: (valor * Duration.microsecondsPerSecond).round(),
  );
}, retry: (intento, error) => null);

/// Cambia aunque no llegue ningún evento (cron detenido o mercado suspendido).
final cotizacionVigenteProvider = Provider.autoDispose.family<bool, String>((
  ref,
  simbolo,
) {
  ref.watch(segundoProvider);
  return cotizacionVigente(
    ref.watch(cotizacionesProvider).value?[simbolo],
    ref.watch(antiguedadMaximaProvider).asData?.value,
    ref.watch(relojProvider).ahora(),
  );
});

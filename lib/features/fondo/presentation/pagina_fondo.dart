import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../core/formato/formato_dinero.dart';
import '../../../core/formato/formato_porcentaje.dart';
import '../../../core/realtime/tiempo_real_provider.dart';
import '../../../core/supabase/cliente_supabase.dart';
import '../../../shared/widgets/barra_superior.dart';
import '../../../shared/widgets/tarjeta.dart';

typedef ResumenDeBolsillo = ({
  String bolsillo,
  num efectivo,
  num posiciones,
  num patrimonio,
  num pesoActual,
  num pesoObjetivo,
});

final resumenFondoProvider =
    FutureProvider.autoDispose<List<ResumenDeBolsillo>>((ref) async {
      final gestor = ref.watch(gestorDeTiempoRealProvider);
      if (gestor != null) {
        final cambios = gestor.eventos
            .where((e) => e.canal == 'fondo' && e.evento == 'resumen_cambio')
            .listen((_) => ref.invalidateSelf());
        final reconexiones = gestor.reconexiones.listen(
          (_) => ref.invalidateSelf(),
        );
        ref.onDispose(() {
          unawaited(cambios.cancel());
          unawaited(reconexiones.cancel());
        });
      }
      final filas = await ref
          .watch(clienteSupabaseProvider)
          .rpc<List<dynamic>>('resumen_fondo');
      return [
        for (final fila in filas.cast<Map<String, dynamic>>())
          (
            bolsillo: fila['bolsillo'] as String,
            efectivo: fila['efectivo'] as num,
            posiciones: fila['valor_posiciones'] as num,
            patrimonio: fila['patrimonio'] as num,
            pesoActual: fila['peso_actual_pct'] as num,
            pesoObjetivo: fila['peso_objetivo_pct'] as num,
          ),
      ];
    });

class PaginaFondo extends ConsumerWidget {
  const PaginaFondo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(resumenFondoProvider);
    final titulo = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: const BarraSuperior(titulo: 'Fondo'),
      body: resumen.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(resumenFondoProvider),
            child: const Text('No se pudo cargar el fondo. Reintentar'),
          ),
        ),
        data: (bolsillos) => bolsillos.isEmpty
            ? const Center(
                child: Text('El resumen del fondo no está disponible.'),
              )
            : ListView(
                padding: const EdgeInsets.all(Espacio.x4),
                children: [
                  Text(
                    'Patrimonio del fondo: ${formatearUsd(bolsillos.fold<num>(0, (total, b) => total + b.patrimonio))}',
                    style: titulo,
                  ),
                  for (final b in bolsillos)
                    Padding(
                      padding: const EdgeInsets.only(top: Espacio.x3),
                      child: Tarjeta(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(switch (b.bolsillo) {
                              'reserva' => 'Reserva',
                              'arriesgadas' => 'Arriesgadas',
                              'usuarios' => 'Usuarios',
                              _ => b.bolsillo,
                            }, style: titulo),
                            Text('Efectivo: ${formatearUsd(b.efectivo)}'),
                            Text(
                              'Valor de las posiciones: ${formatearUsd(b.posiciones)}',
                            ),
                            Text('Patrimonio: ${formatearUsd(b.patrimonio)}'),
                            Text(
                              'Peso actual: ${formatearPorcentaje(b.pesoActual).replaceFirst('+', '')}',
                            ),
                            Text(
                              'Peso objetivo: ${formatearPorcentaje(b.pesoObjetivo).replaceFirst('+', '')}',
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

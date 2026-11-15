import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../shared/widgets/avisos.dart';
import '../../../shared/widgets/barra_superior.dart';
import '../../../shared/widgets/estados.dart';
import '../../../shared/widgets/tarjeta.dart';
import '../../../shared/widgets/dialogo_de_confirmacion.dart';
import '../data/mis_ordenes_repositorio.dart';
import '../domain/mi_orden.dart';
import 'mis_ordenes_provider.dart';

class PaginaMisOrdenes extends ConsumerWidget {
  const PaginaMisOrdenes({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(misOrdenesProvider);
    Future<void> recargar() async {
      ref.invalidate(misOrdenesProvider);
      try {
        await ref.read(misOrdenesProvider.future);
      } catch (_) {
        /* El estado muestra el error. */
      }
    }

    return Scaffold(
      appBar: const BarraSuperior(titulo: 'Mis órdenes'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: RefreshIndicator(
            onRefresh: recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Espacio.x4),
              children: switch (estado) {
                AsyncData(:final value) =>
                  value.isEmpty
                      ? [
                          const EstadoVacio(
                            titulo: 'Aún no tienes órdenes',
                            mensaje: 'Tus compras y ventas aparecen aquí con su estado.',
                          ),
                        ]
                      : [
                          for (final orden in value)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: Espacio.x3,
                              ),
                              child: _TarjetaOrden(
                                orden: orden,
                                recargar: recargar,
                              ),
                            ),
                        ],
                AsyncError(:final error) => [
                  EstadoDeError(error: error, alReintentar: recargar),
                ],
                _ => [const EstadoCargando(lineas: 4)],
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaOrden extends ConsumerWidget {
  const _TarjetaOrden({required this.orden, required this.recargar});
  final MiOrden orden;
  final Future<void> Function() recargar;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendiente =
        orden.cancelacionSolicitada &&
        orden.estado != 'cancelada' &&
        orden.estado != 'llenada';
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${orden.simbolo} · ${orden.lado == 'compra' ? 'Compra' : 'Venta'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Espacio.x2),
          Text(orden.etiqueta),
          Text('Llenadas: ${orden.llenada} de ${orden.cantidad}'),
          if (pendiente)
            const AvisoEnLinea(
              tipo: TipoAviso.informacion,
              mensaje: 'Cancelación solicitada. El broker debe confirmarla; lo llenado se conserva.',
            ),
          if (orden.cancelacionSolicitada && orden.estado == 'llenada')
            const AvisoEnLinea(
              tipo: TipoAviso.advertencia,
              mensaje: 'La orden se llenó antes de confirmar la cancelación.',
            ),
          if (orden.puedeCancelar)
            TextButton(
              onPressed: () async {
                await confirmarAccion(
                  context,
                  titulo: '¿Solicitar la cancelación?',
                  simbolo: orden.simbolo,
                  monto: orden.retencion,
                  textoConfirmar: 'Solicitar cancelación',
                  detalle: 'Lo que ya se llenó se conserva. La cancelación puede coincidir con el llenado.',
                  alConfirmar: () async {
                    try {
                      await ref
                          .read(misOrdenesRepositorioProvider)
                          .cancelar(orden.id);
                    } finally {
                      await recargar();
                    }
                  },
                );
              },
              child: const Text('Cancelar orden'),
            ),
        ],
      ),
    );
  }
}

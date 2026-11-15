import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../shared/widgets/avisos.dart';
import '../../../shared/widgets/barra_superior.dart';
import '../../../shared/widgets/estados.dart';
import 'alertas_provider.dart';

class PaginaAlertas extends ConsumerWidget {
  const PaginaAlertas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(alertasProvider);
    Future<void> recargar() async {
      ref.invalidate(alertasProvider);
      try {
        await ref.read(alertasProvider.future);
      } catch (_) {
        // El proveedor conserva el fallo para EstadoDeError y su reintento.
      }
    }

    return Scaffold(
      appBar: const BarraSuperior(titulo: 'Alertas'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: RefreshIndicator(
            onRefresh: recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                Espacio.x4,
                Espacio.x4,
                Espacio.x4,
                Espacio.x8 + MediaQuery.paddingOf(context).bottom,
              ),
              children: switch (estado) {
                AsyncData(:final value) =>
                  value.isEmpty
                      ? [
                          const EstadoVacio(
                            titulo: 'No tienes alertas activas',
                            mensaje: 'Aquí aparecen los avisos del sistema que te corresponden.',
                          ),
                        ]
                      : [
                          for (final alerta in value)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: Espacio.x3,
                              ),
                              child: AvisoEnLinea(
                                key: ValueKey(alerta.id),
                                titulo: alerta.titulo,
                                mensaje: alerta.cuerpo,
                                tipo: switch (alerta.severidad) {
                                  'critica' => TipoAviso.error,
                                  'advertencia' => TipoAviso.advertencia,
                                  _ => TipoAviso.informacion,
                                },
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

/// Pantalla Mi cupo (HU-019, RN-20): cuánto tengo y cuánto puedo invertir.
///
/// Solo muestra lo que `mi_cupo()` entrega: cada cifra la calcula el servidor.
/// Se actualiza sola con el evento `cupo` (gestor de tiempo real) y al
/// deslizar hacia abajo. Las posiciones, protecciones e historial se agregan
/// en HU-091 y HU-093.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../shared/widgets/avisos.dart';
import '../../../shared/widgets/barra_superior.dart';
import '../../../shared/widgets/cifras.dart';
import '../../../shared/widgets/estados.dart';
import '../../../shared/widgets/tarjeta.dart';
import '../domain/mi_cupo.dart';
import 'mi_cupo_provider.dart';

/// Ancho máximo del contenido en ventanas anchas.
const double anchoMaximoDeMiCupo = 720;

class PaginaMiCupo extends ConsumerWidget {
  const PaginaMiCupo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(miCupoProvider);

    Future<void> recargar() async {
      ref.invalidate(miCupoProvider);
      await ref.read(miCupoProvider.future).catchError((_) => <MiCupo>[]);
    }

    return Scaffold(
      appBar: const BarraSuperior(titulo: 'Mi cupo'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: anchoMaximoDeMiCupo),
          child: RefreshIndicator(
            onRefresh: recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                Espacio.x4,
                Espacio.x4,
                Espacio.x4,
                Espacio.x8,
              ),
              children: switch (estado) {
                AsyncData(:final value) when value.isEmpty => const [
                  EstadoVacio(
                    titulo: 'Aún no tienes un cupo',
                    mensaje:
                        'Tu cupo aparece aquí cuando el Administrador lo '
                        'habilita.',
                  ),
                ],
                AsyncData(:final value) => _contenido(context, value.first),
                AsyncError(:final error) => [
                  EstadoDeError(error: error, alReintentar: recargar),
                ],
                _ => const [EstadoCargando(lineas: 4)],
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenido(BuildContext context, MiCupo cupo) {
    final textos = Theme.of(context).textTheme;
    final suave = textos.bodyMedium!.copyWith(
      color: context.colores.tintaSuave,
    );

    // CB-80: antes del primer aporte el fondo no tiene capital.
    if (!cupo.fondoConCapital) {
      return const [
        EstadoVacio(
          titulo: 'Fondo sin capital',
          mensaje:
              'El fondo todavía no recibe su primer aporte. Cuando lo haga y '
              'el Administrador te asigne dinero, lo verás aquí.',
        ),
      ];
    }

    Widget fila(String etiqueta, Widget valor) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacio.x2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(etiqueta, style: suave)),
          const SizedBox(width: Espacio.x3),
          valor,
        ],
      ),
    );

    return [
      Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patrimonio de tu cupo', style: suave),
            const SizedBox(height: Espacio.x1),
            CifraUsd(cupo.patrimonio, tamano: TamanoCifra.grande),
          ],
        ),
      ),
      const SizedBox(height: Espacio.x4),
      Tarjeta(
        child: Column(
          children: [
            fila('Disponible para invertir', CifraUsd(cupo.disponible)),
            fila('Efectivo', CifraUsd(cupo.efectivo)),
            fila('Retenido', CifraUsd(cupo.retenido)),
            fila('Invertido', CifraUsd(cupo.invertido)),
          ],
        ),
      ),
      const SizedBox(height: Espacio.x4),
      Tarjeta(
        child: Column(
          children: [
            fila('Resultado realizado', CifraUsd(cupo.resultadoRealizado)),
            fila('Resultado no realizado', CifraUsd(cupo.resultadoNoRealizado)),
            fila(
              'Rendimiento',
              cupo.rendimiento == null
                  ? Text('Sin datos aún', style: suave)
                  : Variacion(cupo.rendimiento! * 100),
            ),
          ],
        ),
      ),
      const SizedBox(height: Espacio.x4),
      const AvisoEnLinea(
        tipo: TipoAviso.informacion,
        mensaje:
            'Cifras en USD de paper trading. El patrimonio cuenta lo invertido '
            'a su costo hasta que llegue la valoración con precios.',
      ),
    ];
  }
}

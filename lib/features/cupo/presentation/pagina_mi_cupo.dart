/// Pantalla Mi cupo (HU-019, RN-20): cuánto tengo y cuánto puedo invertir.
///
/// Solo muestra lo que `mi_cupo()` entrega: cada cifra la calcula el servidor.
/// Se actualiza sola con el evento `cupo` (gestor de tiempo real) y al
/// deslizar hacia abajo. Debajo del resumen van las posiciones con su protección
/// (HU-091); el historial llega con HU-093.
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
import 'posiciones_provider.dart';
import 'tarjeta_de_posicion.dart';

/// Ancho máximo del contenido en ventanas anchas.
const double anchoMaximoDeMiCupo = 720;

class PaginaMiCupo extends ConsumerWidget {
  const PaginaMiCupo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(miCupoProvider);

    Future<void> recargar() async {
      ref.invalidate(miCupoProvider);
      ref.invalidate(posicionesDeMiCupoProvider);
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
                AsyncData(:final value) => _contenido(
                  context,
                  ref,
                  value.first,
                ),
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

  List<Widget> _contenido(BuildContext context, WidgetRef ref, MiCupo cupo) {
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
      // Con texto grande el valor baja a su línea en vez de desbordar.
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Espacio.x3,
          runSpacing: Espacio.x1,
          children: [
            Text(etiqueta, style: suave),
            valor,
          ],
        ),
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
      const SizedBox(height: Espacio.x6),
      Semantics(
        header: true,
        child: Text('Posiciones', style: textos.titleLarge),
      ),
      const SizedBox(height: Espacio.x3),
      ..._posiciones(context, ref),
      const SizedBox(height: Espacio.x4),
      const AvisoEnLinea(
        tipo: TipoAviso.informacion,
        mensaje:
            'Cifras en USD de paper trading. El patrimonio cuenta lo invertido '
            'a su costo hasta que llegue la valoración con precios.',
      ),
    ];
  }

  /// Las posiciones abiertas con su protección (HU-091, FR-198 y FR-199).
  List<Widget> _posiciones(BuildContext context, WidgetRef ref) {
    final posiciones = ref.watch(posicionesValoradasProvider);
    return switch (posiciones) {
      AsyncData(:final value) when value.isEmpty => const [
        Tarjeta(
          child: EstadoVacio(
            titulo: 'Aún no tienes posiciones',
            mensaje:
                'Cuando una de tus compras se llene, aparece aquí con su '
                'resultado en vivo y su protección.',
          ),
        ),
      ],
      AsyncData(:final value) => [
        for (final posicion in value) ...[
          TarjetaDePosicion(posicion: posicion),
          const SizedBox(height: Espacio.x3),
        ],
      ],
      AsyncError(:final error) => [
        EstadoDeError(
          error: error,
          alReintentar: () => ref.invalidate(posicionesDeMiCupoProvider),
        ),
      ],
      _ => const [Tarjeta(child: EstadoCargando(lineas: 3))],
    };
  }
}

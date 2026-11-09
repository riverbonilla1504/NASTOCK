/// Tarjeta de una posición de mi cupo con su protección (HU-091, FR-198 y
/// FR-199): símbolo, cantidad, costo promedio, último precio con su antigüedad,
/// valor, resultado no realizado, y el stop y el objetivo de su protección.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../core/realtime/reloj.dart';
import '../../../shared/widgets/chip_de_estado.dart';
import '../../../shared/widgets/cifras.dart';
import '../../../shared/widgets/tarjeta.dart';
import '../domain/posicion.dart';

/// La cantidad sin ceros de sobra: `10` y no `10.000000000`.
String formatearCantidad(double cantidad) {
  if (cantidad == cantidad.roundToDouble()) return cantidad.toInt().toString();
  var texto = cantidad.toStringAsFixed(9);
  texto = texto.replaceFirst(RegExp(r'0+$'), '');
  return texto.replaceAll('.', ',');
}

class TarjetaDePosicion extends ConsumerWidget {
  const TarjetaDePosicion({required this.posicion, super.key});

  final PosicionValorada posicion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    final suave = textos.bodyMedium!.copyWith(color: c.tintaSuave);
    final p = posicion.posicion;
    final proteccion = p.proteccion;

    Widget fila(String etiqueta, Widget valor) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacio.x1),
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

    final antiguedad = posicion.momentoDelPrecio == null
        ? null
        : ref
              .read(relojProvider)
              .ahora()
              .difference(posicion.momentoDelPrecio!);

    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(p.simbolo, style: textos.titleMedium)),
              Text(formatearCantidad(p.cantidad), style: textos.titleMedium),
              const SizedBox(width: Espacio.x1),
              Text('acciones', style: suave),
            ],
          ),
          const SizedBox(height: Espacio.x2),
          fila('Costo promedio', CifraUsd(p.costoPromedio)),
          fila(
            'Último precio',
            posicion.precio == null
                ? Text('Sin precio aún', style: suave)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CifraUsd(posicion.precio!),
                      if (antiguedad != null) AntiguedadDelDato(antiguedad),
                    ],
                  ),
          ),
          fila(
            'Valor',
            posicion.valor == null
                ? Text('—', style: suave)
                : CifraUsd(posicion.valor!),
          ),
          fila(
            'Resultado no realizado',
            posicion.noRealizado == null
                ? Text('—', style: suave)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CifraUsd(posicion.noRealizado!),
                      if (posicion.noRealizadoPct != null)
                        Variacion(posicion.noRealizadoPct!),
                    ],
                  ),
          ),
          const SizedBox(height: Espacio.x2),
          const Divider(height: 1),
          const SizedBox(height: Espacio.x3),
          if (proteccion == null)
            Text('Sin protección', style: suave)
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Protección ${proteccion.etiquetaDelTipo.toLowerCase()}',
                    style: textos.titleSmall,
                  ),
                ),
                proteccion.estado == 'activa'
                    ? ChipDeEstado.enVivo(
                        etiqueta: proteccion.etiquetaDelEstado.toUpperCase(),
                      )
                    : ChipDeEstado.pendiente(
                        etiqueta: proteccion.etiquetaDelEstado.toUpperCase(),
                      ),
              ],
            ),
            fila('Stop', CifraUsd(proteccion.stopPrecio)),
            fila(
              'Objetivo',
              proteccion.objetivoPrecio == null
                  ? Text('Sin objetivo', style: suave)
                  : CifraUsd(proteccion.objetivoPrecio!),
            ),
          ],
        ],
      ),
    );
  }
}

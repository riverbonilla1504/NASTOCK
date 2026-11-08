/// Cotización de un símbolo: precio en USD, variación, antigüedad y, si hay
/// datos, la curva del día en morado. Con el precio desactualizado la cifra se
/// subraya punteada (08 §9.4); deshabilitar la compra es de quien la usa.
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'cifras.dart';
import 'grafica_de_linea.dart';
import 'tarjeta.dart';

/// Fila compacta de cotización para listas densas: símbolo y nombre a la
/// izquierda; precio, variación y antigüedad a la derecha.
class FilaDeCotizacion extends StatelessWidget {
  const FilaDeCotizacion({
    required this.simbolo,
    required this.nombre,
    required this.precio,
    required this.variacion,
    required this.antiguedad,
    this.factor,
    this.desactualizado = false,
    this.alTocar,
    super.key,
  });

  final String simbolo;
  final String nombre;

  /// Apalancamiento del instrumento (p. ej. `×2`). Va en un texto propio que
  /// nunca se corta: es un dato, no un adorno.
  final String? factor;
  final num precio;
  final num variacion;
  final Duration antiguedad;
  final bool desactualizado;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return InkWell(
      onTap: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Espacio.x3,
            vertical: Espacio.x2,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SimboloConFactor(
                      simbolo: simbolo,
                      factor: factor,
                      estilo: textos.titleMedium!,
                    ),
                    Text(
                      nombre,
                      style: textos.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Espacio.x3),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CifraUsd(precio, desactualizada: desactualizado),
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: Espacio.x2,
                      children: [
                        Variacion(variacion),
                        AntiguedadDelDato(
                          antiguedad,
                          desactualizado: desactualizado,
                          compacta: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TarjetaDeCotizacion extends StatelessWidget {
  const TarjetaDeCotizacion({
    required this.simbolo,
    required this.nombre,
    required this.precio,
    required this.variacion,
    required this.antiguedad,
    this.factor,
    this.desactualizado = false,
    this.curva,
    this.ahora,
    this.etiquetasDelEje,
    this.acciones = const [],
    super.key,
  });

  final String simbolo;
  final String nombre;
  final num precio;

  /// Apalancamiento del instrumento (p. ej. `×2`), en un texto que no se corta.
  final String? factor;

  /// Variación porcentual del día.
  final num variacion;
  final Duration antiguedad;
  final bool desactualizado;

  /// Precios del día en orden; se dibujan hasta [ahora].
  final List<double>? curva;

  /// Posición de "ahora" en la jornada, de 0 a 1.
  final double? ahora;

  /// Rótulos bajo la curva, p. ej. `['09:30', 'ahora 11:46', '16:00']`.
  final List<String>? etiquetasDelEje;

  /// Botones de la tarjeta (p. ej. Comprar y Vender).
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SimboloConFactor(
                      simbolo: simbolo,
                      factor: factor,
                      estilo: textos.titleLarge!.copyWith(
                        fontFamily: Familias.texto,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      nombre,
                      style: textos.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Espacio.x3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CifraUsd(
                    precio,
                    tamano: TamanoCifra.grande,
                    desactualizada: desactualizado,
                  ),
                  const SizedBox(height: Espacio.x1),
                  Wrap(
                    spacing: Espacio.x2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Variacion(variacion),
                      AntiguedadDelDato(
                        antiguedad,
                        desactualizado: desactualizado,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (curva != null && curva!.isNotEmpty) ...[
            const SizedBox(height: Espacio.x3),
            GraficaDeLinea(
              serie: curva!,
              ahora: ahora,
              descripcion: 'Curva del día de $simbolo',
            ),
            if (etiquetasDelEje != null) ...[
              const SizedBox(height: Espacio.x1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final e in etiquetasDelEje!)
                    Text(
                      e,
                      style: textos.bodySmall!.copyWith(color: c.tintaSuave),
                    ),
                ],
              ),
            ],
          ],
          if (acciones.isNotEmpty) ...[
            const SizedBox(height: Espacio.x4),
            Wrap(
              spacing: Espacio.x2,
              runSpacing: Espacio.x2,
              children: acciones,
            ),
          ],
        ],
      ),
    );
  }
}

/// Símbolo con su factor de apalancamiento al lado, que nunca se corta.
class _SimboloConFactor extends StatelessWidget {
  const _SimboloConFactor({
    required this.simbolo,
    required this.factor,
    required this.estilo,
  });

  final String simbolo;
  final String? factor;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: simbolo),
          if (factor != null)
            TextSpan(
              text: '  $factor',
              style: estilo.copyWith(
                fontWeight: FontWeight.w600,
                color: c.tintaSuave,
                fontSize: (estilo.fontSize ?? 16) * 0.8,
              ),
            ),
        ],
      ),
      style: estilo,
      softWrap: false,
    );
  }
}

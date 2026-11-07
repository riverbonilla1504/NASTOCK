/// Cifras del sistema: dinero en USD, variación y antigüedad del dato.
///
/// El dinero siempre en USD con dos decimales (docs/README, FR-003). La
/// variación lleva flecha y signo además del color; la antigüedad lleva el
/// trazo de su estado (sólido reciente, punteado desactualizado, 08 §9.4).
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../core/formato/formato_dinero.dart';
import '../../core/formato/formato_porcentaje.dart';
import 'forma_de_linea.dart';

/// Tamaños de una cifra.
enum TamanoCifra { pequena, normal, grande }

/// Monto en USD con cifras tabulares.
class CifraUsd extends StatelessWidget {
  const CifraUsd(
    this.monto, {
    this.tamano = TamanoCifra.normal,
    this.desactualizada = false,
    super.key,
  });

  final num monto;
  final TamanoCifra tamano;

  /// Precio viejo: se subraya punteado y se atenúa (08 §9.4).
  final bool desactualizada;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    final base = switch (tamano) {
      TamanoCifra.pequena => textos.bodyMedium!.copyWith(
        fontWeight: FontWeight.w600,
      ),
      TamanoCifra.normal => textos.titleMedium!,
      TamanoCifra.grande => textos.displaySmall!,
    };
    final texto = formatearUsd(monto);
    return Semantics(
      label: desactualizada ? '$texto, precio desactualizado' : texto,
      excludeSemantics: true,
      child: Text(
        texto,
        style: desactualizada
            ? base.copyWith(
                color: c.tintaSuave,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: c.tinta,
                decorationThickness: 2,
              )
            : base,
      ),
    );
  }
}

/// Variación porcentual con flecha, signo y color de dirección.
class Variacion extends StatelessWidget {
  const Variacion(this.porcentaje, {super.key});

  final num porcentaje;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final texto = formatearPorcentaje(porcentaje);
    final sinCambio = texto.startsWith('0,00');
    final sube = !sinCambio && porcentaje > 0;
    final color = sinCambio ? c.tintaSuave : (sube ? c.alza : c.baja);
    final icono = sinCambio
        ? Icons.remove
        : (sube ? Icons.arrow_upward : Icons.arrow_downward);
    final lectura = sinCambio
        ? 'Sin cambio'
        : '${sube ? 'Sube' : 'Baja'} ${texto.substring(1)}';
    return Semantics(
      label: lectura,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Antigüedad de un dato con el trazo de su estado.
class AntiguedadDelDato extends StatelessWidget {
  const AntiguedadDelDato(
    this.antiguedad, {
    this.desactualizado = false,
    this.compacta = false,
    super.key,
  });

  final Duration antiguedad;

  /// Supera `mercado.max_antiguedad_cotizacion_seg` (08 §9.4).
  final bool desactualizado;

  /// Sin "hace" (para listas densas).
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final tiempo = formatearAntiguedad(antiguedad);
    final texto = desactualizado
        ? 'desactualizado · $tiempo'
        : (compacta ? tiempo : 'hace $tiempo');
    final estilo = Theme.of(context).textTheme.bodySmall!.copyWith(
      color: desactualizado ? c.tinta : c.tintaSuave,
      fontWeight: desactualizado ? FontWeight.w600 : FontWeight.w400,
    );
    return Semantics(
      label: desactualizado
          ? 'Dato desactualizado, hace $tiempo'
          : 'Actualizado hace $tiempo',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TrazoDeLinea(
            forma: desactualizado ? FormaDeLinea.punteada : FormaDeLinea.solida,
            color: desactualizado ? c.tinta : c.tintaSuave,
            ancho: 12,
          ),
          const SizedBox(width: Espacio.x1 + 2),
          Flexible(child: Text(texto, style: estilo)),
        ],
      ),
    );
  }
}

/// Tarjeta de gráfica con el estilo de Alpaca (D-69): título, valor grande en
/// monoespaciada con su cambio y la fecha, la gráfica de línea a todo el ancho
/// y el selector de rango 1D · 1M · 1Y · All.
///
/// Celular primero: el título y el refresco van arriba, el valor debajo, la
/// gráfica a todo el ancho y el selector bajo la gráfica, repartido en todo el
/// ancho con objetivos de 48 dp. Desde [anchoParaSelectorArriba] el selector
/// pasa a la derecha del título, como en el panel de Alpaca.
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../core/formato/formato_dinero.dart';
import 'cifras.dart';
import 'grafica_de_linea.dart';
import 'selector_de_rango.dart';
import 'tarjeta.dart';

/// Ancho de la tarjeta desde el cual el selector va junto al título.
const double anchoParaSelectorArriba = 520;

class TarjetaDeGrafica extends StatelessWidget {
  const TarjetaDeGrafica({
    required this.titulo,
    required this.serie,
    required this.descripcion,
    required this.rango,
    required this.alElegirRango,
    this.valor,
    this.cambio,
    this.fecha,
    this.referencia,
    this.ahora,
    this.alRefrescar,
    this.altoDeGrafica = 160,
    this.rejilla = 4,
    this.mostrarEjeY = true,
    this.formatoY = formatearCifraCorta,
    this.etiquetasX,
    super.key,
  });

  final String titulo;

  /// Valor grande en USD (`10000` → `USD 10.000,00`). Sin él, no se muestra.
  final num? valor;

  /// Cambio porcentual junto al valor, con flecha y signo.
  final num? cambio;

  /// Fecha y hora del dato, a la derecha del cambio y en monoespaciada.
  final String? fecha;

  final List<double> serie;
  final List<double>? referencia;
  final double? ahora;

  /// Lo que lee un lector de pantalla de la gráfica.
  final String descripcion;

  final RangoDeGrafica rango;
  final ValueChanged<RangoDeGrafica>? alElegirRango;

  /// Si existe, aparece el botón de refrescar junto al título.
  final VoidCallback? alRefrescar;

  final double altoDeGrafica;
  final int rejilla;
  final bool mostrarEjeY;
  final String Function(double valor) formatoY;
  final List<String>? etiquetasX;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Tarjeta(
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final ancha = restricciones.maxWidth >= anchoParaSelectorArriba;
          final selector = SelectorDeRango(
            rango: rango,
            alElegir: alElegirRango,
            expandido: !ancha,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(titulo, style: textos.titleMedium),
                    ),
                  ),
                  if (ancha) selector,
                  if (alRefrescar != null)
                    IconButton(
                      onPressed: alRefrescar,
                      tooltip: 'Actualizar',
                      constraints: const BoxConstraints(
                        minWidth: Espacio.objetivoTactil,
                        minHeight: Espacio.objetivoTactil,
                      ),
                      icon: Icon(Icons.refresh, size: 20, color: c.tintaSuave),
                    ),
                ],
              ),
              if (valor != null) ...[
                const SizedBox(height: Espacio.x2),
                // Las cifras grandes se achican antes que cortarse.
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CifraUsd(valor!, tamano: TamanoCifra.grande),
                  ),
                ),
              ],
              if (cambio != null || fecha != null) ...[
                const SizedBox(height: Espacio.x1),
                Row(
                  children: [
                    if (cambio != null) Variacion(cambio!),
                    const Spacer(),
                    if (fecha != null)
                      Flexible(
                        child: Text(
                          fecha!,
                          textAlign: TextAlign.right,
                          style: estiloDeCifra(
                            textos.bodySmall!.copyWith(color: c.tintaSuave),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Espacio.x4),
              GraficaDeLinea(
                serie: serie,
                referencia: referencia,
                ahora: ahora,
                alto: altoDeGrafica,
                rejilla: rejilla,
                mostrarEjeY: mostrarEjeY,
                formatoY: formatoY,
                etiquetasX: etiquetasX,
                descripcion: descripcion,
              ),
              if (!ancha) ...[const SizedBox(height: Espacio.x2), selector],
            ],
          );
        },
      ),
    );
  }
}

/// Detalle de una candidata (HU-048 CA-3, docs/07 §14): por qué ganó o por qué
/// no, qué la frena, cuánto aporta cada dimensión y las advertencias.
///
/// Sin contexto ni titulares: el corte de demo (D-59, D-70) no lee noticias.
library;

import 'package:flutter/material.dart';

import '../../../app/tema.dart';
import '../../../core/formato/formato_porcentaje.dart';
import '../../../shared/widgets/avisos.dart';
import '../../../shared/widgets/hoja_inferior.dart';
import '../domain/oportunidad.dart';
import 'pagina_oportunidades.dart';

Future<void> mostrarDetalleDeOportunidad(
  BuildContext context,
  Oportunidad oportunidad,
) {
  return mostrarHojaInferior<void>(
    context,
    constructor: (_) => DetalleDeOportunidad(oportunidad: oportunidad),
  );
}

class DetalleDeOportunidad extends StatelessWidget {
  const DetalleDeOportunidad({required this.oportunidad, super.key});

  final Oportunidad oportunidad;

  @override
  Widget build(BuildContext context) {
    final o = oportunidad;
    final textos = Theme.of(context).textTheme;
    final tenue = context.colores.tintaSuave;
    final abajo = MediaQuery.paddingOf(context).bottom + Espacio.x4;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Espacio.x4, Espacio.x6, Espacio.x4, abajo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(o.simbolo, style: textos.headlineSmall)),
              ChipDelResultado(resultado: o.resultado),
            ],
          ),
          Text(
            o.bolsillo.etiqueta,
            style: textos.bodySmall!.copyWith(color: tenue),
          ),
          const SizedBox(height: Espacio.x4),
          Row(
            children: [
              _Cifra(
                rotulo: 'Puntaje',
                valor: o.puntaje == null ? '—' : formatearPuntaje(o.puntaje!),
              ),
              const SizedBox(width: Espacio.x6),
              _Cifra(
                rotulo: 'Confianza de JEV',
                valor: o.confianza == null
                    ? '—'
                    : formatearConfianza(o.confianza!),
              ),
            ],
          ),
          if (o.explicacion.que.isNotEmpty) ...[
            const SizedBox(height: Espacio.x4),
            Text(o.explicacion.que, style: textos.bodyLarge),
          ],
          if (o.explicacion.porQue.isNotEmpty) ...[
            const SizedBox(height: Espacio.x5),
            Text('Por qué', style: textos.titleSmall),
            const SizedBox(height: Espacio.x2),
            for (final linea in o.explicacion.porQue) _Linea(texto: linea),
          ],
          if (o.explicacion.frena.isNotEmpty) ...[
            const SizedBox(height: Espacio.x5),
            Text('Qué la frena', style: textos.titleSmall),
            const SizedBox(height: Espacio.x2),
            for (final linea in o.explicacion.frena) _Linea(texto: linea),
          ],
          if (o.aportes.isNotEmpty) ...[
            const SizedBox(height: Espacio.x5),
            Text('Cómo se compone el puntaje', style: textos.titleSmall),
            const SizedBox(height: Espacio.x2),
            for (final a in o.aportes) _FilaDeAporte(aporte: a),
          ],
          if (o.rendimiento20d != null ||
              o.volatilidad20d != null ||
              o.rsi != null) ...[
            const SizedBox(height: Espacio.x5),
            Text('Datos del mercado', style: textos.titleSmall),
            const SizedBox(height: Espacio.x2),
            if (o.rendimiento20d != null)
              _Linea(
                texto:
                    'Rendimiento a 20 días: ${formatearPorcentaje(o.rendimiento20d! * 100)}',
              ),
            if (o.volatilidad20d != null)
              _Linea(
                texto:
                    'Volatilidad anual (20 días): ${(o.volatilidad20d! * 100).round()} %',
              ),
            if (o.rsi != null)
              _Linea(texto: 'RSI de 14 días: ${o.rsi!.round()}'),
          ],
          if (o.explicacion.advertencias.isNotEmpty) ...[
            const SizedBox(height: Espacio.x5),
            for (final a in o.explicacion.advertencias)
              Padding(
                padding: const EdgeInsets.only(bottom: Espacio.x2),
                child: AvisoEnLinea(tipo: TipoAviso.advertencia, mensaje: a),
              ),
          ],
          if (o.modeloJev != null) ...[
            const SizedBox(height: Espacio.x3),
            Text(
              'Modelo: ${o.modeloJev}',
              style: textos.bodySmall!.copyWith(color: tenue),
            ),
          ],
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: textos.labelMedium!.copyWith(
            color: context.colores.tintaSuave,
          ),
        ),
        Text(valor, style: textos.headlineSmall),
      ],
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacio.x1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Una dimensión del puntaje: nombre, barra de 0 a 1 y su aporte. Las neutrales
/// (sin contexto) se marcan como tales.
class _FilaDeAporte extends StatelessWidget {
  const _FilaDeAporte({required this.aporte});

  final AporteDeDimension aporte;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacio.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  aporte.neutral ? '${aporte.nombre} (neutro)' : aporte.nombre,
                  style: textos.bodySmall,
                ),
              ),
              Text(formatearPuntaje(aporte.aporte), style: textos.labelMedium),
            ],
          ),
          const SizedBox(height: Espacio.x1),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: aporte.valor.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: c.regla,
              color: aporte.neutral ? c.tintaTenue : c.morado,
            ),
          ),
        ],
      ),
    );
  }
}

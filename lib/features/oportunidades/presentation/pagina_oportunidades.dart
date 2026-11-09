/// Pantalla Oportunidades (HU-048, docs/07 §14, D-65, D-70): lo que la IA evalúa,
/// con su puntaje, su confianza y por qué.
///
/// Es una recomendación, no una orden: no hay botón para aprobarla. La persona
/// decide y, si quiere, crea una orden manual. La seguridad no está aquí: la RPC
/// `oportunidades()` solo entrega al Usuario el bolsillo de Usuarios.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../shared/widgets/avisos.dart';
import '../../../shared/widgets/barra_superior.dart';
import '../../../shared/widgets/chip_de_estado.dart';
import '../../../shared/widgets/estados.dart';
import '../../../shared/widgets/forma_de_linea.dart';
import '../../../shared/widgets/opciones_excluyentes.dart';
import '../../../shared/widgets/tarjeta.dart';
import '../domain/oportunidad.dart';
import 'detalle_de_oportunidad.dart';
import 'oportunidades_provider.dart';

/// Ancho máximo del contenido en ventanas anchas.
const double anchoMaximoDeOportunidades = 720;

/// Puntaje de 0 a 1 con coma decimal: `0,72`.
String formatearPuntaje(double puntaje) =>
    puntaje.toStringAsFixed(2).replaceAll('.', ',');

/// Confianza de 0 a 1 como porcentaje entero: `81 %`.
String formatearConfianza(double confianza) => '${(confianza * 100).round()} %';

class PaginaOportunidades extends ConsumerStatefulWidget {
  const PaginaOportunidades({super.key});

  @override
  ConsumerState<PaginaOportunidades> createState() =>
      _PaginaOportunidadesState();
}

class _PaginaOportunidadesState extends ConsumerState<PaginaOportunidades> {
  Timer? _refresco;
  BolsilloIa? _elegido;

  @override
  void initState() {
    super.initState();
    _refresco = Timer.periodic(intervaloDeRefresco, (_) {
      if (mounted) ref.invalidate(oportunidadesProvider);
    });
  }

  @override
  void dispose() {
    _refresco?.cancel();
    super.dispose();
  }

  Future<void> _recargar() async {
    ref.invalidate(oportunidadesProvider);
    await ref
        .read(oportunidadesProvider.future)
        .catchError((_) => <Oportunidad>[]);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(oportunidadesProvider);
    return Scaffold(
      appBar: const BarraSuperior(titulo: 'Oportunidades'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: anchoMaximoDeOportunidades,
          ),
          child: RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                Espacio.x4,
                Espacio.x4,
                Espacio.x4,
                Espacio.x8,
              ),
              children: [
                const AvisoEnLinea(
                  tipo: TipoAviso.informacion,
                  mensaje:
                      'La IA evalúa y recomienda; la decisión es tuya. '
                      'Demostración en paper trading, no es asesoría financiera.',
                ),
                const SizedBox(height: Espacio.x4),
                ...switch (estado) {
                  AsyncData(:final value) => _contenido(context, value),
                  AsyncError(:final error) => [
                    EstadoDeError(error: error, alReintentar: _recargar),
                  ],
                  _ => [const EstadoCargando(lineas: 4)],
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenido(BuildContext context, List<Oportunidad> todas) {
    if (todas.isEmpty) {
      return [
        const EstadoVacio(
          titulo: 'Aún no hay evaluaciones',
          mensaje:
              'La IA evalúa cada 15 minutos con el mercado abierto. '
              'Cuando termine su primer ciclo, sus candidatas aparecen aquí.',
        ),
      ];
    }
    final bolsillos = [
      for (final b in BolsilloIa.values)
        if (todas.any((o) => o.bolsillo == b)) b,
    ];
    final actual = bolsillos.contains(_elegido) ? _elegido! : bolsillos.first;
    final delBolsillo = [
      for (final o in todas)
        if (o.bolsillo == actual) o,
    ];
    final evaluadas = [
      for (final o in delBolsillo)
        if (o.resultado != ResultadoIa.excluida) o,
    ];
    final excluidas = [
      for (final o in delBolsillo)
        if (o.resultado == ResultadoIa.excluida) o,
    ];
    final hora = todas.first.terminadoEn;
    final textos = Theme.of(context).textTheme;
    final tenue = context.colores.tintaSuave;

    return [
      if (bolsillos.length > 1) ...[
        OpcionesExcluyentes<BolsilloIa>(
          etiqueta: 'Bolsillo',
          opciones: [
            for (final b in bolsillos)
              OpcionExcluyente(valor: b, etiqueta: b.etiqueta),
          ],
          valor: actual,
          alElegir: (b) => setState(() => _elegido = b),
        ),
        const SizedBox(height: Espacio.x4),
      ],
      if (hora != null) ...[
        Text(
          'Último ciclo: ${_hace(hora)}',
          style: textos.bodySmall!.copyWith(color: tenue),
        ),
        const SizedBox(height: Espacio.x3),
      ],
      if (evaluadas.isEmpty)
        const EstadoVacio(
          titulo: 'Sin candidatas',
          mensaje:
              'Este bolsillo no tiene candidatas evaluadas en el último ciclo.',
        ),
      for (final o in evaluadas) ...[
        TarjetaDeOportunidad(
          oportunidad: o,
          alTocar: () => mostrarDetalleDeOportunidad(context, o),
        ),
        const SizedBox(height: Espacio.x3),
      ],
      if (excluidas.isNotEmpty) ...[
        const SizedBox(height: Espacio.x2),
        Text('Excluidas por la calidad de sus datos', style: textos.titleSmall),
        const SizedBox(height: Espacio.x2),
        for (final o in excluidas)
          Padding(
            padding: const EdgeInsets.only(bottom: Espacio.x2),
            child: Text(
              o.explicacion.que.isEmpty ? o.simbolo : o.explicacion.que,
              style: textos.bodySmall!.copyWith(color: tenue),
            ),
          ),
      ],
    ];
  }

  String _hace(DateTime momento) {
    final d = DateTime.now().difference(momento);
    if (d.inMinutes < 1) return 'hace unos segundos';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    return 'hace ${d.inDays} d';
  }
}

/// Una candidata en la lista: símbolo, resultado, puntaje, confianza y la
/// primera línea de la explicación.
class TarjetaDeOportunidad extends StatelessWidget {
  const TarjetaDeOportunidad({
    required this.oportunidad,
    required this.alTocar,
    super.key,
  });

  final Oportunidad oportunidad;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final o = oportunidad;
    final textos = Theme.of(context).textTheme;
    final tenue = context.colores.tintaSuave;
    return Tarjeta(
      alTocar: alTocar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(o.simbolo, style: textos.titleMedium)),
              ChipDelResultado(resultado: o.resultado),
            ],
          ),
          const SizedBox(height: Espacio.x3),
          Row(
            children: [
              _Dato(
                rotulo: 'Puntaje',
                valor: o.puntaje == null ? '—' : formatearPuntaje(o.puntaje!),
              ),
              const SizedBox(width: Espacio.x6),
              _Dato(
                rotulo: 'Confianza',
                valor: o.confianza == null
                    ? '—'
                    : formatearConfianza(o.confianza!),
              ),
            ],
          ),
          if (o.explicacion.que.isNotEmpty) ...[
            const SizedBox(height: Espacio.x3),
            Text(
              o.explicacion.que,
              style: textos.bodyMedium!.copyWith(color: tenue),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class ChipDelResultado extends StatelessWidget {
  const ChipDelResultado({required this.resultado, super.key});

  final ResultadoIa resultado;

  @override
  Widget build(BuildContext context) => switch (resultado) {
    ResultadoIa.elegida => const ChipDeEstado(
      etiqueta: 'Recomendada',
      forma: FormaDeLinea.solida,
      destacado: true,
    ),
    ResultadoIa.elegibleNoElegida => const ChipDeEstado(
      etiqueta: 'Elegible',
      forma: FormaDeLinea.discontinua,
    ),
    ResultadoIa.noElegible => const ChipDeEstado(
      etiqueta: 'Sin recomendar',
      forma: FormaDeLinea.fina,
    ),
    ResultadoIa.excluida => const ChipDeEstado.desactualizado(
      etiqueta: 'Excluida',
    ),
  };
}

class _Dato extends StatelessWidget {
  const _Dato({required this.rotulo, required this.valor});

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
        Text(valor, style: textos.titleLarge),
      ],
    );
  }
}

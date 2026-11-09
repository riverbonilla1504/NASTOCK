/// Encabezado de la pantalla de mercado: el estado del mercado y la cuenta
/// regresiva al cierre (con el mercado abierto) o a la apertura (cerrado), en
/// hora de Bogotá (HU-030, CA-3, RN-42).
///
/// La cuenta se calcula con el reloj corregido con el servidor (docs/09 §1) y
/// se actualiza cada segundo. Al llegar a cero vuelve a pedir el estado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../core/formato/formato_fechas.dart';
import '../../../core/realtime/reloj.dart';
import '../../../shared/widgets/chip_de_estado.dart';
import '../../../shared/widgets/estados.dart';
import '../domain/mercado.dart';
import 'grafica_de_mercado.dart' show familiaMonoespaciada;
import 'mercado_provider.dart';

/// `2 d 03:12:10`, `03:12:10`, `12:10`: lo que falta, sin negativos.
String formatearCuentaRegresiva(Duration falta) {
  final total = falta.isNegative ? Duration.zero : falta;
  final dias = total.inDays;
  final horas = total.inHours.remainder(24);
  final minutos = total.inMinutes.remainder(60);
  final segundos = total.inSeconds.remainder(60);
  String dos(int n) => n.toString().padLeft(2, '0');
  final reloj = '${dos(horas)}:${dos(minutos)}:${dos(segundos)}';
  return dias > 0 ? '$dias d $reloj' : reloj;
}

/// El rótulo del estado: lo que el servidor calcula (docs/08 §6).
String etiquetaDelEstado(EstadoDelMercado estado) => switch (estado.estado) {
  'abierto' => 'Mercado abierto',
  'abierto_sin_compras' => 'Mercado abierto',
  'cierre_proximo' => 'Mercado por cerrar',
  'pre_apertura' => 'Por abrir',
  _ => 'Mercado cerrado',
};

class EncabezadoDelMercado extends ConsumerWidget {
  const EncabezadoDelMercado({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoMercadoProvider);
    return estado.when(
      data: (datos) => _Contenido(estado: datos),
      loading: () => const EstadoCargando(lineas: 1),
      error: (error, _) => EstadoDeError(
        error: error,
        alReintentar: () => ref.invalidate(estadoMercadoProvider),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.estado});

  final EstadoDelMercado estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El tic de cada segundo solo corre con el estado a la vista.
    ref.watch(segundoProvider);
    final reloj = ref.watch(relojProvider);
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    final objetivo = estado.objetivo;
    final falta = objetivo == null ? null : reloj.faltaPara(objetivo);

    // Al llegar a cero el estado cambia (abre, cierra): se vuelve a pedir una
    // sola vez, no en cada tic.
    if (falta != null && falta <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) ref.invalidate(estadoMercadoProvider);
      });
    }

    final etiqueta = estado.abierto ? 'Cierra en' : 'Abre en';
    final cuenta = falta == null ? '--:--:--' : formatearCuentaRegresiva(falta);
    final rotuloEstado = etiquetaDelEstado(estado);
    return Semantics(
      container: true,
      label: '$rotuloEstado. $etiqueta $cuenta',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          estado.abierto
              ? ChipDeEstado.enVivo(etiqueta: rotuloEstado)
              : ChipDeEstado.deshabilitado(etiqueta: rotuloEstado),
          const SizedBox(width: Espacio.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$etiqueta ',
                        style: textos.bodySmall!.copyWith(color: c.tintaSuave),
                      ),
                      TextSpan(
                        text: cuenta,
                        style: textos.titleMedium!.copyWith(
                          fontFamily: familiaMonoespaciada,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.end,
                ),
                if (objetivo != null)
                  Text(
                    '${formatearFechaHora(objetivo)} · hora de Bogotá',
                    style: textos.bodySmall!.copyWith(
                      color: c.tintaSuave,
                      fontFamily: familiaMonoespaciada,
                    ),
                    textAlign: TextAlign.end,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de aportes con su estado y la acción de anular (HU-099, PM-40).
///
/// Cada fila dice el monto, la referencia, quién lo registró y cuándo, y el
/// estado en un chip cuya forma de línea lo distingue sin depender del color.
/// Solo un aporte registrado ofrece «Anular», y pide el motivo (RN-10). La
/// lista se actualiza sola con el evento `capital`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tema.dart';
import '../../../../core/errores/traduccion_de_errores.dart';
import '../../../../core/formato/formato_dinero.dart';
import '../../../../core/formato/formato_fechas.dart';
import '../../../../shared/widgets/avisos.dart';
import '../../../../shared/widgets/botones.dart';
import '../../../../shared/widgets/campo.dart';
import '../../../../shared/widgets/chip_de_estado.dart';
import '../../../../shared/widgets/estados.dart';
import '../../../../shared/widgets/forma_de_linea.dart';
import '../../../../shared/widgets/tarjeta.dart';
import '../domain/movimiento_de_capital.dart';
import 'capital_provider.dart';

/// Nombre del estado como lo lee una persona.
String etiquetaDeEstadoDeAporte(EstadoMovCapital estado) => switch (estado) {
  EstadoMovCapital.registrado => 'Registrado',
  EstadoMovCapital.confirmado => 'Confirmado',
  EstadoMovCapital.anulado => 'Anulado',
};

class ListaDeAportes extends ConsumerStatefulWidget {
  const ListaDeAportes({super.key});

  static const Key claveDelVacio = Key('aportes-vacio');
  static const Key claveDelError = Key('aportes-error');
  static const Key claveDelMotivo = Key('aporte-motivo');

  @override
  ConsumerState<ListaDeAportes> createState() => _ListaDeAportesState();
}

class _ListaDeAportesState extends ConsumerState<ListaDeAportes> {
  /// Aportes cuya anulación se está enviando.
  final Set<String> _anulando = {};

  Future<void> _anular(MovimientoDeCapital aporte) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoDeAnulacion(monto: aporte.monto),
    );
    if (motivo == null || !mounted) return;

    setState(() => _anulando.add(aporte.id));
    String mensaje;
    try {
      await ref
          .read(aportesProvider.notifier)
          .anular(id: aporte.id, motivo: motivo);
      mensaje = 'Aporte anulado.';
    } catch (error) {
      mensaje = traducirError(error);
    }
    if (!mounted) return;
    setState(() => _anulando.remove(aporte.id));
    mostrarAvisoTemporal(context, mensaje);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(aportesProvider);
    final textos = Theme.of(context).textTheme;
    final lista = estado.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Aportes', style: textos.titleLarge),
              ),
            ),
            BotonTexto(
              texto: 'Actualizar',
              icono: Icons.refresh,
              alPresionar: estado.isLoading
                  ? null
                  : () => ref.read(aportesProvider.notifier).recargar(),
            ),
          ],
        ),
        const SizedBox(height: Espacio.x2),
        if (lista == null && estado.hasError)
          Padding(
            key: ListaDeAportes.claveDelError,
            padding: const EdgeInsets.only(top: Espacio.x2),
            child: EstadoDeError(
              error: estado.error,
              alReintentar: () => ref.read(aportesProvider.notifier).recargar(),
            ),
          )
        else if (lista == null)
          const Tarjeta(child: EstadoCargando(lineas: 4))
        else ...[
          if (estado.hasError) ...[
            AvisoEnLinea.deError(
              estado.error,
              key: ListaDeAportes.claveDelError,
              accion: 'Reintentar',
              alAccionar: () => ref.read(aportesProvider.notifier).recargar(),
            ),
            const SizedBox(height: Espacio.x3),
          ],
          if (lista.isEmpty)
            const Tarjeta(
              child: EstadoVacio(
                key: ListaDeAportes.claveDelVacio,
                titulo: 'Aún no hay aportes',
                mensaje:
                    'Registra el primer aporte para que el fondo tenga '
                    'capital.',
              ),
            )
          else
            Tarjeta(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < lista.length; i++) ...[
                    if (i > 0) const Divider(),
                    _Fila(
                      aporte: lista[i],
                      anulando: _anulando.contains(lista[i].id),
                      alAnular: () => _anular(lista[i]),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.aporte,
    required this.anulando,
    required this.alAnular,
  });

  final MovimientoDeCapital aporte;
  final bool anulando;
  final VoidCallback alAnular;

  String _detalle() {
    final partes = <String>[
      if (aporte.referencia != null) 'Ref. ${aporte.referencia}',
      'Registrado ${formatearFechaHora(aporte.registradoEn)}'
          '${aporte.registradoPor == null ? '' : ' por ${aporte.registradoPor}'}',
      switch (aporte.estado) {
        EstadoMovCapital.confirmado when aporte.confirmadoEn != null =>
          'Confirmado ${formatearFechaHora(aporte.confirmadoEn!)}',
        EstadoMovCapital.anulado when aporte.anuladoEn != null =>
          'Anulado ${formatearFechaHora(aporte.anuladoEn!)}',
        _ => '',
      },
    ];
    return partes.where((p) => p.isNotEmpty).join(' · ');
  }

  Widget _chip() {
    final etiqueta = etiquetaDeEstadoDeAporte(aporte.estado);
    return switch (aporte.estado) {
      EstadoMovCapital.registrado => ChipDeEstado.pendiente(etiqueta: etiqueta),
      EstadoMovCapital.confirmado => ChipDeEstado(
        etiqueta: etiqueta,
        forma: FormaDeLinea.solida,
      ),
      EstadoMovCapital.anulado => ChipDeEstado.deshabilitado(
        etiqueta: etiqueta,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Espacio.x4,
        vertical: Espacio.x3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: Espacio.x1),
                  child: Text(
                    formatearUsd(aporte.monto),
                    style: textos.titleMedium,
                  ),
                ),
              ),
              const SizedBox(width: Espacio.x3),
              _chip(),
            ],
          ),
          const SizedBox(height: Espacio.x1),
          Text(
            _detalle(),
            style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
          ),
          if (aporte.nota != null)
            Text(
              aporte.nota!,
              style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
            ),
          if (aporte.motivoAnulacion != null)
            Text(
              'Motivo: ${aporte.motivoAnulacion}',
              style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
            ),
          if (aporte.sePuedeAnular) ...[
            const SizedBox(height: Espacio.x1),
            Semantics(
              container: true,
              button: true,
              label: 'Anular el aporte de ${formatearUsd(aporte.monto)}',
              excludeSemantics: true,
              onTap: anulando ? null : alAnular,
              child: BotonTexto(
                texto: anulando ? textoProcesando : 'Anular',
                icono: anulando ? null : Icons.block,
                alPresionar: anulando ? null : alAnular,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pide el motivo de la anulación (RN-10). Devuelve el motivo o `null`.
class _DialogoDeAnulacion extends StatefulWidget {
  const _DialogoDeAnulacion({required this.monto});

  final double monto;

  @override
  State<_DialogoDeAnulacion> createState() => _DialogoDeAnulacionState();
}

class _DialogoDeAnulacionState extends State<_DialogoDeAnulacion> {
  final _motivo = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _confirmar() {
    final texto = _motivo.text.trim();
    if (texto.isEmpty) {
      setState(() => _error = 'Escribe el motivo de la anulación.');
      return;
    }
    Navigator.of(context).pop(texto);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('¿Anular este aporte?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'El aporte de ${formatearUsd(widget.monto)} no se confirmará. '
            'Queda en la bitácora.',
          ),
          const SizedBox(height: Espacio.x3),
          Campo(
            key: ListaDeAportes.claveDelMotivo,
            etiqueta: 'Motivo',
            controlador: _motivo,
            error: _error,
            alCambiar: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ],
      ),
      actions: [
        BotonSecundario(
          texto: 'Cancelar',
          alPresionar: () => Navigator.of(context).pop(),
        ),
        BotonPrimario(texto: 'Anular aporte', alPresionar: _confirmar),
      ],
    );
  }
}

/// Los dos interruptores del fondo (HU-101, PM-56 y PM-57): su estado, el
/// motivo, el autor y la hora de la pausa, y las acciones de encender y apagar
/// con confirmación. Sin capital el fondo no se enciende (`FONDO_SIN_CAPITAL`,
/// CB-80); lo decide la base de datos y la pantalla muestra su mensaje.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tema.dart';
import '../../../../core/formato/formato_fechas.dart';
import '../../../../shared/widgets/avisos.dart';
import '../../../../shared/widgets/botones.dart';
import '../../../../shared/widgets/campo.dart';
import '../../../../shared/widgets/chip_de_estado.dart';
import '../../../../shared/widgets/estados.dart';
import '../../../../shared/widgets/forma_de_linea.dart';
import '../../../../shared/widgets/hoja_inferior.dart';
import '../../../../shared/widgets/tarjeta.dart';
import '../domain/parametro.dart';
import 'parametros_provider.dart';

/// Clave de la tarjeta, del botón y del campo de un interruptor, para las pruebas.
Key claveDeInterruptor(Interruptor i) => Key('interruptor-${i.clave}');
Key claveDeAccionDeInterruptor(Interruptor i) =>
    Key('interruptor-accion-${i.clave}');
const Key claveDelMotivoDelFreno = Key('freno-motivo');
const Key claveDeConfirmarInterruptor = Key('interruptor-confirmar');

class PanelDeInterruptores extends ConsumerWidget {
  const PanelDeInterruptores({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(interruptoresProvider);
    return switch (estado) {
      AsyncData(:final value) => Column(
        children: [
          for (final i in Interruptor.values) ...[
            _TarjetaDeInterruptor(interruptor: i, estado: value),
            const SizedBox(height: Espacio.x3),
          ],
        ],
      ),
      AsyncError(:final error) => EstadoDeError(
        error: error,
        alReintentar: () => ref.invalidate(interruptoresProvider),
      ),
      _ => const EstadoCargando(lineas: 3),
    };
  }
}

class _TarjetaDeInterruptor extends StatelessWidget {
  const _TarjetaDeInterruptor({
    required this.interruptor,
    required this.estado,
  });

  final Interruptor interruptor;
  final Interruptores estado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final suave = textos.bodyMedium!.copyWith(
      color: context.colores.tintaSuave,
    );
    final encendido = estado.estaEncendido(interruptor);
    // El motivo de la pausa es del último interruptor apagado: solo se
    // muestra en uno que está apagado.
    final conPausa = !encendido && estado.motivoPausa != null;
    return Tarjeta(
      key: claveDeInterruptor(interruptor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(interruptor.titulo, style: textos.titleMedium),
              ),
              ChipDeEstado(
                etiqueta: encendido ? 'Encendido' : 'Apagado',
                forma: encendido ? FormaDeLinea.solida : FormaDeLinea.punteada,
                destacado: encendido,
              ),
            ],
          ),
          const SizedBox(height: Espacio.x1),
          Text(interruptor.descripcion, style: suave),
          if (conPausa) ...[
            const SizedBox(height: Espacio.x3),
            Text('Motivo de la pausa: ${estado.motivoPausa}'),
            if (estado.pausadoPor != null || estado.pausadoEn != null)
              Text(
                [
                  if (estado.pausadoPor != null) 'Por ${estado.pausadoPor}',
                  if (estado.pausadoEn != null)
                    formatearFechaHora(estado.pausadoEn!),
                ].join(' · '),
                style: suave,
              ),
          ],
          const SizedBox(height: Espacio.x3),
          encendido
              ? BotonSecundario(
                  key: claveDeAccionDeInterruptor(interruptor),
                  texto: 'Apagar',
                  alPresionar: () => mostrarHojaInferior<void>(
                    context,
                    constructor: (_) => _HojaDelFreno(interruptor: interruptor),
                  ),
                )
              : BotonPrimario(
                  key: claveDeAccionDeInterruptor(interruptor),
                  texto: 'Encender',
                  alPresionar: () => mostrarHojaInferior<void>(
                    context,
                    constructor: (_) =>
                        _HojaDeReanudar(interruptor: interruptor),
                  ),
                ),
        ],
      ),
    );
  }
}

/// Confirma encender un interruptor (PM-57).
class _HojaDeReanudar extends ConsumerStatefulWidget {
  const _HojaDeReanudar({required this.interruptor});

  final Interruptor interruptor;

  @override
  ConsumerState<_HojaDeReanudar> createState() => _HojaDeReanudarState();
}

class _HojaDeReanudarState extends ConsumerState<_HojaDeReanudar> {
  Object? _error;
  bool _enviando = false;

  Future<void> _confirmar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref
          .read(interruptoresProvider.notifier)
          .reanudar(widget.interruptor);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Espacio.x4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Encender ${widget.interruptor.titulo}',
            style: textos.titleLarge,
          ),
          const SizedBox(height: Espacio.x1),
          Text(
            widget.interruptor.descripcion,
            style: textos.bodyMedium!.copyWith(
              color: context.colores.tintaSuave,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: Espacio.x3),
            AvisoEnLinea.deError(_error),
          ],
          const SizedBox(height: Espacio.x4),
          BotonPrimario(
            key: claveDeConfirmarInterruptor,
            texto: 'Encender',
            enviando: _enviando,
            alPresionar: _confirmar,
          ),
        ],
      ),
    );
  }
}

/// Pide el motivo y confirma apagar un interruptor (PM-56).
class _HojaDelFreno extends ConsumerStatefulWidget {
  const _HojaDelFreno({required this.interruptor});

  final Interruptor interruptor;

  @override
  ConsumerState<_HojaDelFreno> createState() => _HojaDelFrenoState();
}

class _HojaDelFrenoState extends ConsumerState<_HojaDelFreno> {
  final _motivo = TextEditingController();
  String? _errorDelMotivo;
  Object? _error;
  bool _enviando = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final motivo = _motivo.text.trim();
    if (motivo.isEmpty) {
      setState(() => _errorDelMotivo = 'Escribe por qué lo apagas.');
      return;
    }
    setState(() {
      _errorDelMotivo = null;
      _enviando = true;
      _error = null;
    });
    try {
      await ref
          .read(interruptoresProvider.notifier)
          .frenar(widget.interruptor, motivo);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Espacio.x4,
        Espacio.x4,
        Espacio.x4,
        Espacio.x4 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apagar ${widget.interruptor.titulo}', style: textos.titleLarge),
          const SizedBox(height: Espacio.x3),
          Campo(
            key: claveDelMotivoDelFreno,
            etiqueta: 'Motivo',
            controlador: _motivo,
            error: _errorDelMotivo,
          ),
          if (_error != null) ...[
            const SizedBox(height: Espacio.x3),
            AvisoEnLinea.deError(_error),
          ],
          const SizedBox(height: Espacio.x4),
          BotonPrimario(
            key: claveDeConfirmarInterruptor,
            texto: 'Apagar',
            enviando: _enviando,
            alPresionar: _confirmar,
          ),
        ],
      ),
    );
  }
}

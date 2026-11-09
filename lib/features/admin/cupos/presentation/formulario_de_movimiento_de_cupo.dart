/// Formulario para asignar o reducir el cupo de una persona (HU-100, RN-16 y
/// RN-17). Pide el monto, valida lo básico y abre la confirmación común (sin
/// biometría, D-61); la RPC decide si el movimiento procede y, si no, el
/// diálogo muestra su error (`FONDOS_INSUFICIENTES`, `CUPO_SUPERA_MAXIMO`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tema.dart';
import '../../../../shared/widgets/botones.dart';
import '../../../../shared/widgets/campo.dart';
import '../../../../shared/widgets/cifras.dart';
import '../../../../shared/widgets/dialogo_de_confirmacion.dart';
import '../data/cupos_repositorio.dart';
import '../domain/subcuenta_de_cupo.dart';

enum AccionDeCupo { asignar, reducir }

/// Un monto en USD con hasta dos decimales, con punto o coma decimal.
final RegExp _formaDeMonto = RegExp(r'^\d+([.,]\d{1,2})?$');

class FormularioDeMovimientoDeCupo extends ConsumerStatefulWidget {
  const FormularioDeMovimientoDeCupo({
    required this.cupo,
    required this.accion,
    required this.disponible,
    super.key,
  });

  final SubcuentaDeCupo cupo;
  final AccionDeCupo accion;

  /// Lo que se puede mover: el disponible de la bolsa común al asignar, el del
  /// cupo al reducir. Es una guía: la base de datos decide.
  final double disponible;

  static const Key claveDelMonto = Key('cupo-monto');
  static const Key claveDelBoton = Key('cupo-continuar');

  @override
  ConsumerState<FormularioDeMovimientoDeCupo> createState() =>
      _FormularioDeMovimientoDeCupoState();
}

class _FormularioDeMovimientoDeCupoState
    extends ConsumerState<FormularioDeMovimientoDeCupo> {
  final _monto = TextEditingController();
  String? _error;

  bool get _asigna => widget.accion == AccionDeCupo.asignar;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final texto = _monto.text.trim();
    final monto = _formaDeMonto.hasMatch(texto)
        ? double.parse(texto.replaceAll(',', '.'))
        : null;
    if (monto == null || monto <= 0) {
      setState(
        () => _error = 'Escribe un monto mayor que cero, como 250 o 250,50.',
      );
      return;
    }
    setState(() => _error = null);

    final cupo = widget.cupo;
    final titular = cupo.titular ?? cupo.correo ?? 'el cupo';
    final resultado = await confirmarAccion(
      context,
      titulo: _asigna ? 'Asignar cupo' : 'Reducir cupo',
      rotuloDelSimbolo: 'Cupo',
      simbolo: titular,
      monto: monto,
      textoConfirmar: _asigna ? 'Asignar' : 'Reducir',
      detalle: _asigna
          ? 'Pasa de la bolsa común al cupo de $titular.'
          : 'Pasa del cupo de $titular a la bolsa común.',
      alConfirmar: () {
        final repo = ref.read(cuposRepositorioProvider);
        final usuario = cupo.usuarioId!;
        return _asigna
            ? repo.asignar(usuario, monto)
            : repo.reducir(usuario, monto);
      },
    );
    if (resultado == ResultadoDeConfirmacion.hecho && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final suave = textos.bodyMedium!.copyWith(
      color: context.colores.tintaSuave,
    );
    final cupo = widget.cupo;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Espacio.x4,
        Espacio.x6,
        Espacio.x4,
        Espacio.x4 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _asigna ? 'Asignar al cupo' : 'Reducir el cupo',
            style: textos.titleLarge,
          ),
          const SizedBox(height: Espacio.x1),
          Text(cupo.titular ?? cupo.correo ?? '', style: suave),
          const SizedBox(height: Espacio.x3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _asigna
                      ? 'Disponible en la bolsa común'
                      : 'Disponible del cupo',
                  style: suave,
                ),
              ),
              const SizedBox(width: Espacio.x3),
              CifraUsd(widget.disponible),
            ],
          ),
          const SizedBox(height: Espacio.x4),
          Campo(
            key: FormularioDeMovimientoDeCupo.claveDelMonto,
            etiqueta: 'Monto en USD',
            controlador: _monto,
            teclado: const TextInputType.numberWithOptions(decimal: true),
            pista: '250,00',
            error: _error,
          ),
          const SizedBox(height: Espacio.x4),
          BotonPrimario(
            key: FormularioDeMovimientoDeCupo.claveDelBoton,
            texto: 'Continuar',
            alPresionar: _continuar,
          ),
        ],
      ),
    );
  }
}

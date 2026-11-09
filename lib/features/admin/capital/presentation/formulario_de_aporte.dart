/// Formulario para registrar un aporte: monto, referencia y nota (HU-099,
/// PM-40). Registrar no mueve el libro: el aporte queda `registrado` hasta que
/// la conciliación lo confirma contra la cuenta paper (RN-07). Antes de enviar
/// se pide la confirmación con el componente común (D-61).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tema.dart';
import '../../../../shared/widgets/avisos.dart';
import '../../../../shared/widgets/botones.dart';
import '../../../../shared/widgets/campo.dart';
import '../../../../shared/widgets/dialogo_de_confirmacion.dart';
import 'capital_provider.dart';

/// Texto del botón que abre la confirmación del aporte.
const String textoRegistrarAporte = 'Registrar aporte';

/// Un monto en USD con hasta dos decimales, con punto o coma decimal.
final RegExp _formaDeMonto = RegExp(r'^\d+([.,]\d{1,2})?$');

class FormularioDeAporte extends ConsumerStatefulWidget {
  const FormularioDeAporte({super.key});

  static const Key claveDelMonto = Key('aporte-monto');
  static const Key claveDeLaReferencia = Key('aporte-referencia');
  static const Key claveDeLaNota = Key('aporte-nota');
  static const Key claveDelAvisoDeRegistrado = Key('aporte-registrado');

  @override
  ConsumerState<FormularioDeAporte> createState() => _FormularioDeAporteState();
}

class _FormularioDeAporteState extends ConsumerState<FormularioDeAporte> {
  final _monto = TextEditingController();
  final _referencia = TextEditingController();
  final _nota = TextEditingController();
  String? _errorDelMonto;
  double? _registrado;

  @override
  void dispose() {
    _monto.dispose();
    _referencia.dispose();
    _nota.dispose();
    super.dispose();
  }

  /// Valida lo que la base también valida. Devuelve el monto si está bien.
  double? _validar() {
    final texto = _monto.text.trim();
    String? error;
    double? monto;
    if (!_formaDeMonto.hasMatch(texto)) {
      error = 'Escribe un monto en USD, como 10000 o 10000,50.';
    } else {
      monto = double.parse(texto.replaceAll(',', '.'));
      if (monto <= 0) {
        error = 'El monto debe ser mayor que cero.';
        monto = null;
      }
    }
    setState(() => _errorDelMonto = error);
    return monto;
  }

  Future<void> _registrar() async {
    final monto = _validar();
    if (monto == null) return;
    final referencia = _referencia.text.trim();
    final nota = _nota.text.trim();

    final resultado = await confirmarAccion(
      context,
      titulo: '¿Registrar este aporte?',
      detalle:
          'El aporte queda registrado y el sistema lo confirma cuando la '
          'cuenta paper de Alpaca tenga ese efectivo.',
      simbolo: 'USD',
      monto: monto,
      textoConfirmar: textoRegistrarAporte,
      alConfirmar: () async {
        await ref
            .read(aportesProvider.notifier)
            .registrar(
              monto: monto,
              referencia: referencia.isEmpty ? null : referencia,
              nota: nota.isEmpty ? null : nota,
            );
      },
    );
    if (resultado != ResultadoDeConfirmacion.hecho || !mounted) return;
    _monto.clear();
    _referencia.clear();
    _nota.clear();
    setState(() => _registrado = monto);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text('Registrar un aporte', style: textos.titleLarge),
        ),
        const SizedBox(height: Espacio.x3),
        const AvisoEnLinea(
          tipo: TipoAviso.informacion,
          mensaje:
              'Antes de registrar, reinicia la cuenta paper de Alpaca con el '
              'monto del fondo. El aporte no reparte dinero hasta que se '
              'confirma.',
        ),
        const SizedBox(height: Espacio.x4),
        Campo(
          key: FormularioDeAporte.claveDelMonto,
          etiqueta: 'Monto (USD)',
          controlador: _monto,
          teclado: const TextInputType.numberWithOptions(decimal: true),
          pista: '10000,00',
          error: _errorDelMonto,
          alCambiar: (_) {
            if (_errorDelMonto != null || _registrado != null) {
              setState(() {
                _errorDelMonto = null;
                _registrado = null;
              });
            }
          },
        ),
        const SizedBox(height: Espacio.x4),
        Campo(
          key: FormularioDeAporte.claveDeLaReferencia,
          etiqueta: 'Referencia',
          controlador: _referencia,
          pista: 'paper-inicial',
          ayuda: 'Opcional. El id de la transferencia o paper-inicial.',
        ),
        const SizedBox(height: Espacio.x4),
        Campo(
          key: FormularioDeAporte.claveDeLaNota,
          etiqueta: 'Nota',
          controlador: _nota,
          ayuda: 'Opcional.',
        ),
        const SizedBox(height: Espacio.x5),
        Align(
          alignment: Alignment.centerLeft,
          child: BotonPrimario(
            texto: textoRegistrarAporte,
            icono: Icons.savings_outlined,
            alPresionar: _registrar,
          ),
        ),
        if (_registrado != null) ...[
          const SizedBox(height: Espacio.x4),
          const AvisoEnLinea(
            key: FormularioDeAporte.claveDelAvisoDeRegistrado,
            tipo: TipoAviso.exito,
            titulo: 'Aporte registrado',
            mensaje:
                'Queda pendiente: pasa a confirmado en la lista cuando la '
                'conciliación lo confirma.',
          ),
        ],
      ],
    );
  }
}

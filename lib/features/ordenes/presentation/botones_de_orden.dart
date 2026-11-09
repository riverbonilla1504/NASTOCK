/// Botones Comprar y Vender del detalle de un símbolo y el formulario de la
/// orden manual (HU-075, FR-169). Solo los ve el rol Usuario (CA-6); la RPC
/// vuelve a validar todo. La confirmación es un diálogo (D-61) y el id de la
/// orden se genera una vez por formulario: reintentar no la duplica (CA-3).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../core/perfil/perfil.dart';
import '../../../core/perfil/perfil_provider.dart';
import '../../../shared/widgets/avisos.dart';
import '../../../shared/widgets/botones.dart';
import '../../../shared/widgets/campo.dart';
import '../../../shared/widgets/cifras.dart';
import '../../../shared/widgets/dialogo_de_confirmacion.dart';
import '../../../shared/widgets/hoja_inferior.dart';
import '../data/ordenes_repositorio.dart';
import '../domain/orden_manual.dart';

/// Los dos botones de [simbolo]. No dibuja nada si quien mira no es Usuario.
class BotonesDeOrden extends ConsumerWidget {
  const BotonesDeOrden({
    required this.simbolo,
    required this.precio,
    super.key,
  });

  final String simbolo;

  /// Último precio conocido, para la estimación; `null` si no hay.
  final double? precio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(perfilProvider).value?.rol;
    if (rol != RolApp.usuario) return const SizedBox.shrink();
    Future<void> abrir(LadoDeOrden lado) async {
      final enviada = await mostrarHojaInferior<bool>(
        context,
        constructor: (_) =>
            FormularioDeOrden(simbolo: simbolo, lado: lado, precio: precio),
      );
      if (enviada == true && context.mounted) {
        mostrarAvisoTemporal(
          context,
          'Orden de ${lado.valor} de $simbolo enviada.',
        );
      }
    }

    return Row(
      children: [
        Expanded(
          child: BotonPrimario(
            texto: 'Comprar',
            alPresionar: () => abrir(LadoDeOrden.compra),
          ),
        ),
        const SizedBox(width: Espacio.x3),
        Expanded(
          child: BotonSecundario(
            texto: 'Vender',
            alPresionar: () => abrir(LadoDeOrden.venta),
          ),
        ),
      ],
    );
  }
}

/// Formulario de la orden: cantidad entera (D-63) y, en una compra, el stop y
/// el objetivo precargados con los parámetros (CA-1).
class FormularioDeOrden extends ConsumerStatefulWidget {
  const FormularioDeOrden({
    required this.simbolo,
    required this.lado,
    required this.precio,
    super.key,
  });

  final String simbolo;
  final LadoDeOrden lado;
  final double? precio;

  @override
  ConsumerState<FormularioDeOrden> createState() => _EstadoDelFormulario();
}

class _EstadoDelFormulario extends ConsumerState<FormularioDeOrden> {
  final String _id = nuevoIdDeOrden();
  final TextEditingController _cantidad = TextEditingController();
  final TextEditingController _stop = TextEditingController();
  final TextEditingController _objetivo = TextEditingController();
  bool _precargado = false;
  String? _errorDeCantidad;
  String? _errorDeStop;
  String? _errorDeObjetivo;

  bool get _esCompra => widget.lado == LadoDeOrden.compra;

  @override
  void dispose() {
    _cantidad.dispose();
    _stop.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  String _texto(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _revisar() async {
    final cantidad = cantidadEntera(_cantidad.text);
    final stop = _esCompra ? porcentaje(_stop.text) : null;
    final objetivo = _esCompra ? porcentaje(_objetivo.text) : null;
    setState(() {
      _errorDeCantidad = cantidad == null
          ? 'Escribe un número entero de acciones, de 1 en adelante.'
          : null;
      _errorDeStop = _esCompra && (stop == null || stop <= 0)
          ? 'Escribe un porcentaje mayor que 0.'
          : null;
      _errorDeObjetivo = _esCompra && (objetivo == null || objetivo <= 0)
          ? 'Escribe un porcentaje mayor que 0.'
          : null;
    });
    if (cantidad == null || _errorDeStop != null || _errorDeObjetivo != null) {
      return;
    }
    final precio = widget.precio;
    final resultado = await confirmarAccion(
      context,
      titulo: '${widget.lado.verbo} ${widget.simbolo}',
      simbolo: '$cantidad × ${widget.simbolo}',
      rotuloDelSimbolo: 'Acciones',
      monto: precio == null ? 0 : montoEstimado(cantidad, precio),
      textoConfirmar: 'Confirmar',
      detalle: _esCompra
          ? 'Compra con stop de ${_texto(stop!)} % y objetivo de '
                '${_texto(objetivo!)} %. El monto es aproximado: el precio '
                'límite se fija al enviarla.'
          : 'El monto es aproximado: el precio límite se fija al enviarla.',
      alConfirmar: () => ref
          .read(ordenesRepositorioProvider)
          .crearOrdenManual(
            id: _id,
            simbolo: widget.simbolo,
            lado: widget.lado,
            cantidad: cantidad,
            stopPct: stop,
            objetivoPct: objetivo,
          ),
    );
    if (resultado == ResultadoDeConfirmacion.hecho && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    if (_esCompra && !_precargado) {
      final defecto = ref.watch(proteccionPorDefectoProvider).value;
      if (defecto != null) {
        _precargado = true;
        _stop.text = _texto(defecto.stopPct);
        _objetivo.text = _texto(defecto.objetivoPct);
      }
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Espacio.x4,
        0,
        Espacio.x4,
        Espacio.x4 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                '${widget.lado.verbo} ${widget.simbolo}',
                style: textos.titleLarge,
              ),
            ),
            const SizedBox(height: Espacio.x1),
            if (widget.precio != null)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Precio actual ',
                    style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
                  ),
                  CifraUsd(widget.precio!),
                ],
              ),
            const SizedBox(height: Espacio.x4),
            Campo(
              etiqueta: 'Cantidad de acciones',
              controlador: _cantidad,
              teclado: TextInputType.number,
              error: _errorDeCantidad,
              pista: '1',
            ),
            if (_esCompra) ...[
              const SizedBox(height: Espacio.x3),
              Campo(
                etiqueta: 'Stop-loss (%)',
                controlador: _stop,
                teclado: const TextInputType.numberWithOptions(decimal: true),
                error: _errorDeStop,
                ayuda: 'Pérdida máxima antes de que se venda sola.',
              ),
              const SizedBox(height: Espacio.x3),
              Campo(
                etiqueta: 'Objetivo (%)',
                controlador: _objetivo,
                teclado: const TextInputType.numberWithOptions(decimal: true),
                error: _errorDeObjetivo,
                ayuda: 'Ganancia a la que se vende sola.',
              ),
            ],
            const SizedBox(height: Espacio.x4),
            BotonPrimario(texto: 'Revisar orden', alPresionar: _revisar),
          ],
        ),
      ),
    );
  }
}

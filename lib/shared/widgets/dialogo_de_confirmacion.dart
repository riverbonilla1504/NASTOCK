/// Componente común de confirmación: el diálogo que repite monto y símbolo
/// antes de una acción que toca dinero (docs/04 §8, docs/08 §9.3, FR-028).
///
/// Sin biometría (D-61): en móvil y en web se confirma con este diálogo. Lo
/// usan las historias de aprobar una sugerencia, crear una orden manual y
/// registrar un movimiento de dinero; este componente no conoce ninguna de sus
/// reglas.
///
/// Estados (docs/08 §9.3):
///
/// ```
/// inactivo → confirmando → enviando → hecho
///                │             └── error → enviando (reintento)
///                └── cancelado
/// ```
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'avisos.dart';
import 'botones.dart';
import 'cifras.dart';

/// Estados de una acción del usuario (docs/08 §9.3).
enum EstadoDeConfirmacion {
  inactivo,
  confirmando,
  enviando,
  hecho,
  cancelado,
  error,
}

/// Cómo terminó la confirmación. Un error no termina el diálogo: se muestra en
/// él y la persona puede reintentar o cancelar.
enum ResultadoDeConfirmacion { hecho, cancelado }

/// Máquina de estados de la confirmación. No sabe de pantallas.
class ControladorDeConfirmacion extends ChangeNotifier {
  EstadoDeConfirmacion _estado = EstadoDeConfirmacion.inactivo;
  Object? _error;

  EstadoDeConfirmacion get estado => _estado;

  /// El error de la última acción, mientras [estado] es `error`.
  Object? get error => _error;

  bool get enviando => _estado == EstadoDeConfirmacion.enviando;

  /// El diálogo se abrió: se espera la decisión de la persona.
  void abrir() => _cambiar(EstadoDeConfirmacion.confirmando);

  /// La persona dijo que no. Mientras se envía no se puede cancelar.
  void cancelar() {
    if (enviando) return;
    _error = null;
    _cambiar(EstadoDeConfirmacion.cancelado);
  }

  /// La persona confirmó: corre [accion]. Termina en `hecho` o en `error`.
  Future<void> confirmar(Future<void> Function() accion) async {
    if (enviando) return;
    _error = null;
    _cambiar(EstadoDeConfirmacion.enviando);
    try {
      await accion();
      _cambiar(EstadoDeConfirmacion.hecho);
    } catch (e) {
      _error = e;
      _cambiar(EstadoDeConfirmacion.error);
    }
  }

  void _cambiar(EstadoDeConfirmacion nuevo) {
    _estado = nuevo;
    notifyListeners();
  }
}

/// Abre el diálogo de confirmación y devuelve cómo terminó.
///
/// [alConfirmar] es la acción real (la RPC). Si falla, el diálogo muestra el
/// error ya traducido (`traducirError`) y deja reintentar. Cerrar el diálogo
/// sin confirmar cuenta como [ResultadoDeConfirmacion.cancelado].
Future<ResultadoDeConfirmacion> confirmarAccion(
  BuildContext context, {
  required String titulo,
  required String simbolo,
  required num monto,
  required String textoConfirmar,
  required Future<void> Function() alConfirmar,
  String? detalle,
}) async {
  final resultado = await showDialog<ResultadoDeConfirmacion>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DialogoDeConfirmacion(
      titulo: titulo,
      simbolo: simbolo,
      monto: monto,
      textoConfirmar: textoConfirmar,
      alConfirmar: alConfirmar,
      detalle: detalle,
    ),
  );
  return resultado ?? ResultadoDeConfirmacion.cancelado;
}

/// El diálogo en sí; [confirmarAccion] lo muestra.
class DialogoDeConfirmacion extends StatefulWidget {
  const DialogoDeConfirmacion({
    required this.titulo,
    required this.simbolo,
    required this.monto,
    required this.textoConfirmar,
    required this.alConfirmar,
    this.detalle,
    super.key,
  });

  final String titulo;

  /// Símbolo de la operación (p. ej. `QLD`), repetido para que se lea otra vez.
  final String simbolo;

  /// Monto en USD, repetido para que se lea otra vez.
  final num monto;
  final String textoConfirmar;
  final Future<void> Function() alConfirmar;

  /// Línea opcional bajo el título (p. ej. "Compra a mercado").
  final String? detalle;

  @override
  State<DialogoDeConfirmacion> createState() => _EstadoDelDialogo();
}

class _EstadoDelDialogo extends State<DialogoDeConfirmacion> {
  final ControladorDeConfirmacion _controlador = ControladorDeConfirmacion();

  @override
  void initState() {
    super.initState();
    _controlador
      ..addListener(_alCambiar)
      ..abrir();
  }

  @override
  void dispose() {
    _controlador
      ..removeListener(_alCambiar)
      ..dispose();
    super.dispose();
  }

  void _alCambiar() {
    if (!mounted) return;
    switch (_controlador.estado) {
      case EstadoDeConfirmacion.hecho:
        Navigator.of(context).pop(ResultadoDeConfirmacion.hecho);
      case EstadoDeConfirmacion.cancelado:
        Navigator.of(context).pop(ResultadoDeConfirmacion.cancelado);
      case EstadoDeConfirmacion.inactivo ||
          EstadoDeConfirmacion.confirmando ||
          EstadoDeConfirmacion.enviando ||
          EstadoDeConfirmacion.error:
        setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    final enviando = _controlador.enviando;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        scrollable: true,
        title: Semantics(header: true, child: Text(widget.titulo)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.detalle != null) ...[
              Text(
                widget.detalle!,
                style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
              ),
              const SizedBox(height: Espacio.x3),
            ],
            _FilaDelResumen(
              rotulo: 'Símbolo',
              valor: Text(widget.simbolo, style: textos.titleMedium),
            ),
            const SizedBox(height: Espacio.x2),
            _FilaDelResumen(rotulo: 'Monto', valor: CifraUsd(widget.monto)),
            if (_controlador.estado == EstadoDeConfirmacion.error) ...[
              const SizedBox(height: Espacio.x4),
              AvisoEnLinea.deError(_controlador.error),
            ],
          ],
        ),
        actions: [
          BotonTexto(
            texto: 'Cancelar',
            alPresionar: enviando ? null : _controlador.cancelar,
          ),
          BotonPrimario(
            texto: widget.textoConfirmar,
            enviando: enviando,
            alPresionar: () => _controlador.confirmar(widget.alConfirmar),
          ),
        ],
      ),
    );
  }
}

class _FilaDelResumen extends StatelessWidget {
  const _FilaDelResumen({required this.rotulo, required this.valor});

  final String rotulo;
  final Widget valor;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    // Rótulo a la izquierda y valor a la derecha; con texto grande, que no
    // caben juntos, el valor baja a su propia línea en vez de desbordar.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: Espacio.x1,
        children: [
          Text(rotulo, style: textos.bodyMedium!.copyWith(color: c.tintaSuave)),
          valor,
        ],
      ),
    );
  }
}

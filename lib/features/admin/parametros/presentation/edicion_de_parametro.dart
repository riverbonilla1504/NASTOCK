/// Hoja para cambiar un parámetro (HU-101, PM-54): el valor nuevo, el motivo
/// obligatorio y el historial de cambios. Los tres porcentajes del reparto se
/// editan juntos y no se pueden guardar si no suman 100 (CA-3).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tema.dart';
import '../../../../core/formato/formato_fechas.dart';
import '../../../../shared/widgets/avisos.dart';
import '../../../../shared/widgets/botones.dart';
import '../../../../shared/widgets/campo.dart';
import '../../../../shared/widgets/opciones_excluyentes.dart';
import '../domain/parametro.dart';
import '../domain/valor_de_parametro.dart';
import 'parametros_provider.dart';

/// Claves de los campos, para las pruebas.
const Key claveDelValorNuevo = Key('parametro-valor');
const Key claveDelMotivo = Key('parametro-motivo');
const Key claveDeGuardar = Key('parametro-guardar');
const Key claveDelRepartoReserva = Key('reparto-reserva');
const Key claveDelRepartoArriesgadas = Key('reparto-arriesgadas');
const Key claveDelRepartoUsuarios = Key('reparto-usuarios');

/// Edita un parámetro suelto.
class EdicionDeParametro extends ConsumerStatefulWidget {
  const EdicionDeParametro({required this.parametro, super.key});

  final Parametro parametro;

  @override
  ConsumerState<EdicionDeParametro> createState() => _EdicionDeParametroState();
}

class _EdicionDeParametroState extends ConsumerState<EdicionDeParametro> {
  late final TextEditingController _valor = TextEditingController(
    text: switch (widget.parametro.valor) {
      null => '',
      final List<Object?> lista => lista.join(', '),
      final v => textoDeValor(v),
    },
  );
  final _motivo = TextEditingController();
  late bool _booleano = widget.parametro.valor == true;
  String? _errorDelValor;
  String? _errorDelMotivo;
  Object? _error;
  bool _enviando = false;

  @override
  void dispose() {
    _valor.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final parametro = widget.parametro;
    final lectura = parametro.tipo == 'booleano'
        ? LecturaDeValor.valor(_booleano)
        : leerValor(parametro, _valor.text);
    final motivo = _motivo.text.trim();
    setState(() {
      _errorDelValor = lectura.error;
      _errorDelMotivo = motivo.isEmpty ? 'Escribe el motivo del cambio.' : null;
      _error = null;
    });
    if (!lectura.esValido || motivo.isEmpty) return;

    setState(() => _enviando = true);
    try {
      await ref
          .read(parametrosProvider.notifier)
          .actualizar(parametro.clave, lectura.valor, motivo);
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
    final parametro = widget.parametro;
    final textos = Theme.of(context).textTheme;
    final suave = textos.bodyMedium!.copyWith(
      color: context.colores.tintaSuave,
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Espacio.x4,
        Espacio.x6,
        Espacio.x4,
        Espacio.x4 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(parametro.clave, style: textos.titleMedium),
          const SizedBox(height: Espacio.x1),
          Text(parametro.descripcion, style: suave),
          if (parametro.rango != null) ...[
            const SizedBox(height: Espacio.x1),
            Text('Rango permitido: ${parametro.rango}', style: suave),
          ],
          const SizedBox(height: Espacio.x4),
          if (parametro.tipo == 'booleano')
            OpcionesExcluyentes<bool>(
              etiqueta: 'Valor',
              opciones: const [
                OpcionExcluyente(valor: true, etiqueta: 'Sí'),
                OpcionExcluyente(valor: false, etiqueta: 'No'),
              ],
              valor: _booleano,
              alElegir: (v) => setState(() => _booleano = v),
            )
          else
            Campo(
              key: claveDelValorNuevo,
              etiqueta: 'Valor nuevo',
              controlador: _valor,
              teclado: parametro.tipo == 'numero'
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              ayuda: switch (parametro.tipo) {
                'lista' => 'Separa los elementos con comas.',
                'numero' when parametro.clave == 'cupos.maximo_usd' =>
                  'Déjalo vacío para quitar el límite.',
                _ => null,
              },
              error: _errorDelValor,
            ),
          const SizedBox(height: Espacio.x3),
          Campo(
            key: claveDelMotivo,
            etiqueta: 'Motivo del cambio',
            controlador: _motivo,
            error: _errorDelMotivo,
          ),
          if (_error != null) ...[
            const SizedBox(height: Espacio.x3),
            AvisoEnLinea.deError(_error),
          ],
          const SizedBox(height: Espacio.x4),
          BotonPrimario(
            key: claveDeGuardar,
            texto: 'Guardar',
            enviando: _enviando,
            alPresionar: _guardar,
          ),
          const SizedBox(height: Espacio.x6),
          _Historial(clave: parametro.clave),
        ],
      ),
    );
  }
}

/// Edita los tres porcentajes del reparto juntos (CA-3).
class EdicionDelReparto extends ConsumerStatefulWidget {
  const EdicionDelReparto({required this.parametros, super.key});

  /// Los tres parámetros `reparto.pct_*`.
  final List<Parametro> parametros;

  @override
  ConsumerState<EdicionDelReparto> createState() => _EdicionDelRepartoState();
}

class _EdicionDelRepartoState extends ConsumerState<EdicionDelReparto> {
  late final TextEditingController _reserva = _con('reparto.pct_reserva');
  late final TextEditingController _arriesgadas = _con(
    'reparto.pct_arriesgadas',
  );
  late final TextEditingController _usuarios = _con('reparto.pct_usuarios');
  final _motivo = TextEditingController();
  String? _errorDeLaSuma;
  String? _errorDelMotivo;
  Object? _error;
  bool _enviando = false;

  TextEditingController _con(String clave) => TextEditingController(
    text: textoDeValor(
      widget.parametros.firstWhere((p) => p.clave == clave).valor,
    ),
  );

  @override
  void dispose() {
    _reserva.dispose();
    _arriesgadas.dispose();
    _usuarios.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final lectura = leerReparto(
      reserva: _reserva.text,
      arriesgadas: _arriesgadas.text,
      usuarios: _usuarios.text,
    );
    final motivo = _motivo.text.trim();
    setState(() {
      _errorDeLaSuma = lectura.error;
      _errorDelMotivo = motivo.isEmpty ? 'Escribe el motivo del cambio.' : null;
      _error = null;
    });
    if (!lectura.esValido || motivo.isEmpty) return;

    setState(() => _enviando = true);
    try {
      await ref
          .read(parametrosProvider.notifier)
          .actualizar('reparto', lectura.valor, motivo);
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
    final suave = textos.bodyMedium!.copyWith(
      color: context.colores.tintaSuave,
    );
    const teclado = TextInputType.numberWithOptions(decimal: true);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Espacio.x4,
        Espacio.x6,
        Espacio.x4,
        Espacio.x4 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reparto de aportes', style: textos.titleMedium),
          const SizedBox(height: Espacio.x1),
          Text(
            'Cómo se divide cada aporte nuevo. Los tres porcentajes se cambian '
            'juntos y suman 100. No mueve el dinero que ya está repartido.',
            style: suave,
          ),
          const SizedBox(height: Espacio.x4),
          Campo(
            key: claveDelRepartoReserva,
            etiqueta: 'Reserva (%)',
            controlador: _reserva,
            teclado: teclado,
          ),
          const SizedBox(height: Espacio.x3),
          Campo(
            key: claveDelRepartoArriesgadas,
            etiqueta: 'Arriesgadas (%)',
            controlador: _arriesgadas,
            teclado: teclado,
          ),
          const SizedBox(height: Espacio.x3),
          Campo(
            key: claveDelRepartoUsuarios,
            etiqueta: 'Usuarios (%)',
            controlador: _usuarios,
            teclado: teclado,
            error: _errorDeLaSuma,
          ),
          const SizedBox(height: Espacio.x3),
          Campo(
            key: claveDelMotivo,
            etiqueta: 'Motivo del cambio',
            controlador: _motivo,
            error: _errorDelMotivo,
          ),
          if (_error != null) ...[
            const SizedBox(height: Espacio.x3),
            AvisoEnLinea.deError(_error),
          ],
          const SizedBox(height: Espacio.x4),
          BotonPrimario(
            key: claveDeGuardar,
            texto: 'Guardar',
            enviando: _enviando,
            alPresionar: _guardar,
          ),
          const SizedBox(height: Espacio.x6),
          _Historial(clave: 'reparto.pct_reserva', titulo: 'Historial'),
        ],
      ),
    );
  }
}

class _Historial extends ConsumerWidget {
  const _Historial({required this.clave, this.titulo = 'Historial de cambios'});

  final String clave;
  final String titulo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final suave = textos.bodyMedium!.copyWith(
      color: context.colores.tintaSuave,
    );
    final cambios = ref.watch(historialProvider(clave));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: textos.titleSmall),
        const SizedBox(height: Espacio.x2),
        switch (cambios) {
          AsyncData(:final value) when value.isEmpty => Text(
            'Aún no se ha cambiado.',
            style: suave,
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final c in value)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Espacio.x1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${textoDeValor(c.valorAnterior)} → '
                          '${textoDeValor(c.valorNuevo)}\n${c.motivo}',
                          style: textos.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: Espacio.x3),
                      Text(formatearFechaHora(c.cambiadoEn), style: suave),
                    ],
                  ),
                ),
            ],
          ),
          AsyncError() => Text('No se pudo leer el historial.', style: suave),
          _ => Text('Cargando…', style: suave),
        },
      ],
    );
  }
}

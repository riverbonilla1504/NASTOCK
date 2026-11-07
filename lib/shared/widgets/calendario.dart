/// Calendario del mercado y selector de periodo.
///
/// Un mes de lunes a domingo, como el calendario de pared: hoy en un círculo
/// morado, el periodo elegido en tinta, los fines de semana atenuados, los
/// festivos de la bolsa rayados con su marca y la media jornada con media
/// luna. Cada marca tiene su leyenda en palabras. Festivos y medias jornadas
/// los pone quien lo usa: vienen del calendario del broker (RN-41, HU-027).
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'botones.dart';
import 'hoja_inferior.dart';

const List<String> _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const List<String> _diasCortos = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

const List<String> _diasLargos = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

DateTime _soloDia(DateTime d) => DateTime(d.year, d.month, d.day);

String _dos(int n) => n.toString().padLeft(2, '0');

/// Fecha de calendario como `DD/MM/AAAA` (es una fecha, no un instante).
String formatearDiaDeCalendario(DateTime d) =>
    '${_dos(d.day)}/${_dos(d.month)}/${d.year.toString().padLeft(4, '0')}';

/// "Noviembre 2026".
String tituloDeMes(DateTime mes) {
  final nombre = _meses[mes.month - 1];
  return '${nombre[0].toUpperCase()}${nombre.substring(1)} ${mes.year}';
}

class CalendarioDelMercado extends StatelessWidget {
  const CalendarioDelMercado({
    required this.mes,
    required this.hoy,
    this.festivos = const {},
    this.mediasJornadas = const {},
    this.seleccion,
    this.alElegirDia,
    this.alCambiarMes,
    this.primerDia,
    this.ultimoDia,
    this.conLeyenda = true,
    super.key,
  });

  /// Cualquier día del mes que se muestra.
  final DateTime mes;
  final DateTime hoy;

  /// Días en que la bolsa cierra.
  final Set<DateTime> festivos;

  /// Días con cierre anticipado.
  final Set<DateTime> mediasJornadas;

  /// Periodo elegido; `start == end` para un solo día.
  final DateTimeRange? seleccion;
  final ValueChanged<DateTime>? alElegirDia;

  /// Recibe el primer día del mes al que se cambia.
  final ValueChanged<DateTime>? alCambiarMes;
  final DateTime? primerDia;
  final DateTime? ultimoDia;
  final bool conLeyenda;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final primero = DateTime(mes.year, mes.month);
    final diasDelMes = DateUtils.getDaysInMonth(mes.year, mes.month);
    final desfase = primero.weekday - 1;
    final semanas = ((desfase + diasDelMes) / 7).ceil();
    final festivosDia = festivos.map(_soloDia).toSet();
    final mediasDia = mediasJornadas.map(_soloDia).toSet();
    final hoyDia = _soloDia(hoy);
    final inicio = seleccion == null ? null : _soloDia(seleccion!.start);
    final fin = seleccion == null ? null : _soloDia(seleccion!.end);
    final minimo = primerDia == null ? null : _soloDia(primerDia!);
    final maximo = ultimoDia == null ? null : _soloDia(ultimoDia!);
    final anterior = DateTime(mes.year, mes.month - 1);
    final siguiente = DateTime(mes.year, mes.month + 1);
    final puedeAnterior =
        alCambiarMes != null &&
        (minimo == null ||
            DateTime(minimo.year, minimo.month).isBefore(primero));
    final puedeSiguiente =
        alCambiarMes != null &&
        (maximo == null ||
            !siguiente.isAfter(DateTime(maximo.year, maximo.month)));

    Widget celda(int indice) {
      final numero = indice - desfase + 1;
      if (numero < 1 || numero > diasDelMes) {
        return Container(
          height: Espacio.objetivoTactil,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.regla)),
          ),
        );
      }
      final dia = DateTime(mes.year, mes.month, numero);
      final habilitado =
          (minimo == null || !dia.isBefore(minimo)) &&
          (maximo == null || !dia.isAfter(maximo));
      final extremo =
          inicio != null &&
          (DateUtils.isSameDay(dia, inicio) || DateUtils.isSameDay(dia, fin));
      final enPeriodo =
          inicio != null &&
          fin != null &&
          dia.isAfter(inicio) &&
          dia.isBefore(fin);
      return _CeldaDeDia(
        dia: dia,
        hoy: DateUtils.isSameDay(dia, hoyDia),
        finDeSemana: dia.weekday >= DateTime.saturday,
        festivo: festivosDia.contains(dia),
        mediaJornada: mediasDia.contains(dia),
        extremo: extremo,
        enPeriodo: enPeriodo,
        habilitado: habilitado,
        alTocar: habilitado && alElegirDia != null
            ? () => alElegirDia!(dia)
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mes anterior',
              onPressed: puedeAnterior ? () => alCambiarMes!(anterior) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  tituloDeMes(primero),
                  textAlign: TextAlign.center,
                  style: textos.titleLarge,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Mes siguiente',
              onPressed: puedeSiguiente ? () => alCambiarMes!(siguiente) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: Espacio.x2),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.tinta)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Espacio.x1 + 2),
                    child: Semantics(
                      label: _diasLargos[i],
                      excludeSemantics: true,
                      child: Text(
                        _diasCortos[i],
                        textAlign: TextAlign.center,
                        style: textos.labelMedium,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (var s = 0; s < semanas; s++)
          Row(
            children: [
              for (var d = 0; d < 7; d++) Expanded(child: celda(s * 7 + d)),
            ],
          ),
        if (conLeyenda) ...[
          const SizedBox(height: Espacio.x3),
          const LeyendaDelCalendario(),
        ],
      ],
    );
  }
}

class _CeldaDeDia extends StatelessWidget {
  const _CeldaDeDia({
    required this.dia,
    required this.hoy,
    required this.finDeSemana,
    required this.festivo,
    required this.mediaJornada,
    required this.extremo,
    required this.enPeriodo,
    required this.habilitado,
    required this.alTocar,
  });

  final DateTime dia;
  final bool hoy;
  final bool finDeSemana;
  final bool festivo;
  final bool mediaJornada;
  final bool extremo;
  final bool enPeriodo;
  final bool habilitado;
  final VoidCallback? alTocar;

  String get _lectura {
    final partes = [
      '${_diasLargos[dia.weekday - 1]} ${dia.day} de ${_meses[dia.month - 1]} '
          'de ${dia.year}',
      if (hoy) 'hoy',
      if (festivo) 'festivo: la bolsa cierra',
      if (mediaJornada) 'media jornada: cierre anticipado',
      if (extremo) 'inicio o fin del periodo',
      if (enPeriodo) 'dentro del periodo',
      if (!habilitado) 'no disponible',
    ];
    return partes.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final colorNumero = extremo
        ? c.papel
        : (!habilitado || finDeSemana)
        ? c.tintaTenue
        : festivo
        ? c.tintaSuave
        : c.tinta;
    final numero = Text(
      '${dia.day}',
      style: textos.titleMedium!.copyWith(
        color: hoy && !extremo ? c.sobreMorado : colorNumero,
        fontWeight: finDeSemana && !extremo && !hoy
            ? FontWeight.w400
            : FontWeight.w600,
      ),
    );
    final fondo = extremo
        ? c.tinta
        : enPeriodo
        ? c.regla
        : null;
    final marcaColor = extremo ? c.papel : c.tinta;
    return Semantics(
      label: _lectura,
      button: alTocar != null,
      selected: extremo || enPeriodo,
      excludeSemantics: true,
      child: InkWell(
        onTap: alTocar,
        child: Container(
          height: Espacio.objetivoTactil,
          decoration: BoxDecoration(
            color: fondo,
            border: Border(bottom: BorderSide(color: c.regla)),
          ),
          child: CustomPaint(
            painter: festivo && fondo == null ? _Rayado(c.regla) : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hoy)
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.morado,
                      shape: BoxShape.circle,
                    ),
                    child: numero,
                  )
                else
                  numero,
                if (festivo)
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: marcaColor, width: 1.5),
                    ),
                  )
                else if (mediaJornada)
                  _MediaLuna(color: marcaColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaLuna extends StatelessWidget {
  const _MediaLuna({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      width: 9,
      height: 4.5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(5)),
      ),
    );
  }
}

class _Rayado extends CustomPainter {
  _Rayado(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        pincel,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Rayado viejo) => viejo.color != color;
}

/// Leyenda en palabras de las marcas del calendario.
class LeyendaDelCalendario extends StatelessWidget {
  const LeyendaDelCalendario({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final estilo = Theme.of(context).textTheme.bodySmall!
        .copyWith(color: c.tintaSuave);
    Widget item(Widget muestra, String texto) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 18, height: 16, child: Center(child: muestra)),
        const SizedBox(width: Espacio.x2),
        Flexible(child: Text(texto, style: estilo)),
      ],
    );
    return Wrap(
      spacing: Espacio.x4,
      runSpacing: Espacio.x2,
      children: [
        item(
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: c.morado, shape: BoxShape.circle),
          ),
          'Hoy',
        ),
        item(
          Container(width: 16, height: 14, color: c.tinta),
          'Inicio y fin del periodo',
        ),
        item(
          SizedBox(
            width: 16,
            height: 14,
            child: CustomPaint(painter: _Rayado(c.reglaFuerte)),
          ),
          'Festivo: la bolsa cierra',
        ),
        item(_MediaLuna(color: c.tinta), 'Media jornada: cierre anticipado'),
      ],
    );
  }
}

/// Abre el selector de periodo en una hoja inferior. Devuelve el periodo
/// elegido, o `null` si se cancela.
Future<DateTimeRange?> mostrarSelectorDePeriodo(
  BuildContext context, {
  required DateTime hoy,
  DateTimeRange? inicial,
  Set<DateTime> festivos = const {},
  Set<DateTime> mediasJornadas = const {},
  DateTime? primerDia,
  DateTime? ultimoDia,
}) {
  return mostrarHojaInferior<DateTimeRange>(
    context,
    constructor: (_) => SelectorDePeriodo(
      hoy: hoy,
      inicial: inicial,
      festivos: festivos,
      mediasJornadas: mediasJornadas,
      primerDia: primerDia,
      ultimoDia: ultimoDia,
    ),
  );
}

/// Contenido del selector de periodo; lo usa [mostrarSelectorDePeriodo].
class SelectorDePeriodo extends StatefulWidget {
  const SelectorDePeriodo({
    required this.hoy,
    this.inicial,
    this.festivos = const {},
    this.mediasJornadas = const {},
    this.primerDia,
    this.ultimoDia,
    super.key,
  });

  final DateTime hoy;
  final DateTimeRange? inicial;
  final Set<DateTime> festivos;
  final Set<DateTime> mediasJornadas;
  final DateTime? primerDia;
  final DateTime? ultimoDia;

  @override
  State<SelectorDePeriodo> createState() => _SelectorDePeriodoState();
}

class _SelectorDePeriodoState extends State<SelectorDePeriodo> {
  late DateTime _mes = widget.inicial?.start ?? widget.hoy;
  late DateTime? _inicio = widget.inicial?.start;
  late DateTime? _fin = widget.inicial?.end;

  void _elegir(DateTime dia) {
    setState(() {
      if (_inicio == null || _fin != null) {
        _inicio = dia;
        _fin = null;
      } else if (dia.isBefore(_inicio!)) {
        _inicio = dia;
      } else {
        _fin = dia;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    final indicacion = _inicio == null
        ? 'Elige el primer día'
        : _fin == null
        ? 'Desde ${formatearDiaDeCalendario(_inicio!)} · elige el último día'
        : 'Desde ${formatearDiaDeCalendario(_inicio!)} hasta '
              '${formatearDiaDeCalendario(_fin!)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(Espacio.x4, 0, Espacio.x4, Espacio.x4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Periodo', style: textos.titleLarge),
          const SizedBox(height: Espacio.x1),
          Semantics(
            liveRegion: true,
            child: Text(
              indicacion,
              style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
            ),
          ),
          const SizedBox(height: Espacio.x2),
          CalendarioDelMercado(
            mes: _mes,
            hoy: widget.hoy,
            festivos: widget.festivos,
            mediasJornadas: widget.mediasJornadas,
            seleccion: _inicio == null
                ? null
                : DateTimeRange(start: _inicio!, end: _fin ?? _inicio!),
            primerDia: widget.primerDia,
            ultimoDia: widget.ultimoDia,
            alElegirDia: _elegir,
            alCambiarMes: (mes) => setState(() => _mes = mes),
          ),
          const SizedBox(height: Espacio.x4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BotonSecundario(
                texto: 'Cancelar',
                alPresionar: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: Espacio.x2),
              BotonPrimario(
                texto: 'Listo',
                alPresionar: _inicio != null && _fin != null
                    ? () =>
                          Navigator.of(context)
                              .pop(DateTimeRange(start: _inicio!, end: _fin!))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Campo de solo lectura que muestra un periodo y abre el selector.
class CampoDePeriodo extends StatelessWidget {
  const CampoDePeriodo({
    required this.etiqueta,
    required this.hoy,
    required this.alCambiar,
    this.periodo,
    this.ayuda,
    this.festivos = const {},
    this.mediasJornadas = const {},
    this.primerDia,
    this.ultimoDia,
    super.key,
  });

  final String etiqueta;
  final DateTime hoy;
  final DateTimeRange? periodo;
  final ValueChanged<DateTimeRange> alCambiar;
  final String? ayuda;
  final Set<DateTime> festivos;
  final Set<DateTime> mediasJornadas;
  final DateTime? primerDia;
  final DateTime? ultimoDia;

  Future<void> _abrir(BuildContext context) async {
    final elegido = await mostrarSelectorDePeriodo(
      context,
      hoy: hoy,
      inicial: periodo,
      festivos: festivos,
      mediasJornadas: mediasJornadas,
      primerDia: primerDia,
      ultimoDia: ultimoDia,
    );
    if (elegido != null) alCambiar(elegido);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final texto = periodo == null
        ? 'Elige el periodo'
        : '${formatearDiaDeCalendario(periodo!.start)} — '
              '${formatearDiaDeCalendario(periodo!.end)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: textos.titleSmall!.copyWith(fontSize: 13)),
        const SizedBox(height: Espacio.x1 + 2),
        Semantics(
          button: true,
          label: '$etiqueta: $texto',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => _abrir(context),
            borderRadius: BorderRadius.circular(Radios.control),
            child: InputDecorator(
              isEmpty: false,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
                helperText: ayuda,
              ),
              child: Text(
                texto,
                style: textos.bodyLarge!.copyWith(
                  color: periodo == null ? context.colores.tintaTenue : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tema.dart';
import '../../../../core/exportacion/guardar_csv.dart';
import '../../../../core/formato/formato_fechas.dart';
import '../../../../shared/widgets/barra_superior.dart';
import '../data/bitacora_repositorio.dart';
import '../data/csv_de_bitacora.dart';

class PaginaBitacora extends ConsumerStatefulWidget {
  const PaginaBitacora({super.key});

  @override
  ConsumerState<PaginaBitacora> createState() => _PaginaBitacoraState();
}

class _PaginaBitacoraState extends ConsumerState<PaginaBitacora> {
  final _formulario = GlobalKey<FormState>();
  final _actor = TextEditingController();
  final _accion = TextEditingController();
  final _entidad = TextEditingController();
  DateTimeRange? _fechas;
  FiltrosDeBitacora _filtros = (
    actor: '',
    accion: '',
    entidad: '',
    desde: null,
    hastaExclusiva: null,
  );
  final _registros = <RegistroDeBitacora>[];
  var _cargando = false;
  var _exportando = false;
  var _hayMas = false;
  var _fallo = false;
  var _reintentarPagina = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _actor.dispose();
    _accion.dispose();
    _entidad.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool siguiente = false}) async {
    setState(() {
      _cargando = true;
      _fallo = false;
      if (!siguiente) _registros.clear();
    });
    try {
      final pagina = await ref.read(leerBitacoraProvider)(
        _filtros,
        antesDe: siguiente ? _registros.last.id : null,
      );
      if (!mounted) return;
      setState(() {
        _registros.addAll(pagina);
        _hayMas = pagina.length == tamanoPaginaDeBitacora;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fallo = true;
        _reintentarPagina = siguiente;
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegirFechas() async {
    final hoy = DateTime.now().toUtc().add(desfaseBogota);
    final fechas = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(hoy.year, hoy.month, hoy.day),
      initialDateRange: _fechas,
    );
    if (mounted && fechas != null) setState(() => _fechas = fechas);
  }

  void _aplicar() {
    if (!_formulario.currentState!.validate()) return;
    DateTime bogota(DateTime fecha, [int dias = 0]) => DateTime.utc(
      fecha.year,
      fecha.month,
      fecha.day + dias,
    ).subtract(desfaseBogota);
    final fechas = _fechas;
    _filtros = (
      actor: _actor.text.trim(),
      accion: _accion.text.trim(),
      entidad: _entidad.text.trim(),
      desde: fechas == null ? null : bogota(fechas.start),
      hastaExclusiva: fechas == null ? null : bogota(fechas.end, 1),
    );
    _cargar();
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final csv = await csvDeBitacora(ref.read(leerBitacoraProvider), _filtros);
      if (mounted) await guardarCsv('bitacora.csv', csv);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo exportar la bitácora.')),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = _cargando || _exportando;
    final fechas = _fechas;
    return Scaffold(
      appBar: BarraSuperior(
        titulo: 'Bitácora',
        acciones: [
          TextButton(
            onPressed: ocupado || _registros.isEmpty ? null : _exportar,
            child: Text(_exportando ? 'Exportando…' : 'Exportar CSV'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(Espacio.x4),
        itemCount: _registros.length + 2,
        itemBuilder: (context, indice) {
          if (indice == 0) {
            return Form(
              key: _formulario,
              child: Column(
                children: [
                  TextFormField(
                    controller: _actor,
                    decoration: const InputDecoration(
                      labelText: 'ID de la persona o Sistema',
                    ),
                    validator: (texto) {
                      final valor = texto?.trim() ?? '';
                      if (valor.isEmpty || valor.toLowerCase() == 'sistema') {
                        return null;
                      }
                      final uuid = RegExp(
                        r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
                      );
                      return uuid.hasMatch(valor)
                          ? null
                          : 'Escribe un ID válido.';
                    },
                  ),
                  TextFormField(
                    controller: _accion,
                    decoration: const InputDecoration(labelText: 'Acción'),
                  ),
                  TextFormField(
                    controller: _entidad,
                    decoration: const InputDecoration(labelText: 'Entidad'),
                  ),
                  Wrap(
                    spacing: Espacio.x2,
                    children: [
                      TextButton(
                        onPressed: ocupado ? null : _elegirFechas,
                        child: Text(
                          fechas == null
                              ? 'Rango de fechas'
                              : '${_fechaCivil(fechas.start)} – ${_fechaCivil(fechas.end)}',
                        ),
                      ),
                      if (_fechas != null)
                        TextButton(
                          onPressed: ocupado
                              ? null
                              : () => setState(() => _fechas = null),
                          child: const Text('Quitar fechas'),
                        ),
                      FilledButton(
                        onPressed: ocupado ? null : _aplicar,
                        child: const Text('Aplicar filtros'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          if (indice <= _registros.length) {
            final registro = _registros[indice - 1];
            return ListTile(
              title: Text(registro.accion),
              subtitle: Text(
                '${formatearFechaHora(registro.momento)} · ${registro.actor ?? 'Sistema'}\n'
                '${registro.entidad}${registro.entidadId == null ? '' : ' · ${registro.entidadId}'}',
              ),
              isThreeLine: true,
            );
          }
          if (_cargando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_fallo) {
            return TextButton(
              onPressed: () => _cargar(siguiente: _reintentarPagina),
              child: const Text('No se pudo cargar la bitácora. Reintentar'),
            );
          }
          if (_registros.isEmpty) {
            return const Center(child: Text('Sin registros'));
          }
          if (!_hayMas) return const SizedBox.shrink();
          return TextButton(
            onPressed: ocupado ? null : () => _cargar(siguiente: true),
            child: const Text('Cargar más registros'),
          );
        },
      ),
    );
  }

  String _fechaCivil(DateTime fecha) =>
      '${fecha.day}/${fecha.month}/${fecha.year}';
}

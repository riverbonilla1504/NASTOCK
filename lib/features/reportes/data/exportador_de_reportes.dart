/// Exportador de reportes en CSV (HU-117, FR-203).
///
/// Copia adaptada de `lib/services/report_exporter.dart` de la v2
/// (`ritech-sas-inversiones`, docs/05 §11). De la v2 se conserva lo probado:
/// título, periodo y fecha de generación arriba, una fila de encabezados,
/// totales al final, ningún archivo si no hay filas y nombre con la fecha.
/// Cambia lo que la v3 pide:
///
/// - Columnas y filas genéricas en vez de los modelos de la v2, para que lo
///   usen los reportes (HU-095) y la bitácora (HU-108).
/// - Montos, porcentajes y fechas con el formato de la app
///   (`lib/core/formato/`): `USD 1.234,50`, `+1,24 %`, hora de Bogotá.
/// - Solo CSV (docs/01 §4; el formato texto de la v2 no se copia), con BOM,
///   CRLF y cada celda protegida con `celdaCsv`, como la bitácora.
///
/// Quien llama aplica los filtros: aquí se exporta exactamente lo que llega.
library;

import '../../../core/exportacion/celda_csv.dart';
import '../../../core/exportacion/guardar_csv.dart';
import '../../../core/formato/formato_dinero.dart';
import '../../../core/formato/formato_fechas.dart';
import '../../../core/formato/formato_porcentaje.dart';

/// Cómo se escribe el valor de una celda.
enum FormatoDeCelda {
  /// Tal cual (`toString`).
  texto,

  /// Monto en USD: `USD 1.234,50`.
  dinero,

  /// Variación con signo: `+1,24 %`.
  porcentaje,

  /// Día en hora de Bogotá: `DD/MM/AAAA`.
  fecha,

  /// Día y hora en hora de Bogotá: `DD/MM/AAAA HH:MM`.
  fechaHora,
}

/// Una columna del reporte: su encabezado y cómo sacar el valor de una fila.
class ColumnaDeReporte<T> {
  const ColumnaDeReporte(
    this.encabezado,
    this.valor, {
    this.formato = FormatoDeCelda.texto,
  });

  final String encabezado;

  /// Valor de la celda; `null` deja la celda vacía.
  final Object? Function(T fila) valor;

  final FormatoDeCelda formato;
}

/// Un renglón de totales al final del reporte; el monto sale como dinero.
class TotalDeReporte {
  const TotalDeReporte(this.etiqueta, this.monto);

  final String etiqueta;
  final num monto;
}

/// Resultado de armar un reporte: el archivo listo o el aviso de que no hay
/// nada que exportar.
class ResultadoDeReporte {
  const ResultadoDeReporte.listo({
    required String this.contenido,
    required String this.nombreDeArchivo,
  }) : exito = true,
       mensaje = null;

  const ResultadoDeReporte.vacio(String this.mensaje)
    : exito = false,
      contenido = null,
      nombreDeArchivo = null;

  final bool exito;
  final String? mensaje;
  final String? contenido;
  final String? nombreDeArchivo;
}

/// Arma reportes en CSV.
abstract final class ExportadorDeReportes {
  static const String mensajeSinDatos =
      'No hay datos en el rango seleccionado: no se generó el reporte.';

  /// Arma el CSV de [filas] con [columnas].
  ///
  /// [desde] y [hasta] son días calendario y se escriben tal cual; sin los dos,
  /// el periodo es "Todo el histórico". [generadoEn] es un instante y se
  /// muestra en hora de Bogotá, igual que la fecha del nombre del archivo
  /// (`<nombreBase>-AAAAMMDD.csv`). Sin filas no se genera archivo.
  static ResultadoDeReporte csv<T>({
    required String titulo,
    required String nombreBase,
    required List<ColumnaDeReporte<T>> columnas,
    required List<T> filas,
    required DateTime generadoEn,
    DateTime? desde,
    DateTime? hasta,
    List<TotalDeReporte> totales = const [],
  }) {
    if (filas.isEmpty) return const ResultadoDeReporte.vacio(mensajeSinDatos);

    final periodo = desde == null || hasta == null
        ? 'Todo el histórico'
        : '${_dia(desde)} a ${_dia(hasta)}';

    final csv = StringBuffer('﻿');
    void renglon(Iterable<String?> celdas) =>
        csv.write('${celdas.map(celdaCsv).join(',')}\r\n');

    renglon(['Reporte de $titulo · RiTech SAS']);
    renglon(['Periodo', periodo]);
    renglon(['Generado', formatearFechaHora(generadoEn)]);
    csv.write('\r\n');
    renglon(columnas.map((c) => c.encabezado));
    for (final fila in filas) {
      renglon(columnas.map((c) => _celda(c.valor(fila), c.formato)));
    }
    if (totales.isNotEmpty) {
      csv.write('\r\n');
      for (final total in totales) {
        renglon([total.etiqueta, formatearUsd(total.monto)]);
      }
    }

    return ResultadoDeReporte.listo(
      contenido: csv.toString(),
      nombreDeArchivo: '$nombreBase-${_sello(generadoEn)}.csv',
    );
  }

  static String? _celda(Object? valor, FormatoDeCelda formato) {
    if (valor == null) return null;
    return switch (formato) {
      FormatoDeCelda.texto => valor.toString(),
      FormatoDeCelda.dinero => formatearUsd(valor as num),
      FormatoDeCelda.porcentaje => formatearPorcentaje(valor as num),
      FormatoDeCelda.fecha => formatearFecha(valor as DateTime),
      FormatoDeCelda.fechaHora => formatearFechaHora(valor as DateTime),
    };
  }

  /// Día calendario sin cambiar de zona: `DD/MM/AAAA`.
  static String _dia(DateTime d) =>
      '${_dos(d.day)}/${_dos(d.month)}/${d.year.toString().padLeft(4, '0')}';

  /// Fecha de Bogotá del instante como `AAAAMMDD`.
  static String _sello(DateTime instante) {
    final b = instante.toUtc().add(desfaseBogota);
    return '${b.year.toString().padLeft(4, '0')}${_dos(b.month)}${_dos(b.day)}';
  }

  static String _dos(int n) => n.toString().padLeft(2, '0');
}

/// Guarda el archivo de un reporte.
typedef GuardarArchivo = Future<bool> Function(String nombre, String contenido);

/// Guarda [resultado] con [guardar]: en la web lo descarga y en Android abre
/// el selector de archivos (`lib/core/exportacion/guardar_csv.dart`).
///
/// Devuelve `false` si el reporte está vacío (no llama a [guardar]) o si la
/// persona cancela el selector.
Future<bool> guardarReporte(
  ResultadoDeReporte resultado, {
  GuardarArchivo guardar = guardarCsv,
}) async {
  final contenido = resultado.contenido;
  final nombre = resultado.nombreDeArchivo;
  if (!resultado.exito || contenido == null || nombre == null) return false;
  return guardar(nombre, contenido);
}

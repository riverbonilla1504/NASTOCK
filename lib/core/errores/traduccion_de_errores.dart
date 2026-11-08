/// Traducción de errores a mensajes en español (docs/06 §9, FR-002).
///
/// Regla: la persona nunca ve el texto crudo de Postgres ni de una excepción.
/// Un código del catálogo muestra su mensaje; cualquier otra cosa muestra
/// [mensajeGenerico].
library;

import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../formato/formato_fechas.dart';
import 'codigos_de_error.dart';
import 'fallo_de_ingreso.dart';

/// Un código con la forma de los del catálogo: mayúsculas, dígitos y guiones
/// bajos (`NO_AUTORIZADO`, `REGLA_RR_05`).
final RegExp _formaDeCodigo = RegExp(r'^[A-Z][A-Z0-9_]*$');

final RegExp _reglaDeRiesgo = RegExp(r'^REGLA_RR_(\d{2})$');

/// Error de negocio ya reconocido: el código del catálogo y, si lo trae, el
/// detalle (`DETAIL`) que lo acompaña.
class ErrorDeNegocio implements Exception {
  const ErrorDeNegocio(this.codigo, {this.detalle});

  final String codigo;
  final String? detalle;

  @override
  String toString() => 'ErrorDeNegocio($codigo)';
}

/// Mensaje en español para un código del catálogo de 06 §9.
///
/// [detalle] es el `DETAIL` del error. Solo se usa para completar el mensaje
/// de `MERCADO_CERRADO`: si es el instante de apertura en ISO 8601 (UTC), se
/// agrega "Abre a las HH:MM." en hora de Bogotá. Con cualquier otro valor el
/// detalle se descarta; nunca se muestra tal cual.
String traducirCodigo(String? codigo, {String? detalle}) {
  if (codigo == null) return mensajeGenerico;

  final regla = _reglaDeRiesgo.firstMatch(codigo);
  if (regla != null) return _mensajeDeRegla('RR-${regla.group(1)}');

  final mensaje = mensajesPorCodigo[codigo];
  if (mensaje == null) return mensajeGenerico;

  if (codigo == 'MERCADO_CERRADO') {
    final apertura = detalle == null ? null : DateTime.tryParse(detalle.trim());
    if (apertura != null) {
      return '$mensaje Abre a las ${formatearHora(apertura)}.';
    }
  }
  return mensaje;
}

/// Mensaje en español para cualquier error capturado.
///
/// Reconoce [ErrorDeNegocio], la [PostgrestException] que devuelve una RPC
/// cuando la base lanza `raise exception '<CODIGO>'` (el código viaja en
/// `message`) y el [FalloDeIngreso] ya clasificado por el repositorio de
/// ingreso (docs/04 §11). Todo lo demás —red, Auth sin clasificar,
/// excepciones desconocidas— muestra el mensaje genérico, nunca su texto.
String traducirError(Object? error) {
  if (error is FalloDeIngreso) return error.mensaje;
  final negocio = _comoErrorDeNegocio(error);
  if (negocio == null) return mensajeGenerico;
  return traducirCodigo(negocio.codigo, detalle: negocio.detalle);
}

ErrorDeNegocio? _comoErrorDeNegocio(Object? error) {
  if (error is ErrorDeNegocio) return error;
  if (error is PostgrestException) {
    final codigo = error.message.trim();
    if (!_formaDeCodigo.hasMatch(codigo)) return null;
    return ErrorDeNegocio(codigo, detalle: error.details?.toString());
  }
  return null;
}

String _mensajeDeRegla(String id) {
  final texto = reglasDeRiesgo[id];
  if (texto == null) return 'No se cumple la regla de riesgo $id.';
  return 'No se cumple la regla $id. $texto';
}

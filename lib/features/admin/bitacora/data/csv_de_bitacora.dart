import 'bitacora_repositorio.dart';

/// Neutraliza texto que una hoja de cálculo podría interpretar como fórmula.
String _celda(String? dato) {
  final valor = dato ?? '';
  final protegido = RegExp(r'^\s*[=+\-@]|^[\t\r\n]').hasMatch(valor)
      ? "'$valor"
      : valor;
  return '"${protegido.replaceAll('"', '""')}"';
}

Future<String> csvDeBitacora(
  LeerBitacora leer,
  FiltrosDeBitacora filtros,
) async {
  final csv = StringBuffer(
    '\uFEFFid,momento_utc,actor_id,accion,entidad,entidad_id\r\n',
  );
  int? cursor;
  while (true) {
    final pagina = await leer(filtros, antesDe: cursor);
    for (final registro in pagina) {
      csv
        ..write(
          [
            registro.id.toString(),
            registro.momento.toUtc().toIso8601String(),
            registro.actor ?? 'Sistema',
            registro.accion,
            registro.entidad,
            registro.entidadId,
          ].map(_celda).join(','),
        )
        ..write('\r\n');
    }
    if (pagina.length < tamanoPaginaDeBitacora) return csv.toString();
    cursor = pagina.last.id;
  }
}

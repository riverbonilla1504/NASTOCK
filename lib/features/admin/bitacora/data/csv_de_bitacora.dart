import '../../../../core/exportacion/celda_csv.dart';
import 'bitacora_repositorio.dart';

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
          ].map(celdaCsv).join(','),
        )
        ..write('\r\n');
    }
    if (pagina.length < tamanoPaginaDeBitacora) return csv.toString();
    cursor = pagina.last.id;
  }
}

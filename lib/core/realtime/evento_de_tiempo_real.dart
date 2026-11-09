/// Lo que llega por un canal de tiempo real (docs/09 §4).
///
/// Los eventos avisan, no informan: un evento de entidad lleva solo la tabla,
/// el identificador, la versión y el estado; el dato se lee por la API, donde
/// aplica RLS. La excepción son los precios (`cotizaciones` en `mercado`).
library;

/// Un mensaje de broadcast de un canal.
class EventoDeTiempoReal {
  const EventoDeTiempoReal({
    required this.canal,
    required this.evento,
    this.carga = const {},
  });

  /// Arma el evento con el mensaje que entrega Realtime
  /// (`{event, type, payload}`). Una carga que no es un mapa queda vacía.
  factory EventoDeTiempoReal.desdeMensaje(
    String canal,
    Map<String, dynamic> mensaje,
  ) {
    final carga = mensaje['payload'];
    return EventoDeTiempoReal(
      canal: canal,
      evento: mensaje['event'] as String? ?? '',
      carga: carga is Map ? Map<String, dynamic>.from(carga) : const {},
    );
  }

  /// El canal por el que llegó, por ejemplo `usuario:{uuid}`.
  final String canal;

  /// El nombre del evento: `sugerencia`, `cotizaciones`, `sesion_revocada`…
  final String evento;

  /// El contenido del evento, tal como lo publicó la base de datos.
  final Map<String, dynamic> carga;

  /// La carga como evento de entidad: `{tabla, id, version, estado}`.
  EventoDeEntidad get entidad => EventoDeEntidad.desdeCarga(carga);
}

/// La carga de un evento de entidad (`private.carga_evento`, docs/09 §4).
class EventoDeEntidad {
  const EventoDeEntidad({this.tabla, this.id, this.version, this.estado});

  factory EventoDeEntidad.desdeCarga(Map<String, dynamic> carga) {
    final id = carga['id'];
    final version = carga['version'];
    return EventoDeEntidad(
      tabla: carga['tabla'] as String?,
      id: id?.toString(),
      version: version is num ? version.toInt() : null,
      estado: carga['estado'] as String?,
    );
  }

  final String? tabla;

  /// El identificador del registro, como texto: casi todas las tablas usan
  /// uuid, pero `parametros` usa su clave.
  final String? id;

  /// La versión del registro. Nula si la tabla no tiene versión.
  final int? version;

  final String? estado;
}

/// Estado de la conexión en vivo sobre el contenido (docs/08 §9.4, FR-189).
///
/// ```
/// reconectando → barra "Reconectando…" y los datos se ven atenuados
/// sin conexión → barra "Sin conexión" (los botones de decisión los
///                deshabilita cada pantalla con decisionesHabilitadasProvider)
/// conectado    → nada
/// ```
///
/// Solo compone componentes y tokens existentes: el aviso en línea y los
/// espacios del tema (D-67). No navega ni lee providers: recibe el estado.
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../core/realtime/estado_conexion.dart';
import 'avisos.dart';

/// El texto de la barra para [estado], o `null` si no hay nada que avisar.
String? textoDeConexion(EstadoConexion estado) => switch (estado) {
  EstadoConexion.conectado => null,
  EstadoConexion.reconectando => 'Reconectando…',
  EstadoConexion.sinConexion => 'Sin conexión',
};

/// Cuánto se atenúan los datos mientras se reconecta.
const double opacidadReconectando = 0.5;

/// La barra y el contenido de la pantalla, uno bajo el otro.
///
/// La barra ocupa la franja de arriba (la del reloj del teléfono), así que
/// mientras se ve, [hijo] ya no deja ese espacio. El árbol tiene siempre la
/// misma forma: [hijo] conserva su estado al aparecer o desaparecer la barra.
class ContenidoConConexion extends StatelessWidget {
  const ContenidoConConexion({
    required this.estado,
    required this.hijo,
    super.key,
  });

  final EstadoConexion estado;
  final Widget hijo;

  /// Clave de la barra, para las pruebas.
  static const Key claveDeLaBarra = ValueKey('barra-de-conexion');

  @override
  Widget build(BuildContext context) {
    final texto = textoDeConexion(estado);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (texto == null)
          const SizedBox.shrink()
        else
          SafeArea(
            bottom: false,
            child: Padding(
              key: claveDeLaBarra,
              padding: const EdgeInsets.fromLTRB(
                Espacio.x3,
                Espacio.x2,
                Espacio.x3,
                Espacio.x2,
              ),
              child: AvisoEnLinea(
                tipo: estado == EstadoConexion.sinConexion
                    ? TipoAviso.advertencia
                    : TipoAviso.informacion,
                mensaje: texto,
              ),
            ),
          ),
        Expanded(
          child: AnimatedOpacity(
            opacity: estado == EstadoConexion.reconectando
                ? opacidadReconectando
                : 1,
            duration: Duracion.estado,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: texto != null,
              child: hijo,
            ),
          ),
        ),
      ],
    );
  }
}

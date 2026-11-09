/// Cascarón de navegación: el menú del rol de la sesión (docs/03 §3, FR-021).
///
/// En teléfono, la isla de navegación (`BarraDePestanas`); en ventanas anchas
/// (desde [anchoMinimoDelRiel]) el riel de navegación, con los mismos destinos
/// en el mismo orden y sin la isla (DESIGN.md). Los destinos salen de
/// `destinosDeRol`: cada rol ve solo los suyos, y los de otro rol no aparecen
/// deshabilitados, no aparecen.
///
/// Encima del contenido muestra el estado de la conexión en vivo ("Reconectando…"
/// y datos atenuados, FR-189).
///
/// No navega por sí mismo: avisa la ruta elegida con [alElegirRuta], así se
/// prueba sin enrutador. Forma en
/// `specs/006-navegacion-segun-el-rol/forma-de-las-pantallas.md`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/realtime/tiempo_real_provider.dart';
import '../features/auth/presentation/acceso_de_sesion_provider.dart';
import '../shared/widgets/barra_de_conexion.dart';
import '../shared/widgets/barra_de_pestanas.dart';
import 'destinos.dart';
import 'rutas.dart';

/// Ancho desde el cual el menú pasa de la isla al riel: la clase "expandida" de
/// Material 3. Entre 600 y 840 dp se sigue viendo la isla.
const double anchoMinimoDelRiel = 840;

/// La clave de un destino en las pruebas: la misma en la isla y en el riel.
Key claveDeDestino(String ruta) => ValueKey('destino-$ruta');

class CascaronDeNavegacion extends ConsumerWidget {
  const CascaronDeNavegacion({
    required this.rutaActual,
    required this.hijo,
    required this.alElegirRuta,
    super.key,
  });

  /// La ruta que muestra [hijo] (`/admin/usuarios` marca Administración).
  final String rutaActual;

  /// La pantalla del destino actual.
  final Widget hijo;

  final ValueChanged<String> alElegirRuta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(accesoDeSesionProvider).rol;
    // La barra "Reconectando…" y los datos atenuados valen para toda pantalla
    // en vivo (FR-189).
    final contenido = ContenidoConConexion(
      estado: ref.watch(conexionProvider),
      hijo: hijo,
    );
    final destinos = destinosDeRol(rol);
    final indice = destinos.indexWhere(
      (d) => Rutas.esRutaDe(rutaActual, d.ruta),
    );
    // Una ruta sin destino en el menú (no debería llegar aquí) no marca nada.
    final actual = indice < 0 ? 0 : indice;

    void elegir(int i) {
      if (i != actual) alElegirRuta(destinos[i].ruta);
    }

    if (MediaQuery.sizeOf(context).width >= anchoMinimoDelRiel) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: actual,
              onDestinationSelected: elegir,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinos)
                  NavigationRailDestination(
                    icon: KeyedSubtree(
                      key: claveDeDestino(d.ruta),
                      child: Icon(d.icono),
                    ),
                    label: Text(d.etiqueta),
                  ),
              ],
            ),
            Expanded(child: contenido),
          ],
        ),
      );
    }

    return Scaffold(
      // El contenido pasa por detrás de la isla (DESIGN.md): las pantallas
      // dejan al final de sus listas el relleno inferior de `MediaQuery`.
      extendBody: true,
      body: contenido,
      bottomNavigationBar: BarraDePestanas(
        actual: actual,
        alElegir: elegir,
        pestanas: [
          for (final d in destinos)
            Pestana(
              etiqueta: d.etiqueta,
              icono: d.icono,
              clave: claveDeDestino(d.ruta),
            ),
        ],
      ),
    );
  }
}

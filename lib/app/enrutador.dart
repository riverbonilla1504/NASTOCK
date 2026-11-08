/// Enrutador de la app (go_router, docs/05 §9.3).
///
/// HU-005 agrega `/ingreso` y la guarda por sesión: sin sesión, todo lleva a
/// `/ingreso`; con sesión, `/ingreso` lleva a `/inicio`. Las demás guardas de
/// 05 §9.3 (`/cuenta-suspendida`, `/admin/*`, `/riesgo/*` por estado y rol) las
/// agrega HU-006 sobre este mismo enrutador. El catálogo de componentes
/// (`/catalogo`) solo se registra en debug o con `MODO_PRUEBAS` (HU-116) y
/// queda fuera de la guarda: es una herramienta, no una pantalla de la app.
library;

import 'package:flutter/foundation.dart' show Listenable, ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pagina_de_ingreso.dart';
import '../features/auth/presentation/sesion_provider.dart';
import 'catalogo/pagina_catalogo.dart';
import 'pagina_inicio.dart';
import 'rutas.dart';

export 'rutas.dart';

/// La ruta a la que hay que ir según la sesión, o `null` si se queda donde está.
///
/// [ruta] es la ruta que se pidió. Pura, para probarla sin pantallas.
String? redirigirSegunSesion({required String ruta, required bool haySesion}) {
  // El catálogo de componentes no pide sesión.
  if (ruta == RutasCatalogo.inicio ||
      ruta.startsWith('${RutasCatalogo.inicio}/')) {
    return null;
  }
  if (!haySesion && ruta != Rutas.ingreso) return Rutas.ingreso;
  if (haySesion && ruta == Rutas.ingreso) return Rutas.inicio;
  return null;
}

/// [conCatalogo] registra las rutas del catálogo de componentes. Con
/// [haySesion] la guarda por sesión está activa; [refrescarCon] avisa cuándo
/// volver a evaluarla (al ingresar y al cerrar sesión). Sin [haySesion] no hay
/// guarda (las pruebas de otras pantallas montan el enrutador sin ella).
GoRouter crearEnrutador({
  bool conCatalogo = false,
  bool Function()? haySesion,
  Listenable? refrescarCon,
}) {
  return GoRouter(
    initialLocation: Rutas.inicio,
    refreshListenable: refrescarCon,
    redirect: haySesion == null
        ? null
        : (context, state) => redirigirSegunSesion(
            ruta: state.matchedLocation,
            haySesion: haySesion(),
          ),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => Rutas.inicio),
      GoRoute(
        path: Rutas.ingreso,
        builder: (context, state) => const PaginaDeIngreso(),
      ),
      GoRoute(
        path: Rutas.inicio,
        builder: (context, state) => const PaginaInicio(),
      ),
      if (conCatalogo) ...rutasDelCatalogo(),
    ],
  );
}

final enrutadorProvider = Provider<GoRouter>((ref) {
  // La guarda se vuelve a evaluar cada vez que la sesión cambia.
  final cambioDeSesion = ValueNotifier<int>(0);
  ref.listen(sesionProvider, (_, _) => cambioDeSesion.value++);

  final enrutador = crearEnrutador(
    conCatalogo: ref.watch(catalogoDisponibleProvider),
    haySesion: () => ref.read(sesionProvider) != null,
    refrescarCon: cambioDeSesion,
  );
  ref.onDispose(() {
    enrutador.dispose();
    cambioDeSesion.dispose();
  });
  return enrutador;
});

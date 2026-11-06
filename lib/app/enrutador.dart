/// Enrutador de la app (go_router, docs/05 §9.3).
///
/// Por ahora solo existe la ruta de inicio. Las guardas por sesión, estado y
/// rol (`/ingreso`, `/cuenta-suspendida`, `/admin/*`, `/riesgo/*`) las agrega
/// la historia de ingreso (HU-005) sobre este mismo enrutador.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pagina_inicio.dart';

/// Rutas de la app. Cada historia agrega las suyas aquí.
abstract final class Rutas {
  static const String inicio = '/inicio';
}

GoRouter crearEnrutador() {
  return GoRouter(
    initialLocation: Rutas.inicio,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => Rutas.inicio),
      GoRoute(
        path: Rutas.inicio,
        builder: (context, state) => const PaginaInicio(),
      ),
    ],
  );
}

final enrutadorProvider = Provider<GoRouter>((ref) {
  final enrutador = crearEnrutador();
  ref.onDispose(enrutador.dispose);
  return enrutador;
});

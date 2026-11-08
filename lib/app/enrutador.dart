/// Enrutador de la app (go_router, docs/05 §9.3).
///
/// Guardas (FR-021; la política está en `acceso_por_rol.dart`):
///
/// ```
/// sin sesión                               → /ingreso
/// sesión con app_estado distinto de activo → /cuenta-suspendida
/// ruta de otro rol, o que no existe        → /inicio
/// ```
///
/// Las pantallas del menú cuelgan de un `ShellRoute` con el cascarón de
/// navegación (isla o riel). `/ingreso` y `/cuenta-suspendida` van fuera de él.
/// Los destinos y los roles que los ven están en `destinos.dart`; las rutas de
/// pantallas que no existen en el MVP corto (como `/riesgo/*`) no se crean.
/// El catálogo de componentes (`/catalogo`) solo se registra en debug o con
/// `MODO_PRUEBAS` (HU-116) y queda fuera de la guarda.
library;

import 'package:flutter/foundation.dart' show Listenable, ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/acceso_de_sesion_provider.dart';
import '../features/auth/presentation/pagina_cuenta_suspendida.dart';
import '../features/auth/presentation/pagina_de_ingreso.dart';
import 'acceso_por_rol.dart';
import 'cascaron_de_navegacion.dart';
import 'catalogo/pagina_catalogo.dart';
import 'destinos.dart';
import 'pagina_marcador.dart';
import 'rutas.dart';

export 'rutas.dart';

/// [conCatalogo] registra las rutas del catálogo de componentes. Con
/// [accesoDeSesion] las guardas están activas; [refrescarCon] avisa cuándo
/// volver a evaluarlas (al ingresar, al cerrar sesión y cuando el token trae
/// otro rol u otro estado). Sin [accesoDeSesion] no hay guardas: las pruebas de
/// otras pantallas montan el enrutador sin ellas.
GoRouter crearEnrutador({
  bool conCatalogo = false,
  AccesoDeSesion Function()? accesoDeSesion,
  Listenable? refrescarCon,
}) {
  return GoRouter(
    initialLocation: Rutas.inicio,
    refreshListenable: refrescarCon,
    redirect: accesoDeSesion == null
        ? null
        : (context, state) {
            final acceso = accesoDeSesion();
            return redirigirSegunAcceso(
              ruta: state.matchedLocation,
              haySesion: acceso.haySesion,
              claims: acceso.claims,
            );
          },
    // Una ruta que no existe (un enlace viejo, `/riesgo/...` en el MVP corto)
    // lleva al inicio, como manda docs/03 §3.
    onException: (context, state, router) => router.go(Rutas.inicio),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => Rutas.inicio),
      GoRoute(
        path: Rutas.ingreso,
        builder: (context, state) => const PaginaDeIngreso(),
      ),
      GoRoute(
        path: Rutas.cuentaSuspendida,
        builder: (context, state) => const PaginaCuentaSuspendida(),
      ),
      ShellRoute(
        builder: (context, state, hijo) => CascaronDeNavegacion(
          rutaActual: state.matchedLocation,
          hijo: hijo,
          alElegirRuta: context.go,
        ),
        routes: [
          for (final destino in destinosDelMvp)
            GoRoute(
              path: destino.ruta,
              builder: (context, state) =>
                  destino.pantalla?.call(context) ??
                  PaginaMarcador(etiqueta: destino.etiqueta),
              routes: destino.subrutas,
            ),
        ],
      ),
      if (conCatalogo) ...rutasDelCatalogo(),
    ],
  );
}

final enrutadorProvider = Provider<GoRouter>((ref) {
  // Las guardas se vuelven a evaluar cada vez que el acceso de la sesión
  // cambia: ingreso, cierre de sesión y un token renovado con otro rol o estado.
  final cambioDeAcceso = ValueNotifier<int>(0);
  ref.listen(accesoDeSesionProvider, (_, _) => cambioDeAcceso.value++);

  final enrutador = crearEnrutador(
    conCatalogo: ref.watch(catalogoDisponibleProvider),
    accesoDeSesion: () => ref.read(accesoDeSesionProvider),
    refrescarCon: cambioDeAcceso,
  );
  ref.onDispose(() {
    enrutador.dispose();
    cambioDeAcceso.dispose();
  });
  return enrutador;
});

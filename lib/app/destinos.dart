/// Destinos del menú del MVP corto y quién los ve (docs/03 §3, docs/14 §4.1).
///
/// El enrutador, el menú y las guardas leen de aquí. Cuando una historia
/// construye la pantalla de su sección, solo reemplaza el [Destino.pantalla] de
/// su línea (y agrega sus subrutas bajo la misma ruta base): mientras sea
/// `null`, el enrutador monta un marcador.
///
/// Nueva orden manual no es un destino del menú: la isla de navegación admite
/// cuatro destinos y la acción va en la tarjeta de detalle (DESIGN.md); su ruta
/// y su regla de acceso las crea la historia de la orden manual.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/perfil/perfil.dart';
import '../features/admin/presentation/pagina_administracion.dart';
import '../features/admin/capital/presentation/pagina_capital.dart';
import '../features/admin/parametros/presentation/pagina_parametros.dart';
import '../features/admin/usuarios/presentation/pagina_invitaciones.dart';
import '../features/cupo/presentation/pagina_mi_cupo.dart';
import '../features/oportunidades/presentation/pagina_oportunidades.dart';
import 'pagina_inicio.dart';
import 'rutas.dart';

class Destino {
  const Destino({
    required this.ruta,
    required this.etiqueta,
    required this.icono,
    required this.roles,
    this.pantalla,
    this.subrutas = const [],
  });

  /// Ruta base. Las subrutas (`/admin/usuarios`) son del mismo destino.
  final String ruta;

  /// Texto del menú.
  final String etiqueta;
  final IconData icono;

  /// Roles que lo ven en el menú y pueden abrir su ruta.
  final Set<RolApp> roles;

  /// La pantalla del destino; `null` mientras su historia no la construye (el
  /// enrutador monta un marcador con [etiqueta]).
  final WidgetBuilder? pantalla;

  /// Subrutas del destino, con la ruta relativa (`GoRoute(path: 'usuarios')`
  /// bajo `/admin`). La guarda de la ruta base ya las cubre: las historias
  /// posteriores solo las agregan aquí.
  final List<GoRoute> subrutas;
}

final Set<RolApp> _todos = RolApp.values.toSet();

/// Destinos del MVP corto, en el orden del menú.
final List<Destino> destinosDelMvp = [
  Destino(
    ruta: Rutas.inicio,
    etiqueta: 'Mercado',
    icono: Icons.show_chart,
    roles: _todos,
    pantalla: (_) => const PaginaInicio(),
  ),
  Destino(
    ruta: Rutas.oportunidades,
    etiqueta: 'Oportunidades',
    icono: Icons.query_stats,
    roles: _todos,
    pantalla: (_) => const PaginaOportunidades(),
  ),
  Destino(
    ruta: Rutas.cupo,
    etiqueta: 'Mi cupo',
    icono: Icons.account_balance_wallet_outlined,
    roles: {RolApp.usuario},
    pantalla: (_) => const PaginaMiCupo(),
  ),
  Destino(
    ruta: Rutas.alertas,
    etiqueta: 'Alertas',
    icono: Icons.notifications_none,
    roles: _todos,
  ),
  Destino(
    ruta: Rutas.admin,
    etiqueta: 'Administración',
    icono: Icons.admin_panel_settings_outlined,
    roles: {RolApp.administrador},
    pantalla: (_) => const PaginaAdministracion(),
    subrutas: [
      GoRoute(
        path: 'usuarios',
        builder: (context, state) => const PaginaInvitaciones(),
      ),
      GoRoute(
        path: 'capital',
        builder: (context, state) => const PaginaCapital(),
      ),
      GoRoute(
        path: 'parametros',
        builder: (context, state) => const PaginaParametros(),
      ),
    ],
  ),
];

/// Si la sección [ruta] de Administración (`/admin/capital`…) ya tiene
/// pantalla. Cada historia de E-11 registra su subruta en [destinosDelMvp] y
/// con eso su entrada de Administración deja de estar deshabilitada.
bool seccionDeAdministracionDisponible(String ruta) {
  for (final destino in destinosDelMvp) {
    if (destino.ruta != Rutas.admin) continue;
    for (final subruta in destino.subrutas) {
      if ('${Rutas.admin}/${subruta.path}' == ruta) return true;
    }
  }
  return false;
}

/// El menú de [rol], en orden. Sin rol (o con un rol desconocido) solo queda
/// Mercado, que es de todos y nunca deja a nadie sin a dónde ir.
List<Destino> destinosDeRol(RolApp? rol) => [
  for (final destino in destinosDelMvp)
    if (rol == null
        ? destino.ruta == Rutas.inicio
        : destino.roles.contains(rol))
      destino,
];

/// El destino al que pertenece [ruta] (la base o una subruta), o `null`.
Destino? destinoDeRuta(String ruta) {
  for (final destino in destinosDelMvp) {
    if (Rutas.esRutaDe(ruta, destino.ruta)) return destino;
  }
  return null;
}

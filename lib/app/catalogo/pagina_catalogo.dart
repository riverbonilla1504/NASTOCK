/// Catálogo de componentes del sistema de diseño (HU-116, CA-10).
///
/// Solo existe en debug o con `MODO_PRUEBAS`: el enrutador no registra sus
/// rutas en una compilación de producción. Los datos son de ejemplo.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/configuracion/entorno.dart';
import '../tema.dart';
import 'escena_mercado.dart';
import 'pagina_componentes.dart';

/// Rutas del catálogo.
abstract final class RutasCatalogo {
  static const String inicio = '/catalogo';
  static const String mercado = '/catalogo/mercado';
  static const String componentes = '/catalogo/componentes';
}

/// El catálogo existe en debug o con `MODO_PRUEBAS` (CA-10).
final catalogoDisponibleProvider = Provider<bool>(
  (ref) => kDebugMode || ref.watch(entornoProvider).modoPruebas,
);

/// Si el catálogo se ve en oscuro (solo dentro del catálogo).
final catalogoOscuroProvider = NotifierProvider<_CatalogoOscuro, bool>(
  _CatalogoOscuro.new,
);

class _CatalogoOscuro extends Notifier<bool> {
  @override
  bool build() => false;

  void alternar() => state = !state;
}

/// Rutas del catálogo para el enrutador. `?tema=oscuro` abre en oscuro y, en
/// la escena, `?aviso=1` muestra el aviso temporal al abrir (para capturas).
List<RouteBase> rutasDelCatalogo() => [
  GoRoute(
    path: RutasCatalogo.inicio,
    builder: (context, state) =>
        _ConTema(estado: state, child: const PaginaCatalogo()),
    routes: [
      GoRoute(
        path: 'mercado',
        builder: (context, state) => _ConTema(
          estado: state,
          child: EscenaMercado(
            mostrarAviso: state.uri.queryParameters['aviso'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: 'componentes',
        builder: (context, state) =>
            _ConTema(estado: state, child: const PaginaComponentes()),
      ),
    ],
  ),
];

class _ConTema extends ConsumerWidget {
  const _ConTema({required this.estado, required this.child});

  final GoRouterState estado;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedido = estado.uri.queryParameters['tema'] == 'oscuro';
    final oscuro = ref.watch(catalogoOscuroProvider) != pedido;
    return Theme(data: oscuro ? crearTemaOscuro() : crearTema(), child: child);
  }
}

/// Interruptor claro/oscuro para la barra del catálogo.
class InterruptorDeTema extends ConsumerWidget {
  const InterruptorDeTema({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: oscuro ? 'Ver en claro' : 'Ver en oscuro',
      onPressed: () => ref.read(catalogoOscuroProvider.notifier).alternar(),
      icon: Icon(oscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}

class PaginaCatalogo extends StatelessWidget {
  const PaginaCatalogo({super.key});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de componentes'),
        actions: const [InterruptorDeTema()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Espacio.x4),
        children: [
          Text(
            'Sistema de diseño Almanaque (DESIGN.md). Datos de ejemplo.',
            style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
          ),
          const SizedBox(height: Espacio.x4),
          _Entrada(
            titulo: 'Escena: Mercado',
            detalle:
                'Barra con la franja de la jornada, cotizaciones, '
                'aviso temporal y barra de pestañas.',
            ruta: RutasCatalogo.mercado,
          ),
          const SizedBox(height: Espacio.x3),
          _Entrada(
            titulo: 'Componentes',
            detalle:
                'Botones, campos, avisos, chips, cifras, gráfica, '
                'calendario y estados.',
            ruta: RutasCatalogo.componentes,
          ),
        ],
      ),
    );
  }
}

class _Entrada extends StatelessWidget {
  const _Entrada({
    required this.titulo,
    required this.detalle,
    required this.ruta,
  });

  final String titulo;
  final String detalle;
  final String ruta;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        title: Text(titulo),
        subtitle: Text(detalle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(ruta),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Espacio.x4,
          vertical: Espacio.x1,
        ),
        titleTextStyle: textos.titleMedium,
      ),
    );
  }
}

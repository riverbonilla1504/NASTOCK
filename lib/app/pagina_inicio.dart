/// Pantalla de inicio de los tres roles: Mercado (HU-030). Conserva arriba el
/// aviso de configuración y el acceso al catálogo del esqueleto.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/configuracion/entorno.dart';
import '../features/mercado/presentation/pagina_mercado.dart';
import 'catalogo/pagina_catalogo.dart';

class PaginaInicio extends ConsumerWidget {
  const PaginaInicio({super.key});

  static const Key claveDeAvisoSinConfiguracion = Key(
    'aviso-sin-configuracion',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final entorno = ref.watch(entornoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('RiTech Inversiones')),
      body: PaginaMercado(
        pie: [
          if (!entorno.supabaseConfigurado) ...[
            const SizedBox(height: 24),
            Text(
              'Falta configurar la conexión: ejecuta la app con '
              '--dart-define=SUPABASE_URL=… y '
              '--dart-define=SUPABASE_PUBLISHABLE_KEY=…',
              key: claveDeAvisoSinConfiguracion,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (ref.watch(catalogoDisponibleProvider)) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.push(RutasCatalogo.inicio),
              child: const Text('Catálogo de componentes'),
            ),
          ],
        ],
      ),
    );
  }
}

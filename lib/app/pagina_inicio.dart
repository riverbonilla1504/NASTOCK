/// Pantalla inicial del esqueleto. Cada historia reemplaza o enriquece esta
/// página con la suya (ingreso, resumen del fondo, etc.).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/configuracion/entorno.dart';
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 64,
                  color: tema.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Plataforma de inversión asistida por IA',
                  style: tema.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'MVP en paper trading: una persona siempre aprueba.',
                  style: tema.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
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
          ),
        ),
      ),
    );
  }
}

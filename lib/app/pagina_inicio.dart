/// Pantalla de inicio de los tres roles: Mercado (HU-030). Conserva arriba el
/// aviso de configuración. El catálogo de componentes no se enlaza desde la
/// app: solo se llega por su ruta `/catalogo` (debug o `MODO_PRUEBAS`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/configuracion/entorno.dart';
import '../features/mercado/presentation/pagina_mercado.dart';
import '../shared/widgets/barra_superior.dart';
import 'rutas.dart';

class PaginaInicio extends ConsumerWidget {
  const PaginaInicio({super.key});

  static const Key claveDeAvisoSinConfiguracion = Key(
    'aviso-sin-configuracion',
  );

  /// El acceso a Fondo, arriba a la derecha.
  static const Key claveDelAccesoAlFondo = Key('acceso-al-fondo');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final entorno = ref.watch(entornoProvider);

    return Scaffold(
      appBar: BarraSuperior(
        titulo: 'Mercado',
        acciones: [
          IconButton(
            key: claveDelAccesoAlFondo,
            tooltip: 'Fondo',
            icon: const Icon(Icons.account_balance_outlined),
            onPressed: () => context.push(Rutas.fondo),
          ),
        ],
      ),
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
        ],
      ),
    );
  }
}

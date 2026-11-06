/// Cliente de Supabase (docs/05 §3.1 y §9).
///
/// Es el único punto donde se crea el cliente. Las funcionalidades lo reciben
/// por [clienteSupabaseProvider] en sus repositorios (`data/`), que son los
/// únicos que hablan con Supabase.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../configuracion/entorno.dart';

/// Inicia Supabase con la URL y la llave publicable de [entorno].
///
/// Devuelve `false` sin hacer nada si el entorno no está configurado, para que
/// la app abra igual (y avise) cuando se la ejecuta sin `--dart-define`.
Future<bool> iniciarSupabase([Entorno entorno = Entorno.actual]) async {
  if (!entorno.supabaseConfigurado) return false;
  await Supabase.initialize(
    url: entorno.supabaseUrl,
    publishableKey: entorno.supabaseLlavePublicable,
  );
  return true;
}

/// Cliente de Supabase ya iniciado. Solo se lee si [iniciarSupabase] devolvió
/// `true`; en las pruebas se reemplaza con un repositorio o cliente falso.
final clienteSupabaseProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

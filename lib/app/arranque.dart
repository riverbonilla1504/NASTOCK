/// Arranque de la app: enlaza Flutter, inicia Supabase y monta Riverpod (reiniciable).
library;

import 'package:flutter/widgets.dart';

import '../core/supabase/cliente_supabase.dart';
import 'aplicacion.dart';
import 'raiz_de_providers.dart';

Future<void> arrancar() async {
  WidgetsFlutterBinding.ensureInitialized();
  await iniciarSupabase();
  // La raíz se puede reiniciar entera al cerrar sesión (HU-007, CA-3).
  runApp(const RaizDeProviders(child: Aplicacion()));
}

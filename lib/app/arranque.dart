/// Arranque de la app: enlaza Flutter, inicia Supabase y monta Riverpod.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/cliente_supabase.dart';
import 'aplicacion.dart';

Future<void> arrancar() async {
  WidgetsFlutterBinding.ensureInitialized();
  await iniciarSupabase();
  runApp(const ProviderScope(child: Aplicacion()));
}

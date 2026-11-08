/// La sesión de la app, sobre el estado de autenticación de `supabase_flutter`
/// (docs/04 §8).
///
/// Es síncrona a propósito: el enrutador necesita saber si hay sesión en el
/// primer fotograma para decidir entre `/ingreso` y `/inicio`. Los claims y el
/// perfil de quien tiene la sesión los lee `perfilProvider` (HU-001), no este.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import '../../../core/configuracion/entorno.dart';
import '../data/ingreso_repositorio.dart';

class SesionNotifier extends Notifier<Session?> {
  @override
  Session? build() {
    // Sin Supabase configurado la app abre igual (y avisa): no hay sesión.
    if (!ref.watch(entornoProvider).supabaseConfigurado) return null;

    final repositorio = ref.watch(ingresoRepositorioProvider);
    final suscripcion = repositorio.cambiosDeSesion.listen(
      (sesion) => state = sesion,
    );
    ref.onDispose(suscripcion.cancel);
    return repositorio.sesionActual;
  }
}

/// La sesión actual, o `null` si no hay. Cambia al ingresar, al cerrar sesión
/// y al renovarse el token.
final sesionProvider = NotifierProvider<SesionNotifier, Session?>(
  SesionNotifier.new,
);

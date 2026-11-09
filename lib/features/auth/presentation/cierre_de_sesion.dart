/// Cierre de sesión completo (HU-007, docs/04 §4.5, FR-023).
///
/// Pasos, en este orden:
///
/// 1. Cancelar las suscripciones de tiempo real (los canales del rol).
/// 2. `supabase.auth.signOut()`, que revoca el refresh token, y cerrar también
///    la sesión de `google_sign_in`, para que el siguiente ingreso permita elegir
///    cuenta (`IngresoRepositorio.cerrarSesion`).
///
/// El paso 2 de docs/04 §4.5 (borrar el token de push del dispositivo) es de
/// HU-087 y se agrega allí. Descartar el estado de la sesión anterior lo hace la
/// raíz de providers (`RaizDeProviders`), que quien llama dispara después.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/tiempo_real_provider.dart';
import '../data/ingreso_repositorio.dart';

/// Cuánto se espera a que los canales de tiempo real terminen de cerrarse.
const Duration plazoParaCerrarCanales = Duration(seconds: 3);

/// Cierra la sesión de quien la tiene. Lanza si no pudo cerrar la de Supabase
/// (por ejemplo, sin conexión): la sesión sigue abierta y se puede reintentar.
Future<void> cerrarSesionCompleta(WidgetRef ref) async {
  // Los canales primero: así nada se publica a una sesión que ya se está yendo.
  // `cerrar` es idempotente: al desaparecer la sesión, el provider del gestor
  // lo vuelve a cerrar sin efecto. Con tope de tiempo: cerrar canales usa la red
  // y, sin conexión, no debe impedir que la persona salga.
  await ref
      .read(gestorDeTiempoRealProvider)
      ?.cerrar()
      .timeout(plazoParaCerrarCanales, onTimeout: () {});
  await ref.read(ingresoRepositorioProvider).cerrarSesion();
}

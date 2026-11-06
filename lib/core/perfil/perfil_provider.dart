/// Perfil de la persona que tiene la sesión: claims del token y fila de
/// `perfiles` (docs/03 §4.1, HU-001).
///
/// Es para la interfaz: armar menús y guardas. La seguridad real está en la
/// base de datos (RLS y RPC), que consulta `perfiles` en cada operación.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'perfil.dart';
import 'perfil_repositorio.dart';

/// Los claims y la fila de `perfiles` de quien tiene la sesión. Se vuelve a
/// leer cada vez que la sesión cambia: ingreso, cierre y renovación del token,
/// que es cuando el token trae el rol nuevo.
final perfilProvider = FutureProvider<PerfilDeSesion>((ref) async {
  final repositorio = ref.watch(perfilRepositorioProvider);

  final suscripcion = repositorio.cambiosDeSesion.listen(
    (_) => ref.invalidateSelf(),
  );
  ref.onDispose(suscripcion.cancel);

  final claims = repositorio.leerClaims();
  final fila = await repositorio.leerPerfilPropio();
  return PerfilDeSesion(claims: claims, fila: fila);
});

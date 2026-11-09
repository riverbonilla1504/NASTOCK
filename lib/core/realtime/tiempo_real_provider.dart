/// Providers del tiempo real: los canales del rol, el gestor y la conexión
/// (docs/08 §9.1, docs/09 §7).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/acceso_de_sesion_provider.dart';
import '../../features/auth/presentation/sesion_provider.dart';
import '../perfil/perfil.dart';
import 'canales.dart';
import 'estado_conexion.dart';
import 'fuente_de_tiempo_real.dart';
import 'gestor_de_tiempo_real.dart';

/// Quién abre canales: la persona con la sesión iniciada y su rol.
///
/// Se compara por valor: el token se renueva cada ~15 minutos con otro objeto
/// de sesión y eso no debe cerrar ni volver a abrir los canales (docs/09 §7).
/// Cambia al ingresar, al cerrar sesión y cuando un token renovado trae otro
/// rol (`perfil_actualizado`, HU-011).
class SuscripcionesDeRol {
  const SuscripcionesDeRol({required this.idUsuario, required this.rol});

  final String idUsuario;
  final RolApp rol;

  @override
  bool operator ==(Object other) =>
      other is SuscripcionesDeRol &&
      other.idUsuario == idUsuario &&
      other.rol == rol;

  @override
  int get hashCode => Object.hash(idUsuario, rol);
}

/// A quién le toca abrir canales, o `null` sin sesión o con una cuenta que no
/// está activa (la base de datos tampoco le entregaría canales).
final suscripcionesDeRolProvider = Provider<SuscripcionesDeRol?>((ref) {
  final sesion = ref.watch(sesionProvider);
  final acceso = ref.watch(accesoDeSesionProvider);
  final rol = acceso.rol;
  if (sesion == null || !acceso.activo || rol == null) return null;
  return SuscripcionesDeRol(idUsuario: sesion.user.id, rol: rol);
});

/// El gestor de la sesión actual, o `null` sin sesión. Abre los canales del
/// rol al iniciar sesión y los cierra al cerrarla (docs/09 §7). Alguien debe
/// observarlo para que se abra: `ActivadorDeTiempoReal`.
final gestorDeTiempoRealProvider = Provider<GestorDeTiempoReal?>((ref) {
  final quien = ref.watch(suscripcionesDeRolProvider);
  if (quien == null) return null;
  final gestor = GestorDeTiempoReal(
    ref.watch(fuenteDeTiempoRealProvider),
    canalesDeRol(quien.rol, quien.idUsuario),
  );
  ref.onDispose(() => unawaited(gestor.cerrar()));
  return gestor;
});

/// `conexionProvider` (docs/08 §9.1): `conectado`, `reconectando` o
/// `sinConexion`. Sin sesión no hay conexión que vigilar: `conectado`.
class ConexionNotifier extends Notifier<EstadoConexion> {
  @override
  EstadoConexion build() {
    final gestor = ref.watch(gestorDeTiempoRealProvider);
    if (gestor == null) return EstadoConexion.conectado;
    final suscripcion = gestor.estados.listen((estado) => state = estado);
    ref.onDispose(suscripcion.cancel);
    return gestor.estado;
  }
}

final conexionProvider = NotifierProvider<ConexionNotifier, EstadoConexion>(
  ConexionNotifier.new,
);

/// Si los botones de decisión se pueden usar: sin conexión quedan
/// deshabilitados (FR-189, docs/08 §9.4). El servidor igual valida cada
/// decisión.
final decisionesHabilitadasProvider = Provider<bool>(
  (ref) => ref.watch(conexionProvider) != EstadoConexion.sinConexion,
);

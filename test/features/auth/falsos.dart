import 'dart:async';

import 'package:inversiones/core/errores/fallo_de_ingreso.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/auth/domain/resultado_de_ingreso.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session, User;

/// Una sesión cualquiera, solo para probar quién tiene sesión y quién no.
Session sesionDePrueba([String id = 'usuario-1']) => Session(
  accessToken: 'token-$id',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-11-08T00:00:00Z',
  ),
);

/// Repositorio de ingreso en memoria: la prueba decide qué responde cada
/// ingreso y cuándo.
class IngresoRepositorioFalso implements IngresoRepositorio {
  /// Si no es nulo, el siguiente ingreso lo lanza.
  Object? error;

  /// Si no es nulo, el siguiente ingreso espera a que la prueba lo complete.
  Completer<ResultadoDeIngreso>? pendiente;

  ResultadoDeIngreso resultado = ResultadoDeIngreso.exito;
  int ingresosConGoogle = 0;
  final List<(String, String)> ingresosConCorreo = [];
  bool sesionDeGoogleCerrada = false;

  final StreamController<FalloDeIngreso> fallos = StreamController.broadcast();
  final StreamController<Session?> sesiones = StreamController.broadcast();

  @override
  Session? sesionActual;

  Future<ResultadoDeIngreso> _responder() async {
    if (error != null) throw error!;
    if (pendiente != null) return pendiente!.future;
    return resultado;
  }

  @override
  Future<ResultadoDeIngreso> ingresarConGoogle() {
    ingresosConGoogle++;
    return _responder();
  }

  @override
  Future<ResultadoDeIngreso> ingresarConCorreo(
    String correo,
    String contrasena,
  ) {
    ingresosConCorreo.add((correo, contrasena));
    return _responder();
  }

  @override
  Stream<FalloDeIngreso> get fallosDeRegreso => fallos.stream;

  @override
  Stream<Session?> get cambiosDeSesion => sesiones.stream;

  @override
  Future<void> cerrarSesionDeGoogle() async => sesionDeGoogleCerrada = true;
}

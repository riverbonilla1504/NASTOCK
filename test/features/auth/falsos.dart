import 'dart:async';
import 'dart:convert';

import 'package:inversiones/core/errores/fallo_de_ingreso.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/auth/domain/resultado_de_ingreso.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session, User;

/// Un token con la forma de un JWT y los claims `app_rol` y `app_estado` que
/// agrega el hook de Auth (docs/04 §7). Sin firma: la app no la valida.
String tokenDePrueba({String? rol, String? estado}) {
  String parte(Map<String, Object?> datos) =>
      base64Url.encode(utf8.encode(jsonEncode(datos))).replaceAll('=', '');
  return [
    parte({'alg': 'none', 'typ': 'JWT'}),
    parte({'sub': 'usuario-1', 'app_rol': rol, 'app_estado': estado}),
    'firma',
  ].join('.');
}

/// Una sesión cualquiera, solo para probar quién tiene sesión y quién no. Con
/// [rol] y [estado] el token trae esos claims; sin ellos, es un token sin
/// claims.
Session sesionDePrueba({
  String id = 'usuario-1',
  String? rol,
  String? estado,
  String? email,
}) => Session(
  accessToken: rol == null && estado == null
      ? 'token-$id'
      : tokenDePrueba(rol: rol, estado: estado),
  tokenType: 'bearer',
  user: User(
    id: id,
    email: email,
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
  int cierresDeSesion = 0;

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

  @override
  Future<void> cerrarSesion() async {
    if (error != null) throw error!;
    cierresDeSesion++;
    // Como Supabase: sin sesión y con el aviso del cambio.
    sesionActual = null;
    sesiones.add(null);
  }
}

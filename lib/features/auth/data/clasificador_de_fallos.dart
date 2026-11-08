/// Convierte cualquier excepción de un intento de ingreso en un
/// [FalloDeIngreso] (docs/04 §11, FR-022).
///
/// Reglas, en este orden:
/// 1. Un [FalloDeIngreso] ya clasificado pasa tal cual.
/// 2. Sin conexión: fallo de red de Auth (`AuthRetryableFetchException`), de
///    la plataforma o del ingreso de Google.
/// 3. Cuenta bloqueada: Auth responde con el código `user_banned`.
/// 4. Rechazo del hook "antes de crear usuario" (HU-002): el hook no pone
///    código, solo el mensaje, así que se reconoce por su prefijo y se guarda el
///    texto del servidor para mostrarlo tal cual. Solo se reconoce un mensaje
///    que **empieza** con uno de los prefijos: cualquier otro mensaje del
///    servidor no se muestra.
/// 5. Todo lo demás es inesperado: el detalle va al registro técnico y nunca a
///    la pantalla (CA-6).
library;

import 'dart:async' show TimeoutException;
import 'dart:developer' as developer;

import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInException;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException;

import '../../../core/errores/fallo_de_ingreso.dart';

/// Prefijos de los mensajes del hook, con los textos de `main` (HU-002) y los
/// nuevos (decisión del 2026-11-08), para no depender de cuál migración llegó.
const Map<String, TipoDeFalloDeIngreso> _prefijosDelHook = {
  'Tu correo no tiene una invitación vigente':
      TipoDeFalloDeIngreso.sinInvitacion,
  'Solo se admiten cuentas': TipoDeFalloDeIngreso.dominioNoPermitido,
  'Solo puedes ingresar con tu cuenta de Google':
      TipoDeFalloDeIngreso.proveedorNoPermitido,
};

/// Clasifica [error]. [pila] solo sirve para el registro técnico.
FalloDeIngreso clasificarFalloDeIngreso(Object error, [StackTrace? pila]) {
  if (error is FalloDeIngreso) return error;

  if (_esFalloDeRed(error)) {
    return const FalloDeIngreso(TipoDeFalloDeIngreso.sinConexion);
  }

  if (error is AuthException) {
    if (error.code == 'user_banned' ||
        error.message.toLowerCase().contains('banned')) {
      return const FalloDeIngreso(TipoDeFalloDeIngreso.cuentaSuspendida);
    }
    final mensaje = error.message.trim();
    for (final entrada in _prefijosDelHook.entries) {
      if (mensaje.startsWith(entrada.key)) {
        return FalloDeIngreso(entrada.value, textoDelServidor: mensaje);
      }
    }
  }

  developer.log(
    'Ingreso fallido',
    name: 'auth',
    error: error,
    stackTrace: pila,
  );
  return const FalloDeIngreso(TipoDeFalloDeIngreso.inesperado);
}

bool _esFalloDeRed(Object error) {
  if (error is AuthRetryableFetchException || error is TimeoutException) {
    return true;
  }
  if (error is GoogleSignInException) {
    final descripcion = (error.description ?? '').toLowerCase();
    return descripcion.contains('network') || descripcion.contains('timeout');
  }
  // `dart:io` no existe en web: se reconoce por el nombre del tipo.
  final tipo = error.runtimeType.toString();
  return tipo == 'SocketException' ||
      tipo == 'ClientException' ||
      tipo == '_ClientSocketException';
}

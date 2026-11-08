import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:inversiones/core/errores/fallo_de_ingreso.dart';
import 'package:inversiones/features/auth/data/clasificador_de_fallos.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthApiException, AuthException, AuthRetryableFetchException;

TipoDeFalloDeIngreso _tipo(Object error) =>
    clasificarFalloDeIngreso(error).tipo;

void main() {
  group('cuenta suspendida o de baja (CA-3)', () {
    test('Auth responde con el código user_banned', () {
      expect(
        _tipo(
          const AuthApiException(
            'User is banned',
            statusCode: '403',
            code: 'user_banned',
          ),
        ),
        TipoDeFalloDeIngreso.cuentaSuspendida,
      );
    });

    test('también si solo llega el mensaje', () {
      expect(
        _tipo(const AuthException('User banned until later')),
        TipoDeFalloDeIngreso.cuentaSuspendida,
      );
    });
  });

  group('sin conexión (CA-4)', () {
    test('error de red de Auth', () {
      expect(
        _tipo(AuthRetryableFetchException()),
        TipoDeFalloDeIngreso.sinConexion,
      );
    });

    test('fallos de red de la plataforma y tiempo agotado', () {
      expect(
        _tipo(const SocketException('Failed host lookup')),
        TipoDeFalloDeIngreso.sinConexion,
      );
      expect(
        _tipo(TimeoutException('tardó demasiado')),
        TipoDeFalloDeIngreso.sinConexion,
      );
    });

    test('el ingreso de Google que falla por la red', () {
      expect(
        _tipo(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.unknownError,
            description: 'A network error has occurred',
          ),
        ),
        TipoDeFalloDeIngreso.sinConexion,
      );
    });
  });

  group('rechazos del hook (CA-5)', () {
    test('sin invitación vigente, con el texto que llegó del servidor', () {
      final fallo = clasificarFalloDeIngreso(
        const AuthApiException(
          'Tu correo no tiene una invitación vigente. Pídele una al administrador.',
          statusCode: '403',
        ),
      );

      expect(fallo.tipo, TipoDeFalloDeIngreso.sinInvitacion);
      expect(
        fallo.mensaje,
        'Tu correo no tiene una invitación vigente. Pídele una al administrador.',
      );
    });

    test('dominio no permitido, con la redacción vieja y con la nueva', () {
      for (final texto in [
        'Solo se admiten cuentas corporativas de RiTech.',
        'Solo se admiten cuentas de Google invitadas.',
      ]) {
        final fallo = clasificarFalloDeIngreso(
          AuthApiException(texto, statusCode: '403'),
        );

        expect(fallo.tipo, TipoDeFalloDeIngreso.dominioNoPermitido);
        expect(fallo.mensaje, texto);
      }
    });

    test('proveedor no permitido, con la redacción vieja y con la nueva', () {
      for (final texto in [
        'Solo puedes ingresar con tu cuenta de Google de RiTech.',
        'Solo puedes ingresar con tu cuenta de Google.',
      ]) {
        final fallo = clasificarFalloDeIngreso(
          AuthApiException(texto, statusCode: '403'),
        );

        expect(fallo.tipo, TipoDeFalloDeIngreso.proveedorNoPermitido);
        expect(fallo.mensaje, texto);
      }
    });

    test('un mensaje que no empieza con el prefijo no se reconoce', () {
      final fallo = clasificarFalloDeIngreso(
        const AuthApiException(
          'Error: Tu correo no tiene una invitación vigente.',
          statusCode: '403',
        ),
      );

      expect(fallo.tipo, TipoDeFalloDeIngreso.inesperado);
    });
  });

  group('error inesperado (CA-6)', () {
    test('un mensaje desconocido del servidor no llega a la pantalla', () {
      final fallo = clasificarFalloDeIngreso(
        const AuthApiException(
          'Database error saving new user',
          statusCode: '500',
        ),
      );

      expect(fallo.tipo, TipoDeFalloDeIngreso.inesperado);
      expect(
        fallo.mensaje,
        'No pudimos iniciar tu sesión. Inténtalo de nuevo.',
      );
      expect(fallo.mensaje, isNot(contains('Database')));
    });

    test('cualquier otra excepción', () {
      expect(_tipo(StateError('raro')), TipoDeFalloDeIngreso.inesperado);
      expect(
        _tipo(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.clientConfigurationError,
          ),
        ),
        TipoDeFalloDeIngreso.inesperado,
      );
    });

    test('un fallo ya clasificado pasa tal cual', () {
      const ya = FalloDeIngreso(TipoDeFalloDeIngreso.sinConexion);

      expect(identical(clasificarFalloDeIngreso(ya), ya), isTrue);
    });
  });
}

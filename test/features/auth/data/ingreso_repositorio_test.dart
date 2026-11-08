import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/errores/fallo_de_ingreso.dart';
import 'package:inversiones/features/auth/data/google_nativo.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/auth/domain/resultado_de_ingreso.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthApiException,
        AuthChangeEvent,
        AuthRetryableFetchException,
        AuthState,
        Session;

class _AuthFalso implements ClienteDeAuth {
  final StreamController<AuthState> flujo = StreamController.broadcast();
  final List<String> llamadas = [];
  Map<String, String>? parametrosDeOAuth;
  Object? errorAlIngresar;
  bool oauthSePudoAbrir = true;

  @override
  Future<void> ingresarConIdToken({
    required String idToken,
    String? accessToken,
  }) async {
    llamadas.add('idToken:$idToken:$accessToken');
    if (errorAlIngresar != null) throw errorAlIngresar!;
  }

  @override
  Future<void> ingresarConCorreo(String correo, String contrasena) async {
    llamadas.add('correo:$correo:$contrasena');
    if (errorAlIngresar != null) throw errorAlIngresar!;
  }

  @override
  Future<bool> ingresarConOAuthGoogle({
    required Map<String, String> parametros,
  }) async {
    llamadas.add('oauth');
    parametrosDeOAuth = parametros;
    if (errorAlIngresar != null) throw errorAlIngresar!;
    return oauthSePudoAbrir;
  }

  @override
  Stream<AuthState> get cambios => flujo.stream;

  @override
  Session? get sesionActual => null;
}

class _GoogleFalso implements ProveedorDeGoogleNativo {
  Object? error;
  bool sesionCerrada = false;

  @override
  Future<CredencialDeGoogle> autenticar() async {
    if (error != null) throw error!;
    return const CredencialDeGoogle(idToken: 'id-token', accessToken: 'acceso');
  }

  @override
  Future<void> cerrarSesion() async => sesionCerrada = true;
}

void main() {
  late _AuthFalso auth;
  late _GoogleFalso google;

  setUp(() {
    auth = _AuthFalso();
    google = _GoogleFalso();
  });

  group('Android (ingreso nativo)', () {
    IngresoRepositorioSupabase repo() =>
        IngresoRepositorioSupabase(auth, google: google, esWeb: false);

    test(
      'CA-1: entrega el id_token a Supabase y queda con la sesión',
      () async {
        final resultado = await repo().ingresarConGoogle();

        expect(resultado, ResultadoDeIngreso.exito);
        expect(auth.llamadas, ['idToken:id-token:acceso']);
      },
    );

    test(
      'CA-4: si cierra la ventana de Google no hay fallo ni sesión',
      () async {
        google.error = const GoogleCanceladoException();

        final resultado = await repo().ingresarConGoogle();

        expect(resultado, ResultadoDeIngreso.cancelado);
        expect(auth.llamadas, isEmpty);
      },
    );

    test('CA-4: sin conexión, el fallo es sin conexión', () async {
      auth.errorAlIngresar = AuthRetryableFetchException();

      await expectLater(
        repo().ingresarConGoogle(),
        throwsA(
          isA<FalloDeIngreso>().having(
            (f) => f.tipo,
            'tipo',
            TipoDeFalloDeIngreso.sinConexion,
          ),
        ),
      );
    });

    test('CA-3: una cuenta bloqueada lanza cuenta suspendida', () async {
      auth.errorAlIngresar = const AuthApiException(
        'User is banned',
        statusCode: '403',
        code: 'user_banned',
      );

      await expectLater(
        repo().ingresarConGoogle(),
        throwsA(
          isA<FalloDeIngreso>().having(
            (f) => f.tipo,
            'tipo',
            TipoDeFalloDeIngreso.cuentaSuspendida,
          ),
        ),
      );
    });

    test('CA-5: el rechazo del hook llega con el texto del servidor', () async {
      auth.errorAlIngresar = const AuthApiException(
        'Tu correo no tiene una invitación vigente. Pídele una al administrador.',
        statusCode: '403',
      );

      await expectLater(
        repo().ingresarConGoogle(),
        throwsA(
          isA<FalloDeIngreso>()
              .having((f) => f.tipo, 'tipo', TipoDeFalloDeIngreso.sinInvitacion)
              .having(
                (f) => f.mensaje,
                'mensaje',
                'Tu correo no tiene una invitación vigente. Pídele una al administrador.',
              ),
        ),
      );
    });

    test(
      'CA-6: un error inesperado del ingreso de Google es inesperado',
      () async {
        google.error = StateError('Google no entregó el id_token');

        await expectLater(
          repo().ingresarConGoogle(),
          throwsA(
            isA<FalloDeIngreso>().having(
              (f) => f.tipo,
              'tipo',
              TipoDeFalloDeIngreso.inesperado,
            ),
          ),
        );
      },
    );

    test('sin el proveedor nativo no ingresa', () async {
      final sinGoogle = IngresoRepositorioSupabase(auth, esWeb: false);

      await expectLater(
        sinGoogle.ingresarConGoogle(),
        throwsA(isA<FalloDeIngreso>()),
      );
      expect(auth.llamadas, isEmpty);
    });
  });

  group('web (redirección OAuth con PKCE)', () {
    IngresoRepositorioSupabase repo() =>
        IngresoRepositorioSupabase(auth, esWeb: true);

    test('CA-2: abre el flujo OAuth con selector de cuenta y sin hd', () async {
      final resultado = await repo().ingresarConGoogle();

      expect(resultado, ResultadoDeIngreso.redirigido);
      expect(auth.llamadas, ['oauth']);
      expect(auth.parametrosDeOAuth, {'prompt': 'select_account'});
      expect(auth.parametrosDeOAuth!.containsKey('hd'), isFalse);
    });

    test('si no se pudo abrir el flujo, el fallo es inesperado', () async {
      auth.oauthSePudoAbrir = false;

      await expectLater(
        repo().ingresarConGoogle(),
        throwsA(
          isA<FalloDeIngreso>().having(
            (f) => f.tipo,
            'tipo',
            TipoDeFalloDeIngreso.inesperado,
          ),
        ),
      );
    });

    test('los errores de regreso del flujo OAuth salen clasificados', () async {
      final fallos = <FalloDeIngreso>[];
      final suscripcion = repo().fallosDeRegreso.listen(fallos.add);

      auth.flujo.addError(
        const AuthApiException(
          'Solo se admiten cuentas de Google invitadas.',
          statusCode: '403',
        ),
      );
      auth.flujo.addError(
        const AuthApiException('User is banned', code: 'user_banned'),
      );
      await Future<void>.delayed(Duration.zero);
      await suscripcion.cancel();

      expect(fallos.map((f) => f.tipo), [
        TipoDeFalloDeIngreso.dominioNoPermitido,
        TipoDeFalloDeIngreso.cuentaSuspendida,
      ]);
    });
  });

  group('correo y contraseña (modo de pruebas)', () {
    test('ingresa con el correo sin espacios', () async {
      final resultado = await IngresoRepositorioSupabase(
        auth,
        esWeb: true,
      ).ingresarConCorreo('  admin@prueba.local ', 'clave');

      expect(resultado, ResultadoDeIngreso.exito);
      expect(auth.llamadas, ['correo:admin@prueba.local:clave']);
    });

    test('un fallo se clasifica igual que el de Google', () async {
      auth.errorAlIngresar = AuthRetryableFetchException();

      await expectLater(
        IngresoRepositorioSupabase(
          auth,
          esWeb: true,
        ).ingresarConCorreo('a@b.c', 'x'),
        throwsA(
          isA<FalloDeIngreso>().having(
            (f) => f.tipo,
            'tipo',
            TipoDeFalloDeIngreso.sinConexion,
          ),
        ),
      );
    });
  });

  group('sesión', () {
    test('los cambios de sesión no incluyen los errores del flujo', () async {
      final repo = IngresoRepositorioSupabase(auth, esWeb: true);
      final sesiones = <Session?>[];
      final errores = <Object>[];
      final suscripcion = repo.cambiosDeSesion.listen(
        sesiones.add,
        onError: errores.add,
      );

      auth.flujo.add(const AuthState(AuthChangeEvent.signedOut, null));
      auth.flujo.addError(const AuthApiException('algo', statusCode: '500'));
      await Future<void>.delayed(Duration.zero);
      await suscripcion.cancel();

      expect(sesiones, [null]);
      expect(errores, isEmpty);
    });

    test('cerrar la sesión de Google no toca la de Supabase', () async {
      final repo = IngresoRepositorioSupabase(
        auth,
        google: google,
        esWeb: false,
      );

      await repo.cerrarSesionDeGoogle();

      expect(google.sesionCerrada, isTrue);
      expect(auth.llamadas, isEmpty);
    });
  });
}

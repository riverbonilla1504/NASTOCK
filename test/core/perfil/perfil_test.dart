import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/perfil/perfil.dart';

/// Arma un JWT sin firma válida con [contenido] como cuerpo: la app solo lee
/// los claims, no valida la firma.
String _token(Map<String, Object?> contenido) {
  String parte(Object? valor) =>
      base64Url.encode(utf8.encode(jsonEncode(valor))).replaceAll('=', '');
  return '${parte({'alg': 'HS256', 'typ': 'JWT'})}.${parte(contenido)}.firma';
}

Map<String, dynamic> _fila({
  String rol = 'analista',
  String estado = 'activo',
}) => {
  'id': '00000000-0000-4000-8000-000000000002',
  'email': 'analista@prueba.test',
  'nombre': 'Analista de prueba',
  'rol': rol,
  'estado': estado,
  'recibe_sugerencias': true,
  'version': 3,
};

void main() {
  group('RolApp y EstadoCuenta', () {
    test('reconocen los valores de la base de datos', () {
      expect(RolApp.desdeTexto('usuario'), RolApp.usuario);
      expect(RolApp.desdeTexto('analista'), RolApp.analista);
      expect(RolApp.desdeTexto('administrador'), RolApp.administrador);
      expect(EstadoCuenta.desdeTexto('activo'), EstadoCuenta.activo);
      expect(EstadoCuenta.desdeTexto('suspendido'), EstadoCuenta.suspendido);
      expect(EstadoCuenta.desdeTexto('baja'), EstadoCuenta.baja);
    });

    test('un valor nulo o desconocido da null', () {
      expect(RolApp.desdeTexto(null), isNull);
      expect(RolApp.desdeTexto('superadmin'), isNull);
      expect(RolApp.desdeTexto(7), isNull);
      expect(EstadoCuenta.desdeTexto(null), isNull);
      expect(EstadoCuenta.desdeTexto('Activo'), isNull);
    });
  });

  group('ClaimsDeSesion.desdeToken', () {
    test('CA-1: lee app_rol y app_estado de un analista activo', () {
      final claims = ClaimsDeSesion.desdeToken(
        _token({'sub': 'x', 'app_rol': 'analista', 'app_estado': 'activo'}),
      );
      expect(claims.rol, RolApp.analista);
      expect(claims.estado, EstadoCuenta.activo);
    });

    test('lee el estado de una cuenta suspendida', () {
      final claims = ClaimsDeSesion.desdeToken(
        _token({'app_rol': 'usuario', 'app_estado': 'suspendido'}),
      );
      expect(claims.rol, RolApp.usuario);
      expect(claims.estado, EstadoCuenta.suspendido);
    });

    test('un token de alguien sin perfil trae los claims en null', () {
      final claims = ClaimsDeSesion.desdeToken(
        _token({'sub': 'x', 'app_rol': null, 'app_estado': null}),
      );
      expect(claims.rol, isNull);
      expect(claims.estado, isNull);
    });

    test('un token sin los claims da claims vacíos', () {
      final claims = ClaimsDeSesion.desdeToken(_token({'sub': 'x'}));
      expect(claims.rol, isNull);
      expect(claims.estado, isNull);
    });

    test('un rol o un estado desconocidos dan null y no fallan', () {
      final claims = ClaimsDeSesion.desdeToken(
        _token({'app_rol': 'superadmin', 'app_estado': 'dormido'}),
      );
      expect(claims.rol, isNull);
      expect(claims.estado, isNull);
    });

    test('sin token o con un token mal formado da claims vacíos', () {
      for (final token in [
        null,
        '',
        'no-es-un-jwt',
        'a.b',
        'a.%%%.c',
        'a.${base64Url.encode(utf8.encode('[1, 2]'))}.c',
        'a.${base64Url.encode(utf8.encode('no es json'))}.c',
      ]) {
        final claims = ClaimsDeSesion.desdeToken(token);
        expect(claims.rol, isNull, reason: '$token');
        expect(claims.estado, isNull, reason: '$token');
      }
    });
  });

  group('Perfil.desdeJson', () {
    test('arma el perfil con una fila de perfiles', () {
      final perfil = Perfil.desdeJson(_fila());
      expect(perfil.id, '00000000-0000-4000-8000-000000000002');
      expect(perfil.email, 'analista@prueba.test');
      expect(perfil.nombre, 'Analista de prueba');
      expect(perfil.rol, RolApp.analista);
      expect(perfil.estado, EstadoCuenta.activo);
      expect(perfil.recibeSugerencias, isTrue);
      expect(perfil.version, 3);
    });

    test('una fila con un rol o un estado desconocidos es un error', () {
      expect(
        () => Perfil.desdeJson(_fila(rol: 'superadmin')),
        throwsFormatException,
      );
      expect(
        () => Perfil.desdeJson(_fila(estado: 'dormido')),
        throwsFormatException,
      );
    });

    test('las columnas que se piden son las que lee desdeJson', () {
      final pedidas = Perfil.columnas.split(',').map((c) => c.trim()).toSet();
      expect(pedidas, _fila().keys.toSet());
    });
  });

  group('PerfilDeSesion', () {
    const claimsDeAdministrador = ClaimsDeSesion(
      rol: RolApp.administrador,
      estado: EstadoCuenta.activo,
    );

    test('sin sesión no hay perfil ni rol', () {
      expect(PerfilDeSesion.sinSesion.fila, isNull);
      expect(PerfilDeSesion.sinSesion.activo, isFalse);
      expect(PerfilDeSesion.sinSesion.rol, isNull);
    });

    test('con la fila de una cuenta activa, el rol es el de la fila', () {
      final perfil = PerfilDeSesion(
        claims: const ClaimsDeSesion(
          rol: RolApp.analista,
          estado: EstadoCuenta.activo,
        ),
        fila: Perfil.desdeJson(_fila()),
      );
      expect(perfil.activo, isTrue);
      expect(perfil.rol, RolApp.analista);
    });

    test('CA-6: si el rol cambió en perfiles, manda el de la fila y no el '
        'del token', () {
      final perfil = PerfilDeSesion(
        claims: claimsDeAdministrador,
        fila: Perfil.desdeJson(_fila(rol: 'usuario')),
      );
      expect(perfil.claims.rol, RolApp.administrador);
      expect(perfil.rol, RolApp.usuario);
    });

    test('CA-2: sin fila (cuenta no activa) no hay rol aunque el token '
        'siga diciendo administrador', () {
      const perfil = PerfilDeSesion(claims: claimsDeAdministrador);
      expect(perfil.activo, isFalse);
      expect(perfil.rol, isNull);
    });

    test('una fila que no está activa no da rol', () {
      final perfil = PerfilDeSesion(
        claims: claimsDeAdministrador,
        fila: Perfil.desdeJson(_fila(estado: 'suspendido')),
      );
      expect(perfil.activo, isFalse);
      expect(perfil.rol, isNull);
    });
  });
}

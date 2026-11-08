import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/acceso_por_rol.dart';
import 'package:inversiones/app/catalogo/pagina_catalogo.dart';
import 'package:inversiones/app/rutas.dart';
import 'package:inversiones/core/perfil/perfil.dart';

const _usuario = ClaimsDeSesion(
  rol: RolApp.usuario,
  estado: EstadoCuenta.activo,
);
const _analista = ClaimsDeSesion(
  rol: RolApp.analista,
  estado: EstadoCuenta.activo,
);
const _admin = ClaimsDeSesion(
  rol: RolApp.administrador,
  estado: EstadoCuenta.activo,
);

String? _ir(String ruta, ClaimsDeSesion claims, {bool haySesion = true}) =>
    redirigirSegunAcceso(ruta: ruta, haySesion: haySesion, claims: claims);

void main() {
  group('accesoDeRuta (docs/03 §3)', () {
    test('Mercado es de todos, también de un rol desconocido', () {
      for (final rol in [...RolApp.values, null]) {
        expect(accesoDeRuta(rol, Rutas.inicio), AccesoDeRuta.permitido);
      }
    });

    test('Oportunidades y Alertas son de los tres roles', () {
      for (final ruta in [Rutas.oportunidades, Rutas.alertas]) {
        for (final rol in RolApp.values) {
          expect(accesoDeRuta(rol, ruta), AccesoDeRuta.permitido, reason: ruta);
        }
        expect(accesoDeRuta(null, ruta), AccesoDeRuta.denegado, reason: ruta);
      }
    });

    test('Mi cupo es solo del Usuario', () {
      expect(accesoDeRuta(RolApp.usuario, Rutas.cupo), AccesoDeRuta.permitido);
      expect(accesoDeRuta(RolApp.analista, Rutas.cupo), AccesoDeRuta.denegado);
      expect(
        accesoDeRuta(RolApp.administrador, Rutas.cupo),
        AccesoDeRuta.denegado,
      );
    });

    test('CA-2: /admin y sus subrutas son solo del Administrador', () {
      for (final ruta in [
        '/admin',
        '/admin/usuarios',
        '/admin/capital/aportes',
      ]) {
        expect(
          accesoDeRuta(RolApp.administrador, ruta),
          AccesoDeRuta.permitido,
          reason: ruta,
        );
        expect(
          accesoDeRuta(RolApp.usuario, ruta),
          AccesoDeRuta.denegado,
          reason: ruta,
        );
        expect(
          accesoDeRuta(RolApp.analista, ruta),
          AccesoDeRuta.denegado,
          reason: ruta,
        );
      }
    });

    test(
      'CA-2 y CA-4: /riesgo es del Analista y el Administrador solo lo mira',
      () {
        for (final ruta in ['/riesgo', '/riesgo/bandeja', '/riesgo/segundas']) {
          expect(
            accesoDeRuta(RolApp.analista, ruta),
            AccesoDeRuta.permitido,
            reason: ruta,
          );
          expect(
            accesoDeRuta(RolApp.administrador, ruta),
            AccesoDeRuta.soloLectura,
            reason: ruta,
          );
          expect(
            accesoDeRuta(RolApp.usuario, ruta),
            AccesoDeRuta.denegado,
            reason: ruta,
          );
          expect(accesoDeRuta(null, ruta), AccesoDeRuta.denegado, reason: ruta);
        }
      },
    );

    test('una ruta que solo empieza parecido no cuenta como la de un rol', () {
      expect(
        accesoDeRuta(RolApp.administrador, '/administracion'),
        AccesoDeRuta.denegado,
      );
      expect(
        accesoDeRuta(RolApp.administrador, '/riesgos'),
        AccesoDeRuta.denegado,
      );
      expect(accesoDeRuta(RolApp.usuario, '/cupos'), AccesoDeRuta.denegado);
    });

    test('una ruta desconocida se niega a todos', () {
      for (final rol in [...RolApp.values, null]) {
        expect(accesoDeRuta(rol, '/no-existe'), AccesoDeRuta.denegado);
        expect(accesoDeRuta(rol, '/'), AccesoDeRuta.denegado);
      }
    });
  });

  group('redirigirSegunAcceso (docs/05 §9.3)', () {
    test('CA-3: sin sesión, cualquier ruta lleva al ingreso', () {
      for (final ruta in [
        Rutas.inicio,
        '/',
        Rutas.cupo,
        '/admin/usuarios',
        '/riesgo/bandeja',
        Rutas.cuentaSuspendida,
      ]) {
        expect(
          _ir(ruta, ClaimsDeSesion.vacios, haySesion: false),
          Rutas.ingreso,
          reason: ruta,
        );
      }
    });

    test('sin sesión, el ingreso se queda donde está', () {
      expect(
        _ir(Rutas.ingreso, ClaimsDeSesion.vacios, haySesion: false),
        isNull,
      );
    });

    test(
      'CA-3: con la cuenta suspendida o de baja va a /cuenta-suspendida',
      () {
        for (final estado in [EstadoCuenta.suspendido, EstadoCuenta.baja]) {
          final claims = ClaimsDeSesion(rol: RolApp.usuario, estado: estado);
          for (final ruta in [Rutas.inicio, Rutas.ingreso, '/admin', '/']) {
            expect(
              _ir(ruta, claims),
              Rutas.cuentaSuspendida,
              reason: '$estado $ruta',
            );
          }
          expect(
            _ir(Rutas.cuentaSuspendida, claims),
            isNull,
            reason: '$estado',
          );
        }
      },
    );

    test('un token sin el claim de estado se trata como no activo', () {
      expect(_ir(Rutas.inicio, ClaimsDeSesion.vacios), Rutas.cuentaSuspendida);
      expect(
        _ir(Rutas.inicio, const ClaimsDeSesion(rol: RolApp.usuario)),
        Rutas.cuentaSuspendida,
      );
    });

    test('con sesión activa, ingreso y cuenta suspendida llevan al inicio', () {
      for (final claims in [_usuario, _analista, _admin]) {
        expect(_ir(Rutas.ingreso, claims), Rutas.inicio);
        expect(_ir(Rutas.cuentaSuspendida, claims), Rutas.inicio);
      }
    });

    test('CA-1: cada rol se queda en las rutas de su menú', () {
      expect(_ir(Rutas.inicio, _usuario), isNull);
      expect(_ir(Rutas.oportunidades, _usuario), isNull);
      expect(_ir(Rutas.cupo, _usuario), isNull);
      expect(_ir(Rutas.alertas, _usuario), isNull);
      expect(_ir(Rutas.cupo, _analista), Rutas.inicio);
      expect(_ir(Rutas.alertas, _analista), isNull);
      expect(_ir(Rutas.admin, _admin), isNull);
      expect(_ir('/admin/usuarios', _admin), isNull);
    });

    test('CA-2: el Usuario y el Analista en /admin vuelven al inicio', () {
      for (final claims in [_usuario, _analista]) {
        expect(_ir('/admin', claims), Rutas.inicio);
        expect(_ir('/admin/usuarios', claims), Rutas.inicio);
      }
    });

    test('CA-2: el Usuario en /riesgo vuelve al inicio', () {
      expect(_ir('/riesgo', _usuario), Rutas.inicio);
      expect(_ir('/riesgo/bandeja', _usuario), Rutas.inicio);
    });

    test(
      'CA-4: el Administrador y el Analista no son expulsados de /riesgo',
      () {
        expect(_ir('/riesgo/bandeja', _admin), isNull);
        expect(_ir('/riesgo/bandeja', _analista), isNull);
      },
    );

    test(
      'la raíz y las rutas desconocidas llevan al inicio con sesión activa',
      () {
        for (final claims in [_usuario, _analista, _admin]) {
          expect(_ir('/', claims), Rutas.inicio);
          expect(_ir('/no-existe', claims), Rutas.inicio);
        }
      },
    );

    test('el catálogo de componentes no pide sesión ni rol', () {
      for (final ruta in [
        RutasCatalogo.inicio,
        RutasCatalogo.mercado,
        RutasCatalogo.componentes,
      ]) {
        expect(_ir(ruta, ClaimsDeSesion.vacios, haySesion: false), isNull);
        expect(_ir(ruta, _usuario), isNull);
      }
    });

    test('una ruta que solo empieza parecido al catálogo sí pide sesión', () {
      expect(
        _ir('/catalogos', ClaimsDeSesion.vacios, haySesion: false),
        Rutas.ingreso,
      );
    });

    test(
      'no hay ciclos: el destino de una redirección es una ruta estable',
      () {
        for (final claims in [
          _usuario,
          _analista,
          _admin,
          ClaimsDeSesion.vacios,
          const ClaimsDeSesion(rol: RolApp.usuario, estado: EstadoCuenta.baja),
        ]) {
          for (final haySesion in [true, false]) {
            for (final ruta in [
              '/',
              Rutas.ingreso,
              Rutas.cuentaSuspendida,
              Rutas.inicio,
              Rutas.cupo,
              '/admin',
              '/riesgo/x',
              '/zzz',
            ]) {
              final primero = _ir(ruta, claims, haySesion: haySesion);
              if (primero == null) continue;
              expect(
                _ir(primero, claims, haySesion: haySesion),
                isNull,
                reason: '$ruta → $primero con $claims',
              );
            }
          }
        }
      },
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/acceso_por_rol.dart';
import 'package:inversiones/app/destinos.dart';
import 'package:inversiones/app/rutas.dart';
import 'package:inversiones/core/perfil/perfil.dart';

List<String> _menu(RolApp? rol) =>
    destinosDeRol(rol).map((d) => d.etiqueta).toList();

void main() {
  group('menú de cada rol en el MVP corto (docs/03 §3)', () {
    test('CA-1: el Usuario ve Mercado, Oportunidades, Mi cupo y Alertas', () {
      expect(_menu(RolApp.usuario), [
        'Mercado',
        'Oportunidades',
        'Mi cupo',
        'Alertas',
      ]);
    });

    test('CA-1: el Analista ve Mercado, Oportunidades y Alertas', () {
      expect(_menu(RolApp.analista), ['Mercado', 'Oportunidades', 'Alertas']);
    });

    test('CA-1: el Administrador ve además Administración', () {
      expect(_menu(RolApp.administrador), [
        'Mercado',
        'Oportunidades',
        'Alertas',
        'Administración',
      ]);
    });

    test('sin rol solo queda Mercado', () {
      expect(_menu(null), ['Mercado']);
    });

    test('ningún menú pasa de cuatro destinos (el tope de la isla)', () {
      for (final rol in RolApp.values) {
        expect(destinosDeRol(rol).length, lessThanOrEqualTo(4), reason: '$rol');
      }
    });

    test('no hay pestañas de pantallas fuera del MVP corto', () {
      final etiquetas = destinosDelMvp.map((d) => d.etiqueta).join(' ');
      for (final fuera in [
        'Nueva orden',
        'Mis sugerencias',
        'Bandeja de riesgo',
        'Fondo',
        'Desempeño',
        'Reportes',
        'Perfil',
        'Rebalanceos',
        'Bitácora',
      ]) {
        expect(etiquetas, isNot(contains(fuera)));
      }
    });
  });

  group('el registro y la política no se contradicen', () {
    test('cada rol puede abrir exactamente los destinos de su menú', () {
      for (final rol in RolApp.values) {
        for (final destino in destinosDelMvp) {
          final esperado = destino.roles.contains(rol)
              ? AccesoDeRuta.permitido
              : AccesoDeRuta.denegado;
          expect(
            accesoDeRuta(rol, destino.ruta),
            esperado,
            reason: '$rol ${destino.ruta}',
          );
        }
      }
    });

    test('las rutas son únicas y la primera es Mercado', () {
      final rutas = destinosDelMvp.map((d) => d.ruta).toList();
      expect(rutas.toSet().length, rutas.length);
      expect(rutas.first, Rutas.inicio);
    });

    test('Mercado, Oportunidades, Mi cupo y Administración tienen pantalla propia; el resto, marcador', () {
      const conPantalla = {
        Rutas.inicio,
        Rutas.oportunidades,
        Rutas.cupo,
        Rutas.admin,
      };
      for (final destino in destinosDelMvp) {
        expect(
          destino.pantalla == null,
          !conPantalla.contains(destino.ruta),
          reason: destino.ruta,
        );
      }
    });

    test(
      'Administración trae las subrutas de sus secciones (HU-003, HU-099, HU-100)',
      () {
        final admin = destinosDelMvp.firstWhere((d) => d.ruta == Rutas.admin);
        expect(
          admin.subrutas.map((r) => r.path),
          containsAll(['usuarios', 'capital', 'cupos']),
        );
        expect(seccionDeAdministracionDisponible(Rutas.adminCapital), isTrue);
        expect(seccionDeAdministracionDisponible(Rutas.adminUsuarios), isTrue);
        expect(seccionDeAdministracionDisponible(Rutas.adminCupos), isTrue);
        expect(
          seccionDeAdministracionDisponible('/admin/inexistente'),
          isFalse,
        );
      },
    );
  });

  group('destinoDeRuta', () {
    test('encuentra el destino de una ruta base y de sus subrutas', () {
      expect(destinoDeRuta('/admin')?.etiqueta, 'Administración');
      expect(destinoDeRuta('/admin/usuarios')?.etiqueta, 'Administración');
      expect(destinoDeRuta('/cupo')?.etiqueta, 'Mi cupo');
    });

    test(
      'no confunde rutas que solo empiezan parecido ni las desconocidas',
      () {
        expect(destinoDeRuta('/administracion'), isNull);
        expect(destinoDeRuta('/riesgo/bandeja'), isNull);
        expect(destinoDeRuta('/'), isNull);
      },
    );
  });
}

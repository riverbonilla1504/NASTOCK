import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/acceso_por_rol.dart';
import 'package:inversiones/app/rutas.dart';
import 'package:inversiones/core/configuracion/entorno.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/auth/presentation/acceso_de_sesion_provider.dart';

import '../falsos.dart';

const _configurado = Entorno(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseLlavePublicable: 'llave-publicable-de-prueba',
);

ProviderContainer _contenedor(IngresoRepositorioFalso repo) {
  final contenedor = ProviderContainer(
    overrides: [
      entornoProvider.overrideWithValue(_configurado),
      ingresoRepositorioProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(contenedor.dispose);
  return contenedor;
}

void main() {
  test('sin sesión no hay acceso ni claims', () {
    final acceso = _contenedor(IngresoRepositorioFalso())
        .read(accesoDeSesionProvider);

    expect(acceso.haySesion, isFalse);
    expect(acceso.rol, isNull);
    expect(acceso.activo, isFalse);
  });

  test('lee el rol y el estado del token de cada rol', () {
    for (final rol in RolApp.values) {
      final repo = IngresoRepositorioFalso()
        ..sesionActual = sesionDePrueba(rol: rol.name, estado: 'activo');
      final acceso = _contenedor(repo).read(accesoDeSesionProvider);

      expect(acceso.haySesion, isTrue);
      expect(acceso.rol, rol);
      expect(acceso.estado, EstadoCuenta.activo);
      expect(acceso.activo, isTrue);
    }
  });

  test('CA-3: un token suspendido o de baja no es una sesión activa', () {
    for (final estado in ['suspendido', 'baja']) {
      final repo = IngresoRepositorioFalso()
        ..sesionActual = sesionDePrueba(rol: 'usuario', estado: estado);
      final acceso = _contenedor(repo).read(accesoDeSesionProvider);

      expect(acceso.haySesion, isTrue);
      expect(acceso.estado.toString(), contains(estado));
      expect(acceso.activo, isFalse);
    }
  });

  test('un token sin claims no es una sesión activa', () {
    final repo = IngresoRepositorioFalso()..sesionActual = sesionDePrueba();
    final acceso = _contenedor(repo).read(accesoDeSesionProvider);

    expect(acceso.haySesion, isTrue);
    expect(acceso.rol, isNull);
    expect(acceso.estado, isNull);
    expect(acceso.activo, isFalse);
  });

  test(
    'un token renovado con el mismo rol y estado no avisa de un cambio',
    () async {
      final repo = IngresoRepositorioFalso()
        ..sesionActual = sesionDePrueba(rol: 'usuario', estado: 'activo');
      final contenedor = _contenedor(repo);
      var avisos = 0;
      contenedor.listen(accesoDeSesionProvider, (_, _) => avisos++);
      contenedor.read(accesoDeSesionProvider);

      repo.sesiones.add(
        sesionDePrueba(id: 'otro-token', rol: 'usuario', estado: 'activo'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(avisos, 0);
    },
  );

  test('un token renovado con otro rol sí avisa', () async {
    final repo = IngresoRepositorioFalso()
      ..sesionActual = sesionDePrueba(rol: 'usuario', estado: 'activo');
    final contenedor = _contenedor(repo);
    final vistos = <RolApp?>[];
    contenedor.listen(
      accesoDeSesionProvider,
      (_, nuevo) => vistos.add(nuevo.rol),
    );
    contenedor.read(accesoDeSesionProvider);

    // Sin una pantalla que dibuje, Riverpod recalcula un proveedor derivado al
    // leerlo: se lee entre un cambio y el siguiente, como lo haría un fotograma.
    repo.sesiones.add(sesionDePrueba(rol: 'analista', estado: 'activo'));
    await Future<void>.delayed(Duration.zero);
    contenedor.read(accesoDeSesionProvider);
    repo.sesiones.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(vistos, [RolApp.analista, null]);
    expect(contenedor.read(accesoDeSesionProvider).haySesion, isFalse);
  });

  group('accesoDeRutaProvider', () {
    AccesoDeRuta acceso(String rol, String ruta) {
      final repo = IngresoRepositorioFalso()
        ..sesionActual = sesionDePrueba(rol: rol, estado: 'activo');
      return _contenedor(repo).read(accesoDeRutaProvider(ruta));
    }

    test('CA-4: el Administrador entra a /riesgo solo en lectura', () {
      expect(acceso('administrador', Rutas.riesgo), AccesoDeRuta.soloLectura);
    });

    test('el Analista opera en /riesgo y el Usuario no entra', () {
      expect(acceso('analista', Rutas.riesgo), AccesoDeRuta.permitido);
      expect(acceso('usuario', Rutas.riesgo), AccesoDeRuta.denegado);
    });

    test('sin sesión no hay acceso salvo a Mercado', () {
      final contenedor = _contenedor(IngresoRepositorioFalso());

      expect(
        contenedor.read(accesoDeRutaProvider(Rutas.inicio)),
        AccesoDeRuta.permitido,
      );
      expect(
        contenedor.read(accesoDeRutaProvider(Rutas.admin)),
        AccesoDeRuta.denegado,
      );
    });
  });
}

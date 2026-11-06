import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/core/perfil/perfil_provider.dart';
import 'package:inversiones/core/perfil/perfil_repositorio.dart';

/// Repositorio falso: lo que "dice" el token y lo que entrega `perfiles` se
/// cambian a mano, y [cambiarSesion] simula una renovación del token.
class _RepositorioFalso implements PerfilRepositorio {
  _RepositorioFalso({this.claims = ClaimsDeSesion.vacios, this.fila});

  ClaimsDeSesion claims;
  Perfil? fila;
  int lecturasDeFila = 0;
  final _cambios = StreamController<void>.broadcast(sync: true);

  void cambiarSesion() => _cambios.add(null);

  @override
  ClaimsDeSesion leerClaims() => claims;

  @override
  Future<Perfil?> leerPerfilPropio() async {
    lecturasDeFila++;
    return fila;
  }

  @override
  Stream<void> get cambiosDeSesion => _cambios.stream;
}

Perfil _perfil({
  required RolApp rol,
  EstadoCuenta estado = EstadoCuenta.activo,
}) => Perfil(
  id: '00000000-0000-4000-8000-000000000001',
  email: 'persona@prueba.test',
  nombre: 'Persona de prueba',
  rol: rol,
  estado: estado,
  recibeSugerencias: true,
  version: 1,
);

ProviderContainer _contenedor(_RepositorioFalso repositorio) {
  final contenedor = ProviderContainer(
    overrides: [perfilRepositorioProvider.overrideWithValue(repositorio)],
  );
  addTearDown(contenedor.dispose);
  return contenedor;
}

void main() {
  test('lee los claims del token y la fila de perfiles', () async {
    final repositorio = _RepositorioFalso(
      claims: const ClaimsDeSesion(
        rol: RolApp.analista,
        estado: EstadoCuenta.activo,
      ),
      fila: _perfil(rol: RolApp.analista),
    );
    final contenedor = _contenedor(repositorio);

    final perfil = await contenedor.read(perfilProvider.future);

    expect(perfil.claims.rol, RolApp.analista);
    expect(perfil.claims.estado, EstadoCuenta.activo);
    expect(perfil.fila?.rol, RolApp.analista);
    expect(perfil.activo, isTrue);
    expect(perfil.rol, RolApp.analista);
  });

  test('sin sesión no hay claims ni fila', () async {
    final contenedor = _contenedor(_RepositorioFalso());

    final perfil = await contenedor.read(perfilProvider.future);

    expect(perfil.claims.rol, isNull);
    expect(perfil.fila, isNull);
    expect(perfil.rol, isNull);
  });

  test('CA-2: una cuenta suspendida con token vigente no tiene rol', () async {
    final contenedor = _contenedor(
      _RepositorioFalso(
        claims: const ClaimsDeSesion(
          rol: RolApp.administrador,
          estado: EstadoCuenta.activo,
        ),
        // La base de datos no entrega la fila de una cuenta no activa.
        fila: null,
      ),
    );

    final perfil = await contenedor.read(perfilProvider.future);

    expect(perfil.claims.rol, RolApp.administrador);
    expect(perfil.activo, isFalse);
    expect(perfil.rol, isNull);
  });

  test(
    'CA-6: con el token atrasado, el rol vigente es el de perfiles',
    () async {
      final contenedor = _contenedor(
        _RepositorioFalso(
          claims: const ClaimsDeSesion(
            rol: RolApp.administrador,
            estado: EstadoCuenta.activo,
          ),
          fila: _perfil(rol: RolApp.usuario),
        ),
      );

      final perfil = await contenedor.read(perfilProvider.future);

      expect(perfil.claims.rol, RolApp.administrador);
      expect(perfil.rol, RolApp.usuario);
    },
  );

  test('cuando la sesión cambia vuelve a leer claims y fila', () async {
    final repositorio = _RepositorioFalso(
      claims: const ClaimsDeSesion(
        rol: RolApp.usuario,
        estado: EstadoCuenta.activo,
      ),
      fila: _perfil(rol: RolApp.usuario),
    );
    final contenedor = _contenedor(repositorio);
    // Se mantiene escuchado, como lo hará el enrutador.
    final escucha = contenedor.listen(perfilProvider, (_, _) {});
    addTearDown(escucha.close);

    final antes = await contenedor.read(perfilProvider.future);
    expect(antes.rol, RolApp.usuario);
    expect(repositorio.lecturasDeFila, 1);

    // El rol cambia en perfiles y la renovación del token ya lo trae.
    repositorio.claims = const ClaimsDeSesion(
      rol: RolApp.analista,
      estado: EstadoCuenta.activo,
    );
    repositorio.fila = _perfil(rol: RolApp.analista);
    repositorio.cambiarSesion();

    final despues = await contenedor.read(perfilProvider.future);
    expect(despues.claims.rol, RolApp.analista);
    expect(despues.rol, RolApp.analista);
    expect(repositorio.lecturasDeFila, 2);
  });
}

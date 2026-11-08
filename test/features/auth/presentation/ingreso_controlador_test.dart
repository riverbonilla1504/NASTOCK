import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/configuracion/entorno.dart';
import 'package:inversiones/core/errores/fallo_de_ingreso.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/auth/domain/resultado_de_ingreso.dart';
import 'package:inversiones/features/auth/presentation/ingreso_controlador.dart';

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
  late IngresoRepositorioFalso repo;
  late ProviderContainer contenedor;

  setUp(() {
    repo = IngresoRepositorioFalso();
    contenedor = _contenedor(repo);
  });

  EstadoDeIngreso estado() => contenedor.read(ingresoControladorProvider);
  IngresoControlador controlador() =>
      contenedor.read(ingresoControladorProvider.notifier);

  test('arranca inactivo: sin ingresar y sin fallo', () {
    expect(estado().ingresando, isFalse);
    expect(estado().fallo, isNull);
  });

  test('ingresa: pasa por ingresando y vuelve a inactivo', () async {
    final respuesta = Completer<ResultadoDeIngreso>();
    repo.pendiente = respuesta;

    final ingreso = controlador().ingresarConGoogle();
    expect(estado().ingresando, isTrue);

    respuesta.complete(ResultadoDeIngreso.exito);
    await ingreso;
    expect(estado().ingresando, isFalse);
    expect(estado().fallo, isNull);
    expect(repo.ingresosConGoogle, 1);
  });

  test('CA-4: si cierra la ventana de Google vuelve sin mensaje', () async {
    repo.resultado = ResultadoDeIngreso.cancelado;

    await controlador().ingresarConGoogle();

    expect(estado().ingresando, isFalse);
    expect(estado().fallo, isNull);
  });

  test('un fallo clasificado queda en el estado', () async {
    repo.error = const FalloDeIngreso(TipoDeFalloDeIngreso.sinInvitacion);

    await controlador().ingresarConGoogle();

    expect(estado().ingresando, isFalse);
    expect(estado().fallo?.tipo, TipoDeFalloDeIngreso.sinInvitacion);
  });

  test('CA-6: una excepción cualquiera queda como fallo inesperado', () async {
    repo.error = StateError('detalle técnico');

    await controlador().ingresarConGoogle();

    expect(estado().fallo?.tipo, TipoDeFalloDeIngreso.inesperado);
    expect(estado().fallo?.mensaje, isNot(contains('detalle técnico')));
  });

  test('un nuevo intento borra el fallo anterior', () async {
    repo.error = const FalloDeIngreso(TipoDeFalloDeIngreso.sinConexion);
    await controlador().ingresarConGoogle();
    expect(estado().fallo, isNotNull);

    repo.error = null;
    final respuesta = Completer<ResultadoDeIngreso>();
    repo.pendiente = respuesta;
    final ingreso = controlador().ingresarConGoogle();

    expect(estado().ingresando, isTrue);
    expect(estado().fallo, isNull);
    respuesta.complete(ResultadoDeIngreso.exito);
    await ingreso;
  });

  test('mientras ingresa ignora otro toque', () async {
    final respuesta = Completer<ResultadoDeIngreso>();
    repo.pendiente = respuesta;

    final primero = controlador().ingresarConGoogle();
    await controlador().ingresarConGoogle();
    await controlador().ingresarConCorreo('a@b.c', 'x');

    expect(repo.ingresosConGoogle, 1);
    expect(repo.ingresosConCorreo, isEmpty);
    respuesta.complete(ResultadoDeIngreso.exito);
    await primero;
  });

  test('ingresa con correo y contraseña', () async {
    await controlador().ingresarConCorreo('admin@prueba.local', 'clave');

    expect(repo.ingresosConCorreo, [('admin@prueba.local', 'clave')]);
    expect(estado().fallo, isNull);
  });

  test(
    'el rechazo que llega al volver de Google (web) queda como fallo',
    () async {
      estado(); // construye el controlador y se suscribe
      repo.fallos.add(
        const FalloDeIngreso(
          TipoDeFalloDeIngreso.dominioNoPermitido,
          textoDelServidor: 'Solo se admiten cuentas de Google invitadas.',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(estado().fallo?.tipo, TipoDeFalloDeIngreso.dominioNoPermitido);
      expect(
        estado().fallo?.mensaje,
        'Solo se admiten cuentas de Google invitadas.',
      );
    },
  );
}

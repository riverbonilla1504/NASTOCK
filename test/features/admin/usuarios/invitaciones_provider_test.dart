import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/features/admin/usuarios/presentation/invitaciones_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'ayudas.dart';

ProviderContainer _contenedor(RepositorioFalso repositorio) {
  final contenedor = ProviderContainer(overrides: overridesDe(repositorio));
  addTearDown(contenedor.dispose);
  return contenedor;
}

void main() {
  test('pide la lista al construirse', () async {
    final repositorio = RepositorioFalso(
      invitaciones: [invitacion(email: 'ana@prueba.test')],
    );
    final contenedor = _contenedor(repositorio);

    final lista = await contenedor.read(invitacionesProvider.future);

    expect(lista.map((i) => i.email), ['ana@prueba.test']);
    expect(repositorio.listados, 1);
  });

  test('invitar llama a la RPC y vuelve a pedir la lista', () async {
    final repositorio = RepositorioFalso();
    final contenedor = _contenedor(repositorio);
    await contenedor.read(invitacionesProvider.future);

    final creada = await contenedor
        .read(invitacionesProvider.notifier)
        .invitar(
          email: 'Luis@prueba.test',
          rol: RolApp.analista,
          cupoInicial: 0,
        );

    expect(repositorio.invitados, [
      (email: 'Luis@prueba.test', rol: RolApp.analista, cupo: 0.0),
    ]);
    expect(creada.email, 'luis@prueba.test');
    expect(repositorio.listados, 2);
    expect(contenedor.read(invitacionesProvider).value?.map((i) => i.email), [
      'luis@prueba.test',
    ]);
  });

  test(
    'si la RPC de invitar falla, lanza su error y no pide la lista',
    () async {
      final repositorio = RepositorioFalso()
        ..errorAlInvitar = const PostgrestException(
          message: 'INVITACION_DUPLICADA',
          code: 'P0001',
        );
      final contenedor = _contenedor(repositorio);
      await contenedor.read(invitacionesProvider.future);

      await expectLater(
        contenedor
            .read(invitacionesProvider.notifier)
            .invitar(
              email: 'ana@prueba.test',
              rol: RolApp.usuario,
              cupoInicial: 0,
            ),
        throwsA(
          isA<PostgrestException>().having(
            (e) => e.message,
            'message',
            'INVITACION_DUPLICADA',
          ),
        ),
      );
      expect(repositorio.listados, 1);
    },
  );

  test('revocar llama a la RPC y vuelve a pedir la lista', () async {
    final repositorio = RepositorioFalso(invitaciones: [invitacion(id: 'uno')]);
    final contenedor = _contenedor(repositorio);
    await contenedor.read(invitacionesProvider.future);

    await contenedor.read(invitacionesProvider.notifier).revocar('uno');

    expect(repositorio.revocadas, ['uno']);
    expect(repositorio.listados, 2);
  });

  test(
    'si revocar falla, lanza el error pero vuelve a pedir la lista',
    () async {
      final repositorio =
          RepositorioFalso(invitaciones: [invitacion(id: 'uno')])
            ..errorAlRevocar = const PostgrestException(
              message: 'ESTADO_INVALIDO',
              code: 'P0001',
            );
      final contenedor = _contenedor(repositorio);
      await contenedor.read(invitacionesProvider.future);

      await expectLater(
        contenedor.read(invitacionesProvider.notifier).revocar('uno'),
        throwsA(isA<PostgrestException>()),
      );
      expect(repositorio.listados, 2);
    },
  );

  test('si la lista no se puede pedir, el error queda en el estado', () async {
    final repositorio = RepositorioFalso()
      ..errorAlListar = Exception('sin red');
    final contenedor = _contenedor(repositorio);
    // Se mantiene viva para que no se destruya entre lecturas.
    contenedor.listen(invitacionesProvider, (_, _) {});

    await contenedor.read(invitacionesProvider.notifier).recargar();

    expect(contenedor.read(invitacionesProvider).hasError, isTrue);
  });

  test('recargar muestra lo que cambió en el servidor', () async {
    final repositorio = RepositorioFalso();
    final contenedor = _contenedor(repositorio);
    contenedor.listen(invitacionesProvider, (_, _) {});
    await contenedor.read(invitacionesProvider.future);

    repositorio.invitaciones = [invitacion(email: 'nueva@prueba.test')];
    await contenedor.read(invitacionesProvider.notifier).recargar();

    expect(contenedor.read(invitacionesProvider).value?.map((i) => i.email), [
      'nueva@prueba.test',
    ]);
  });
}

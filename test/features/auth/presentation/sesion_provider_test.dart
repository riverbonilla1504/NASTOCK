import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/configuracion/entorno.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/auth/presentation/sesion_provider.dart';

import '../falsos.dart';

const _configurado = Entorno(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseLlavePublicable: 'llave-publicable-de-prueba',
);

ProviderContainer _contenedor(Entorno entorno, IngresoRepositorioFalso repo) {
  final contenedor = ProviderContainer(
    overrides: [
      entornoProvider.overrideWithValue(entorno),
      ingresoRepositorioProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(contenedor.dispose);
  return contenedor;
}

void main() {
  test('sin Supabase configurado no hay sesión y no toca el repositorio', () {
    final repo = IngresoRepositorioFalso()..sesionActual = sesionDePrueba();
    final contenedor = _contenedor(
      const Entorno(supabaseUrl: '', supabaseLlavePublicable: ''),
      repo,
    );

    expect(contenedor.read(sesionProvider), isNull);
  });

  test('arranca con la sesión que ya existe', () {
    final sesion = sesionDePrueba();
    final contenedor = _contenedor(
      _configurado,
      IngresoRepositorioFalso()..sesionActual = sesion,
    );

    expect(contenedor.read(sesionProvider), sesion);
  });

  test('arranca sin sesión si no hay ninguna', () {
    final contenedor = _contenedor(_configurado, IngresoRepositorioFalso());

    expect(contenedor.read(sesionProvider), isNull);
  });

  test('sigue al ingreso y al cierre de sesión', () async {
    final repo = IngresoRepositorioFalso();
    final contenedor = _contenedor(_configurado, repo);
    final vistos = <Object?>[];
    contenedor.listen(sesionProvider, (_, nueva) => vistos.add(nueva));
    expect(contenedor.read(sesionProvider), isNull);

    final sesion = sesionDePrueba();
    repo.sesiones.add(sesion);
    await Future<void>.delayed(Duration.zero);
    expect(contenedor.read(sesionProvider), sesion);

    repo.sesiones.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(contenedor.read(sesionProvider), isNull);
    expect(vistos, [sesion, null]);
  });
}

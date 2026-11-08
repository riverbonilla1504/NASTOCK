import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/supabase/almacenamiento_seguro.dart';

/// Almacén en memoria que reemplaza al del sistema, solo para la prueba.
class _AlmacenEnMemoria implements FlutterSecureStorage {
  final Map<String, String> datos = {};

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => datos.containsKey(key);

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => datos[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      datos.remove(key);
    } else {
      datos[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => datos.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} no se usa aquí');
}

void main() {
  group('AlmacenamientoSeguroDeSesion', () {
    late _AlmacenEnMemoria almacen;
    late AlmacenamientoSeguroDeSesion sesion;

    setUp(() {
      almacen = _AlmacenEnMemoria();
      sesion = AlmacenamientoSeguroDeSesion(almacen);
    });

    test('sin sesión guardada no hay token', () async {
      await sesion.initialize();

      expect(await sesion.hasAccessToken(), isFalse);
      expect(await sesion.accessToken(), isNull);
    });

    test('guarda la sesión bajo su clave en el almacén seguro', () async {
      await sesion.persistSession('{"access_token":"x"}');

      expect(almacen.datos, {claveDeSesionSegura: '{"access_token":"x"}'});
      expect(await sesion.hasAccessToken(), isTrue);
      expect(await sesion.accessToken(), '{"access_token":"x"}');
    });

    test('guardar de nuevo reemplaza la sesión anterior', () async {
      await sesion.persistSession('uno');
      await sesion.persistSession('dos');

      expect(await sesion.accessToken(), 'dos');
    });

    test('quitar la sesión la borra del almacén', () async {
      await sesion.persistSession('uno');
      await sesion.removePersistedSession();

      expect(await sesion.hasAccessToken(), isFalse);
      expect(almacen.datos, isEmpty);
    });
  });
}

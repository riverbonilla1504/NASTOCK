import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/realtime/estado_conexion.dart';
import 'package:inversiones/core/realtime/foto_y_eventos.dart';
import 'package:inversiones/core/realtime/gestor_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';

import 'falsos.dart';

class _Registro {
  const _Registro(this.id, this.version, [this.texto = '']);
  final String id;
  final int version;
  final String texto;
}

/// La "API": lo que la base de datos entregaría hoy.
class _Api {
  final Map<String, _Registro> filas = {};
  int fotos = 0;
  final List<String> registrosPedidos = [];

  /// Si no es nulo, el siguiente registro pedido espera a que se complete.
  Completer<void>? pausa;
}

class _Bandeja extends FotoYEventosNotifier<_Registro> {
  _Bandeja(this.api);

  final _Api api;

  @override
  String get tabla => 'sugerencias';

  @override
  String idDe(_Registro registro) => registro.id;

  @override
  int? versionDe(_Registro registro) => registro.version;

  @override
  Future<List<_Registro>> pedirFoto() async {
    api.fotos++;
    return api.filas.values.toList();
  }

  @override
  Future<_Registro?> pedirRegistro(String id) async {
    api.registrosPedidos.add(id);
    final espera = api.pausa;
    if (espera != null) {
      api.pausa = null;
      await espera.future;
    }
    return api.filas[id];
  }
}

class _BandejaQueFalla extends _Bandeja {
  _BandejaQueFalla() : super(_Api());

  @override
  Future<List<_Registro>> pedirFoto() async => throw Exception('sin red');
}

void main() {
  late _Api api;
  late FuenteFalsa fuente;
  late GestorDeTiempoReal gestor;
  late AsyncNotifierProvider<_Bandeja, List<_Registro>> bandeja;
  late ProviderContainer contenedor;

  setUp(() {
    api = _Api()
      ..filas['a'] = const _Registro('a', 3, 'vieja')
      ..filas['b'] = const _Registro('b', 1);
    fuente = FuenteFalsa();
    gestor = GestorDeTiempoReal(fuente, ['usuario:u-1']);
    bandeja = AsyncNotifierProvider<_Bandeja, List<_Registro>>(
      () => _Bandeja(api),
    );
    // Sin reintentos automáticos: la prueba decide cuándo se pide otra vez.
    contenedor = ProviderContainer(
      retry: (_, _) => null,
      overrides: [gestorDeTiempoRealProvider.overrideWithValue(gestor)],
    );
    addTearDown(() async {
      contenedor.dispose();
      await gestor.cerrar();
    });
  });

  Future<List<_Registro>> montar() {
    // Como la pantalla: alguien escucha, así una invalidación recalcula.
    contenedor.listen(bandeja, (_, _) {});
    return contenedor.read(bandeja.future);
  }

  Future<void> pasar() async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  List<_Registro> lista() => contenedor.read(bandeja).requireValue;

  test('CA-6: al montar pide la foto por la API', () async {
    final registros = await montar();

    expect(registros.map((r) => r.id), ['a', 'b']);
    expect(api.fotos, 1);
    expect(api.registrosPedidos, isEmpty);
  });

  group('CA-2: eventos por versión', () {
    test('ignora un evento con la misma versión', () async {
      await montar();
      fuente.evento(
        'usuario:u-1',
        'sugerencia',
        tabla: 'sugerencias',
        id: 'a',
        version: 3,
      );
      await pasar();

      expect(api.registrosPedidos, isEmpty);
    });

    test('ignora un evento con una versión menor', () async {
      await montar();
      fuente.evento(
        'usuario:u-1',
        'sugerencia',
        tabla: 'sugerencias',
        id: 'a',
        version: 2,
      );
      await pasar();

      expect(api.registrosPedidos, isEmpty);
      expect(lista().first.texto, 'vieja');
    });

    test(
      'con una versión mayor pide ese registro por la API y lo reemplaza',
      () async {
        await montar();
        api.filas['a'] = const _Registro('a', 4, 'nueva');
        fuente.evento(
          'usuario:u-1',
          'sugerencia',
          tabla: 'sugerencias',
          id: 'a',
          version: 4,
        );
        await pasar();

        expect(api.registrosPedidos, ['a']);
        expect(lista().map((r) => '${r.id}:${r.version}:${r.texto}'), [
          'a:4:nueva',
          'b:1:',
        ]);
      },
    );

    test('un registro nuevo se agrega al final', () async {
      await montar();
      api.filas['c'] = const _Registro('c', 1);
      fuente.evento(
        'usuario:u-1',
        'sugerencia',
        tabla: 'sugerencias',
        id: 'c',
        version: 1,
      );
      await pasar();

      expect(lista().map((r) => r.id), ['a', 'b', 'c']);
    });

    test('un registro que la API ya no entrega se quita', () async {
      await montar();
      api.filas.remove('b');
      fuente.evento(
        'usuario:u-1',
        'sugerencia',
        tabla: 'sugerencias',
        id: 'b',
        version: 2,
      );
      await pasar();

      expect(lista().map((r) => r.id), ['a']);
    });

    test('un evento sin versión siempre pide el registro', () async {
      await montar();
      api.filas['a'] = const _Registro('a', 4, 'nueva');
      fuente.evento('usuario:u-1', 'sugerencia', tabla: 'sugerencias', id: 'a');
      await pasar();

      expect(lista().first.texto, 'nueva');
    });

    test('ignora los eventos de otras tablas', () async {
      await montar();
      fuente.evento(
        'usuario:u-1',
        'orden',
        tabla: 'ordenes',
        id: 'a',
        version: 9,
      );
      await pasar();

      expect(api.registrosPedidos, isEmpty);
    });

    test('una respuesta más vieja no reemplaza a una más nueva', () async {
      await montar();
      // Llega el evento v4 y la API tarda; mientras, llega el evento v5.
      final pausa = Completer<void>();
      api.pausa = pausa;
      api.filas['a'] = const _Registro('a', 4, 'cuarta');
      fuente.evento(
        'usuario:u-1',
        'sugerencia',
        tabla: 'sugerencias',
        id: 'a',
        version: 4,
      );
      await pasar();

      api.filas['a'] = const _Registro('a', 5, 'quinta');
      fuente.evento(
        'usuario:u-1',
        'sugerencia',
        tabla: 'sugerencias',
        id: 'a',
        version: 5,
      );
      await pasar();
      expect(lista().first.texto, 'quinta');

      // La primera respuesta llega tarde, con lo que valía (v5 ya en la API).
      pausa.complete();
      await pasar();
      expect(lista().first.version, 5);
    });

    test('un evento sin identificador pide la foto otra vez', () async {
      await montar();
      api.filas['a'] = const _Registro('a', 4, 'nueva');
      fuente.evento('usuario:u-1', 'sugerencia', tabla: 'sugerencias');
      await pasar();

      expect(api.fotos, 2);
      expect(lista().first.texto, 'nueva');
    });
  });

  group('CA-3 / CB-66: reconexión', () {
    test('al reconectar pide la foto completa otra vez', () async {
      await montar();
      fuente.suscribirTodos();
      api.filas['z'] = const _Registro('z', 1);

      fuente.senal(const SocketCerrado());
      await pasar();
      fuente.senal(const SocketAbierto());
      fuente.suscribirTodos();
      await pasar();

      expect(api.fotos, 2);
      expect(lista().map((r) => r.id), ['a', 'b', 'z']);
    });

    test('al volver a primer plano pide la foto otra vez', () async {
      await montar();
      gestor.alVolverAPrimerPlano();
      await pasar();

      expect(api.fotos, 2);
    });
  });

  test('si la foto falla, un evento no rompe nada', () async {
    final fallida = AsyncNotifierProvider<_BandejaQueFalla, List<_Registro>>(
      _BandejaQueFalla.new,
    );
    contenedor.listen(fallida, (_, _) {});
    await expectLater(contenedor.read(fallida.future), throwsException);

    fuente.evento(
      'usuario:u-1',
      'sugerencia',
      tabla: 'sugerencias',
      id: 'a',
      version: 4,
    );
    await pasar();

    expect(contenedor.read(fallida).hasError, isTrue);
  });

  test('sin sesión (sin gestor) pide la foto y no escucha nada', () async {
    final sinSesion = ProviderContainer(
      overrides: [gestorDeTiempoRealProvider.overrideWithValue(null)],
    );
    addTearDown(sinSesion.dispose);

    final registros = await sinSesion.read(bandeja.future);

    expect(registros, hasLength(2));
  });
}

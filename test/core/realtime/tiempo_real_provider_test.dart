import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/core/realtime/estado_conexion.dart';
import 'package:inversiones/core/realtime/fuente_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';
import 'package:inversiones/features/auth/presentation/sesion_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import '../../features/auth/falsos.dart';
import 'falsos.dart';

class _SesionFija extends SesionNotifier {
  _SesionFija(this._sesion);
  final Session? _sesion;

  @override
  Session? build() => _sesion;

  void poner(Session? sesion) => state = sesion;
}

void main() {
  late FuenteFalsa fuente;
  late _SesionFija sesion;

  ProviderContainer crear(Session? inicial) {
    sesion = _SesionFija(inicial);
    final contenedor = ProviderContainer(
      overrides: [
        fuenteDeTiempoRealProvider.overrideWithValue(fuente),
        sesionProvider.overrideWith(() => sesion),
      ],
    );
    addTearDown(contenedor.dispose);
    return contenedor;
  }

  setUp(() => fuente = FuenteFalsa());

  Session activa(String rol, {String id = 'u-1'}) =>
      sesionDePrueba(id: id, rol: rol, estado: 'activo');

  group('CA-1: canales por rol al ingresar', () {
    test('el Usuario abre mercado, fondo y el suyo', () {
      final c = crear(activa('usuario'));
      c.read(gestorDeTiempoRealProvider);

      expect(fuente.abiertos, ['mercado', 'fondo', 'usuario:u-1']);
    });

    test('el Analista suma supervision', () {
      final c = crear(activa('analista'));
      c.read(gestorDeTiempoRealProvider);

      expect(fuente.abiertos, [
        'mercado',
        'fondo',
        'usuario:u-1',
        'supervision',
      ]);
    });

    test('el Administrador suma supervision y admin', () {
      final c = crear(activa('administrador'));
      c.read(gestorDeTiempoRealProvider);

      expect(fuente.abiertos, [
        'mercado',
        'fondo',
        'usuario:u-1',
        'supervision',
        'admin',
      ]);
    });

    test('sin sesión no hay gestor ni canales y se ve conectado', () {
      final c = crear(null);

      expect(c.read(gestorDeTiempoRealProvider), isNull);
      expect(c.read(conexionProvider), EstadoConexion.conectado);
      expect(fuente.abiertos, isEmpty);
    });

    test('una cuenta suspendida no abre canales', () {
      final c = crear(sesionDePrueba(rol: 'usuario', estado: 'suspendido'));

      expect(c.read(gestorDeTiempoRealProvider), isNull);
      expect(fuente.abiertos, isEmpty);
    });
  });

  group('la sesión cambia', () {
    test('renovar el token con el mismo rol no reabre los canales', () {
      final c = crear(activa('usuario'));
      final gestor = c.read(gestorDeTiempoRealProvider);

      sesion.poner(activa('usuario'));
      final despues = c.read(gestorDeTiempoRealProvider);

      expect(despues, same(gestor));
      expect(fuente.abiertos, hasLength(3));
      expect(fuente.cierres, 0);
    });

    test(
      'un token con otro rol cierra y abre los canales del nuevo rol',
      () async {
        final c = crear(activa('usuario'));
        c.read(gestorDeTiempoRealProvider);

        sesion.poner(activa('analista'));
        c.read(gestorDeTiempoRealProvider);
        await Future<void>.delayed(Duration.zero);

        expect(fuente.cierres, 1);
        expect(fuente.abiertos, hasLength(3 + 4));
        expect(fuente.abiertos.last, 'supervision');
      },
    );

    test('cerrar la sesión cierra los canales', () async {
      final c = crear(activa('usuario'));
      c.read(gestorDeTiempoRealProvider);

      sesion.poner(null);

      expect(c.read(gestorDeTiempoRealProvider), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(fuente.cierres, 1);
    });
  });

  group('conexionProvider y decisionesHabilitadasProvider', () {
    test('sigue el estado del gestor', () async {
      final c = crear(activa('usuario'));
      c.listen(conexionProvider, (_, _) {});
      c.read(gestorDeTiempoRealProvider);
      expect(c.read(conexionProvider), EstadoConexion.conectado);
      expect(c.read(decisionesHabilitadasProvider), isTrue);

      fuente.suscribirTodos();
      fuente.senal(const SocketCerrado());
      await Future<void>.delayed(Duration.zero);
      expect(c.read(conexionProvider), EstadoConexion.reconectando);
      expect(c.read(decisionesHabilitadasProvider), isTrue);

      fuente.senal(const SocketFallo());
      await Future<void>.delayed(Duration.zero);
      expect(c.read(conexionProvider), EstadoConexion.sinConexion);
      expect(c.read(decisionesHabilitadasProvider), isFalse);

      fuente.senal(const SocketAbierto());
      fuente.suscribirTodos();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(conexionProvider), EstadoConexion.conectado);
      expect(c.read(decisionesHabilitadasProvider), isTrue);
    });
  });

  test('SuscripcionesDeRol se compara por valor', () {
    const a = SuscripcionesDeRol(idUsuario: 'u', rol: RolApp.usuario);
    const b = SuscripcionesDeRol(idUsuario: 'u', rol: RolApp.usuario);
    const c = SuscripcionesDeRol(idUsuario: 'u', rol: RolApp.analista);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}

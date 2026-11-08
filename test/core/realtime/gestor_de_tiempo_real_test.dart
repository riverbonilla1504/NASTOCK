
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/realtime/estado_conexion.dart';
import 'package:inversiones/core/realtime/gestor_de_tiempo_real.dart';

import 'falsos.dart';

void main() {
  late FuenteFalsa fuente;
  late GestorDeTiempoReal gestor;

  setUp(() {
    fuente = FuenteFalsa();
    gestor = GestorDeTiempoReal(fuente, ['mercado', 'fondo', 'usuario:u-1']);
  });

  tearDown(() => gestor.cerrar());

  test('CA-1: abre los canales que recibió, en orden', () {
    expect(fuente.abiertos, ['mercado', 'fondo', 'usuario:u-1']);
    expect(gestor.canales, ['mercado', 'fondo', 'usuario:u-1']);
  });

  test('reparte los eventos de todos los canales', () async {
    final llegados = <String>[];
    gestor.eventos.listen((e) => llegados.add('${e.canal}/${e.evento}'));

    fuente.evento('usuario:u-1', 'sugerencia', tabla: 'sugerencias', id: 's1');
    fuente.evento('mercado', 'estado_mercado', tabla: 'estado_mercado');
    await Future<void>.delayed(Duration.zero);

    expect(llegados, ['usuario:u-1/sugerencia', 'mercado/estado_mercado']);
  });

  group('CA-3 / CB-66: reconexión', () {
    test('la conexión inicial no pide fotos otra vez', () async {
      var avisos = 0;
      gestor.reconexiones.listen((_) => avisos++);

      fuente.suscribirTodos();
      await Future<void>.delayed(Duration.zero);

      expect(gestor.estado, EstadoConexion.conectado);
      expect(gestor.canalesSuscritos, {'mercado', 'fondo', 'usuario:u-1'});
      expect(avisos, 0);
    });

    test('al perder la conexión pasa a reconectando y al volver pide fotos', () async {
      final estados = <EstadoConexion>[];
      var avisos = 0;
      gestor.estados.listen(estados.add);
      gestor.reconexiones.listen((_) => avisos++);
      fuente.suscribirTodos();

      fuente.senal(const SocketCerrado());
      await Future<void>.delayed(Duration.zero);
      expect(gestor.estado, EstadoConexion.reconectando);
      expect(avisos, 0);

      fuente.senal(const SocketAbierto());
      fuente.suscribirTodos();
      await Future<void>.delayed(Duration.zero);

      expect(estados, [EstadoConexion.reconectando, EstadoConexion.conectado]);
      expect(avisos, 1);
    });

    test('un intento fallido pasa a sin conexión', () async {
      fuente.suscribirTodos();
      fuente.senal(const SocketCerrado());
      fuente.senal(const SocketFallo());
      await Future<void>.delayed(Duration.zero);
      expect(gestor.estado, EstadoConexion.sinConexion);
    });
  });

  test('al volver a primer plano pide las fotos otra vez', () async {
    var avisos = 0;
    gestor.reconexiones.listen((_) => avisos++);
    gestor.alVolverAPrimerPlano();
    await Future<void>.delayed(Duration.zero);
    expect(avisos, 1);
  });

  test('al cerrar, cierra los canales y deja de escuchar', () async {
    final llegados = <String>[];
    gestor.eventos.listen((e) => llegados.add(e.evento), onDone: () {});

    await gestor.cerrar();
    fuente.evento('mercado', 'estado_mercado', tabla: 'estado_mercado');
    await Future<void>.delayed(Duration.zero);

    expect(fuente.cierres, 1);
    expect(llegados, isEmpty);
    // Cerrar dos veces no vuelve a cerrar los canales.
    await gestor.cerrar();
    expect(fuente.cierres, 1);
  });
}
